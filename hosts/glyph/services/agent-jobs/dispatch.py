"""Dispatcher for unattended agent jobs on glyph (../agent-jobs.nix).

`poll <job>` runs a job's trigger and queues events it hasn't seen.
`work` runs queued events one at a time: builds the prompt, starts the
tier's template unit (agent-job-<tier>@<run>.service, which the polkit rule
lets this user start), validates the agent's JSON result and posts it
through the job's sinks. Agents never post anything themselves.
`forget <job> <key>` drops a dedup key, so the event can run again.
"""

import argparse
import datetime
import fcntl
import json
import os
import re
import secrets
import shutil
import subprocess
import sys
import time
import urllib.request
from pathlib import Path

import jsonschema

HOME = Path(os.environ.get("AGENT_DISPATCH_HOME", "/var/lib/agent-dispatch"))
QUEUE = HOME / "queue"
INCOMING = HOME / "incoming"
RUNS = HOME / "runs"
STATE = HOME / "state.json"
LOCK = HOME / "lock"
NTFY_URL = os.environ.get("NTFY_URL", "http://127.0.0.1:2586")
NTFY_TOPIC = os.environ.get("NTFY_TOPIC", "agents")
# The tier units' runner ends their output with this line
EXIT_MARKER = "__AGENT_JOB_EXIT__"
RUN_RETENTION_DAYS = 14
STATE_RETENTION_DAYS = 90
# Loop guard: never run on events from the agents' own branches
AGENT_BRANCH_FIELDS = ("headBranch", "branch", "headRefName")
AGENT_BRANCH_PREFIX = "agents/"
CONTROL_CHARS = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]")


def now():
    return datetime.datetime.now(datetime.timezone.utc)


def stamp(t=None):
    return (t or now()).strftime("%Y-%m-%dT%H:%M:%SZ")


def log(**fields):
    """One JSON line per event, for Loki ({unit=~"agent-dispatch.*"})."""
    print(json.dumps({"ts": stamp(), **fields}), flush=True)


def load_jobs():
    return json.loads(Path(os.environ["AGENT_JOBS"]).read_text())


def jq(expr, value):
    out = subprocess.run(
        ["jq", "-c", expr],
        input=json.dumps(value),
        capture_output=True,
        text=True,
        check=True,
    ).stdout
    return [json.loads(line) for line in out.splitlines() if line.strip()]


def jq_one(expr, value):
    results = jq(expr, value)
    if len(results) != 1:
        raise ValueError(f"jq {expr!r} gave {len(results)} results, expected 1")
    return results[0]


class State:
    """state.json under an exclusive lock: {job: {key: {status, at, run}}}."""

    def __enter__(self):
        self.lock = open(LOCK, "w")
        fcntl.flock(self.lock, fcntl.LOCK_EX)
        self.data = json.loads(STATE.read_text()) if STATE.exists() else {}
        return self.data

    def __exit__(self, *exc):
        cutoff = stamp(now() - datetime.timedelta(days=STATE_RETENTION_DAYS))
        for keys in self.data.values():
            for key in [k for k, v in keys.items() if v.get("at", "") < cutoff]:
                del keys[key]
        tmp = STATE.with_suffix(".tmp")
        tmp.write_text(json.dumps(self.data, indent=1, sort_keys=True))
        os.replace(tmp, STATE)
        fcntl.flock(self.lock, fcntl.LOCK_UN)
        self.lock.close()


def record(job, key, **fields):
    with State() as state:
        state.setdefault(job, {})[key] = {"at": stamp(), **fields}


def from_agent_branch(event):
    return any(
        isinstance(event.get(f), str) and event[f].startswith(AGENT_BRANCH_PREFIX)
        for f in AGENT_BRANCH_FIELDS
    )


