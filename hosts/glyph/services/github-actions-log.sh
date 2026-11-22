# Logs the GitHub Actions runs that completed since the last poll, in every
# repo the app is installed on, as JSON lines on stdout, which journald hands
# to Loki: one per job ("kind":"job"), one per run ("kind":"run"), and the
# tail of each failed job's log ("kind":"log"). Run hourly by
# github-actions-log.service (./github-actions-log.nix), which sets
# APP_CLIENT_ID, APP_OWNER and APP_KEY.

b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }

# Every job line's fields; the run and log lines repeat the ones they share
# so each line stands alone in a query. `workflow` is the file, since a
# workflow's run-name replaces its name in the API. A job that got a runner
# started when it was picked up; one that didn't "started" when it was
# created, so it queued until it was cancelled and never ran.
job_line='
  def secs(from; to): if from and to then (to | fromdate) - (from | fromdate) else null end;
  {
    kind: "job", repo: $repo, workflow: ($run.path | split("/") | last), title: $run.display_title,
    run: $run.id, attempt: $run.run_attempt, event: $run.event, branch: $run.head_branch, sha: $run.head_sha,
    job: .name, job_id: .id, conclusion, labels, runner: (.runner_name // ""),
    created_at, started_at, completed_at,
    queue_seconds: (if $unacquired then secs(.created_at; .completed_at) else secs(.created_at; .started_at) end),
    run_seconds: (if $unacquired then null else secs(.started_at; .completed_at) end),
    unacquired: $unacquired, annotations: $annotations, url: .html_url
  }'

auth=
api() {
  curl -sSfL -H "Authorization: Bearer $auth" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" "https://api.github.com/$1" "${@:2}"
}

# An installation token, as agents-github-token mints teleomycete's
# (./agents.nix): a JWT for the app, valid for 9 minutes, iat backdated for
# clock skew. The token lasts an hour, longer than a poll.
now=$(date +%s)
header=$(printf '{"alg":"RS256","typ":"JWT"}' | b64url)
payload=$(jq -nc --argjson now "$now" --arg iss "$APP_CLIENT_ID" \
  '{iat: ($now - 60), exp: ($now + 540), iss: $iss}' | b64url)
signature=$(printf '%s.%s' "$header" "$payload" | openssl dgst -sha256 -sign "$APP_KEY" | b64url)
auth="$header.$payload.$signature"
installation=$(api "users/$APP_OWNER/installation" | jq -er .id)
auth=$(api "app/installations/$installation/access_tokens" -X POST | jq -er .token)

# Runs that finished in the last couple of minutes may not be listed yet
until=$(date -u -d '-2 min' +%FT%TZ)
repos=$(api "installation/repositories?per_page=100" | jq -r '.repositories[].full_name')

for repo in $repos; do
  # Each repo keeps its own watermark, and its lines are printed only once
  # all of them are fetched, so a failure part way repeats nothing on the
  # next poll. A repo seen for the first time starts an hour back.
  state="$STATE_DIRECTORY/${repo//\//_}"
  since=$(cat "$state" 2>/dev/null || date -u -d '-1 hour' +%FT%TZ)
  # Listed by creation, but logged once completed or re-run (updated_at):
  # a week back covers queueing, approvals and the 6-hour job limit
  created=$(date -u -d "$since 7 days ago" +%FT%TZ)
  out=$(mktemp)

  runs=$(mktemp)
  page=1
  while :; do
    list=$(api "repos/$repo/actions/runs?status=completed&per_page=100&page=$page&created=%3E%3D$created")
    jq -c --arg since "$since" --arg until "$until" \
      '.workflow_runs[] | select(.updated_at > $since and .updated_at <= $until)' <<<"$list" >>"$runs"
    [ "$(jq '.workflow_runs | length' <<<"$list")" -eq 100 ] || break
    page=$((page + 1))
  done

  while read -r run; do
    id=$(jq -r .id <<<"$run")
    attempt=$(jq -r .run_attempt <<<"$run")
    unacquired_jobs=0
    while read -r job; do
      job_id=$(jq -r .id <<<"$job")
      conclusion=$(jq -r .conclusion <<<"$job")
      annotations='[]'
      unacquired=false
      case $conclusion in
        failure | cancelled | timed_out)
          annotations=$(api "repos/$repo/check-runs/$job_id/annotations" |
            jq -c '[limit(20; .[]) | {level: .annotation_level, message: .message[:1000]}]')
          # Cancelled before any runner took it, and not by concurrency:
          # GitHub gave up finding a hosted runner (macOS arm64, mostly)
          if [ "$conclusion" = cancelled ] &&
            jq -e '(.runner_name // "") == ""' <<<"$job" >/dev/null &&
            jq -e 'any(.[]; .message | test("not acquired by Runner"))' <<<"$annotations" >/dev/null; then
            unacquired=true
            unacquired_jobs=$((unacquired_jobs + 1))
          fi
          ;;
      esac
      jq -c --arg repo "$repo" --argjson run "$run" --argjson annotations "$annotations" \
        --argjson unacquired "$unacquired" "$job_line" <<<"$job" >>"$out"

      # A failed job's log up to its last error, where the failure is, rather
      # than the cleanup steps after it; without each line's timestamp or
      # colors. Logs expire, so they're best effort.
      if [ "$conclusion" = failure ] || [ "$conclusion" = timed_out ]; then
        if log=$(api "repos/$repo/actions/jobs/$job_id/logs"); then
          last_error=$(grep -n '##\[error\]' <<<"$log" | tail -n 1 | cut -d: -f1 || true)
          head -n "${last_error:-$(wc -l <<<"$log")}" <<<"$log" | tail -n 200 | sed -E 's/^[0-9T:.-]+Z //; s/\x1b\[[0-9;]*m//g' |
            jq -Rc --arg repo "$repo" --argjson run "$id" --argjson attempt "$attempt" \
              --arg job "$(jq -r .name <<<"$job")" --argjson job_id "$job_id" \
              '{kind: "log", repo: $repo, run: $run, attempt: $attempt, job: $job, job_id: $job_id, line: .[:2000]}' >>"$out"
        fi
      fi
    done < <(api "repos/$repo/actions/runs/$id/attempts/$attempt/jobs?per_page=100" | jq -c '.jobs[]')

    jq -c --arg repo "$repo" --argjson unacquired_jobs "$unacquired_jobs" '
      {
        kind: "run", repo: $repo, workflow: (.path | split("/") | last), title: .display_title, run: .id, attempt: .run_attempt,
        event, branch: .head_branch, sha: .head_sha, actor: .actor.login, conclusion,
        created_at, run_started_at, updated_at,
        run_seconds: ((.updated_at | fromdate) - (.run_started_at | fromdate)),
        unacquired_jobs: $unacquired_jobs, url: .html_url
      }' <<<"$run" >>"$out"
  # Oldest first, so the latest run of a job is also its latest line, which
  # last_over_time in the Builds dashboard relies on. The API lists newest first.
  done < <(jq -sc 'sort_by(.updated_at)[]' "$runs")

  cat "$out"
  printf '%s\n' "$until" >"$state"
  rm -f "$out" "$runs"
done
