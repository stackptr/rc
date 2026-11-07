# First agent job: diagnose a flake update whose CI failed. update.yml opens
# the PR from gh/update-flake (or gh/update-flake-<run id> for a partial
# update) and merges it once the required checks pass, so a failed build
# leaves the PR open. The dispatcher fetches the failed logs, the lock diff
# and the PR's description; a review-tier agent reads them with rc-source
# and returns a diagnosis, which the dispatcher posts on the PR and to
# #agents. The agent pushes nothing, and can't evaluate Nix (the daemon's
# socket is hidden from the tiers).
{pkgs, ...}: let
  repo = "stackptr/rc";
  # Set to a test branch's prefix to try the job on a deliberately failing PR
  branchPrefix = "gh/update-flake";
  script = name: text:
    pkgs.writeShellApplication {
      inherit name text;
      runtimeInputs = with pkgs; [coreutils jq];
    };

  # Failed CI runs from the last day on an update branch, for the PR's
  # current head only, so old runs and closed PRs never start a job
  poll = script "flake-update-poll" ''
    since=$(date -u -d '-1 day' +%Y-%m-%dT%H:%M:%SZ)
    gh run list --repo ${repo} --workflow ci.yml --status failure --limit 50 \
      --json databaseId,headBranch,headSha,url,createdAt |
      jq -c --arg prefix ${branchPrefix} --arg since "$since" \
        '.[] | select((.headBranch | startswith($prefix)) and .createdAt >= $since)' |
      while IFS= read -r run; do
        branch=$(jq -r .headBranch <<<"$run")
        pr=$(gh pr list --repo ${repo} --head "$branch" --state open \
          --json number,url,headRefOid --jq '.[0] // empty')
        [ -n "$pr" ] || continue
        jq -c --argjson pr "$pr" \
          'select(.headSha == $pr.headRefOid) | . + {pr: $pr.number, prUrl: $pr.url}' <<<"$run"
      done
  '';
in {
  rc.agents.jobs.flake-update = {
    tier = "review";
    trigger = {
      onCalendar = "*:0/15";
      poll = "${poll}/bin/flake-update-poll";
    };
    dedupKey = ".databaseId";
    prompt = ./flake-update.md;
    context = {
      logs = {
        command = "${script "flake-update-logs" ''
          gh run view "$(jq -r .databaseId <<<"$EVENT")" --repo ${repo} --log-failed
        ''}/bin/flake-update-logs";
        maxBytes = 60000;
      };
      lock = {
        command = "${script "flake-update-lock" ''
          gh api "repos/${repo}/pulls/$(jq -r .pr <<<"$EVENT")/files" --paginate \
            --jq '.[] | select(.filename == "flake.lock") | .patch'
        ''}/bin/flake-update-lock";
        maxBytes = 30000;
      };
      pr = {
        command = "${script "flake-update-pr" ''
          gh pr view "$(jq -r .pr <<<"$EVENT")" --repo ${repo} --json title,body \
            --jq '"\(.title)\n\n\(.body)"'
        ''}/bin/flake-update-pr";
        maxBytes = 10000;
      };
    };
    schema = {
      type = "object";
      additionalProperties = false;
      required = ["status" "summary" "confidence"];
      properties = {
        status.enum = ["diagnosed" "gave_up"];
        summary = {
          type = "string";
          maxLength = 300;
        };
        root_cause = {
          type = "string";
          maxLength = 4000;
        };
        evidence = {
          type = "array";
          maxItems = 10;
          items = {
            type = "string";
            maxLength = 500;
          };
        };
        proposed_patch = {
          type = "string";
          maxLength = 8000;
        };
        confidence.enum = ["low" "medium" "high"];
      };
    };
    sinks = [
      {
        type = "pr-comment";
        inherit repo;
        pr = ".event.pr";
        body = ''
          "### Why this update's CI failed\n\n"
          + (if .result.status == "gave_up" then "The agent couldn't find the cause. " else "" end)
          + "**\(.result.summary)** (confidence: \(.result.confidence))\n\n"
          + (if .result.root_cause then .result.root_cause + "\n\n" else "" end)
          + (if ((.result.evidence // []) | length) > 0
             then "**Evidence**\n\n" + (.result.evidence | map("- " + .) | join("\n")) + "\n\n"
             else "" end)
          + (if .result.proposed_patch
             then "**Proposed patch** (not applied)\n\n~~~~diff\n" + .result.proposed_patch + "\n~~~~\n\n"
             else "" end)
          + "---\n_Diagnosed by an unattended agent on glyph (local model) from [the failed CI run](\(.event.url)), run `\(.run)`. It pushed nothing; check its reasoning before acting on it._"
        '';
      }
      {
        type = "ntfy";
        publish = ''
          {
            title: ("Flake update: " + (.result.summary | .[0:150])),
            message: "\(if .result.status == "gave_up" then "Gave up" else "Diagnosed" end), confidence \(.result.confidence). Details on the PR.",
            click: .event.prUrl
          }
        '';
      }
    ];
  };
}