def poll(name):
    job = load_jobs()[name]
    if job["poll"]:
        out = subprocess.run([job["poll"]], capture_output=True, text=True, check=True).stdout
        events = [json.loads(line) for line in out.splitlines() if line.strip()]
    else:
        events = [{"time": stamp()}]
    queued = 0
    for event in events:
        if not isinstance(event, dict):
            log(job=name, action="poll", error="event is not an object", event=event)
            continue
        if from_agent_branch(event):
            log(job=name, action="poll", skipped="agent branch", event=event)
            continue
        key = str(jq_one(job["dedupKey"], event))
        with State() as state:
            seen = state.setdefault(name, {})
            if key in seen:
                continue
            seen[key] = {"status": "queued", "at": stamp()}
            # Written outside the queue, then moved in, so the path unit
            # never starts the worker on a half-written file
            entry = f"{time.time_ns()}-{name}-{secrets.token_hex(3)}.json"
            (INCOMING / entry).write_text(json.dumps({"job": name, "key": key, "event": event}))
            os.replace(INCOMING / entry, QUEUE / entry)
        queued += 1
        log(job=name, action="queued", key=key)
    log(job=name, action="poll", events=len(events), queued=queued)


def clean(text):
    return CONTROL_CHARS.sub("", text)


def run_context(command, event, max_bytes):
    """A context command's output, the tail if it's long."""
    proc = subprocess.run(
        [command],
        env={**os.environ, "EVENT": json.dumps(event)},
        capture_output=True,
        check=False,
    )
    data = proc.stdout
    if proc.returncode != 0:
        data += f"\n[command exited {proc.returncode}: {clean(proc.stderr.decode(errors='replace'))[-500:]}]".encode()
    truncated = len(data) > max_bytes
    text = clean(data[-max_bytes:].decode(errors="replace"))
    return ("[earlier output truncated]\n" if truncated else "") + text


def render(template, values):
    def substitute(match):
        name = match.group(1)
        if name not in values:
            raise KeyError(f"prompt template names unknown value {{{{{name}}}}}")
        return values[name]

    return re.sub(r"\{\{\s*([A-Za-z0-9_.-]+)\s*\}\}", substitute, template)


def extract_result(output):
    """The last ```json block in the agent's reply, else its last JSON line."""
    blocks = re.findall(r"```json\s*\n(.*?)\n\s*```", output, re.S)
    candidates = blocks[::-1] or [
        line for line in reversed(output.splitlines()) if line.strip().startswith("{")
    ]
    for candidate in candidates:
        try:
            # Not strict: models put raw newlines in strings, and
            # sanitize() strips control characters before anything posts
            return json.loads(candidate, strict=False)
        except json.JSONDecodeError:
            continue
    return None


def sanitize(value):
    """Agent text that sinks post: no control characters, no @-mentions
    (a GitHub mention notifies whoever it names), and no ~~~~ fences, which
    the sinks' own formatting uses."""
    if isinstance(value, str):
        value = clean(value).replace("~~~~", "~ ~ ~ ~")
        return re.sub(r"@(?=[A-Za-z0-9_-])", "@​", value)
    if isinstance(value, list):
        return [sanitize(v) for v in value]
    if isinstance(value, dict):
        return {k: sanitize(v) for k, v in value.items()}
    return value


def ntfy(message):
    body = json.dumps({"topic": NTFY_TOPIC, **message}).encode()
    request = urllib.request.Request(NTFY_URL, data=body, method="POST")
    with urllib.request.urlopen(request, timeout=30) as response:
        response.read()


def post(sink, payload):
    if sink["type"] == "ntfy":
        ntfy(jq_one(sink["publish"], payload))
    elif sink["type"] == "pr-comment":
        number = str(jq_one(sink["pr"], payload))
        body = jq_one(sink["body"], payload)
        subprocess.run(
            ["gh", "pr", "comment", number, "--repo", sink["repo"], "--body-file", "-"],
            input=body,
            text=True,
            capture_output=True,
            check=True,
        )
    else:
        raise ValueError(f"unknown sink type {sink['type']!r}")


def run(item, jobs):
    name, key, event = item["job"], item["key"], item["event"]
    job = jobs.get(name)
    if job is None:
        log(job=name, key=key, outcome="skipped", reason="job no longer defined")
        return "skipped", None
    run_id = f"{name}-{now().strftime('%Y%m%dT%H%M%S')}-{secrets.token_hex(3)}"
    rundir = RUNS / run_id
    rundir.mkdir(mode=0o700)

    values = {
        "job": name,
        "run": run_id,
        "event": json.dumps(event, indent=2),
        "schema": json.dumps(job["schema"], indent=2),
    }
    for cname, ctx in job["context"].items():
        text = run_context(ctx["command"], event, ctx["maxBytes"])
        # Delimited, so the prompt can tell the agent that what's inside is
        # data, never instructions (#741)
        values[f"context.{cname}"] = f'<untrusted-data name="{cname}">\n{text}\n</untrusted-data>'
    (rundir / "prompt").write_text(render(Path(job["prompt"]).read_text(), values))
    (rundir / "timeout").write_text(str(job["timeout"]))

    unit = f"agent-job-{job['tier']}@{run_id}.service"
    started = time.monotonic()
    proc = subprocess.run(["systemctl", "start", unit], capture_output=True, text=True, check=False)
    duration = round(time.monotonic() - started)
    output_file = rundir / "output"
    output = output_file.read_text(errors="replace") if output_file.exists() else ""
    marker = re.findall(rf"^{EXIT_MARKER} (\d+)$", output, re.M)
    output = output.split(f"\n{EXIT_MARKER}")[0]

    detail = None
    result = None
    if not marker:
        outcome, detail = "error", clean(proc.stderr.strip())[-500:] or "the unit ended without a result"
    elif marker[-1] == "124":
        outcome = "timeout"
    elif marker[-1] != "0":
        outcome, detail = "error", f"the agent exited {marker[-1]}"
    else:
        result = extract_result(output)
        try:
            if result is None:
                raise jsonschema.ValidationError("no JSON result in the agent's reply")
            jsonschema.validate(result, job["schema"])
            outcome = "gave_up" if result.get("status") == "gave_up" else "finding"
        except jsonschema.ValidationError as e:
            outcome, detail, result = "invalid_output", e.message[:500], None

    if result is not None:
        payload = {"job": name, "run": run_id, "event": event, "outcome": outcome, "result": sanitize(result)}
        for sink in job["sinks"]:
            try:
                post(sink, payload)
            except Exception as e:  # noqa: BLE001 - one sink failing mustn't stop the others
                log(job=name, run=run_id, sink=sink["type"], error=clean(str(e))[:500])
                outcome = "sink_error"
    else:
        # Trusted text only: never the agent's own output
        try:
            ntfy({
                "title": f"Agent job {name}: {outcome}",
                "message": f"Run {run_id} posted nothing. Its output is in /var/lib/agent-dispatch/runs/{run_id} on glyph.",
            })
        except Exception as e:  # noqa: BLE001
            log(job=name, run=run_id, sink="ntfy", error=clean(str(e))[:500])

    log(job=name, key=key, run=run_id, unit=unit, outcome=outcome, duration=duration, detail=detail)
    return outcome, run_id


def prune_runs():
    cutoff = time.time() - RUN_RETENTION_DAYS * 86400
    for rundir in RUNS.iterdir():
        if rundir.is_dir() and rundir.stat().st_mtime < cutoff:
            shutil.rmtree(rundir, ignore_errors=True)


def work():
    prune_runs()
    jobs = load_jobs()
    while True:
        entries = sorted(QUEUE.glob("*.json"))
        if not entries:
            return
        entry = entries[0]
        item = json.loads(entry.read_text())
        try:
            outcome, run_id = run(item, jobs)
        except Exception as e:  # noqa: BLE001 - keep working through the queue
            outcome, run_id = "error", None
            log(job=item.get("job"), key=item.get("key"), outcome="error", detail=clean(str(e))[:500])
        record(item["job"], item["key"], status=outcome, run=run_id)
        entry.unlink()


def forget(name, key):
    with State() as state:
        removed = state.get(name, {}).pop(key, None)
    print("forgot" if removed else "not found", name, key)


def main():
    parser = argparse.ArgumentParser(prog="agent-dispatch")
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("poll").add_argument("job")
    sub.add_parser("work")
    forget_parser = sub.add_parser("forget")
    forget_parser.add_argument("job")
    forget_parser.add_argument("key")
    args = parser.parse_args()
    for d in (QUEUE, INCOMING, RUNS):
        d.mkdir(mode=0o700, parents=True, exist_ok=True)
    if args.command == "poll":
        poll(args.job)
    elif args.command == "work":
        work()
    else:
        forget(args.job, args.key)


if __name__ == "__main__":
    sys.exit(main())
