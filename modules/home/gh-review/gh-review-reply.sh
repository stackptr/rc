# Reply to a bot's PR review thread, ending the reply with the agent trailer.
# Claude Code runs it without asking (development.nix); every other `gh api`
# write asks. It refuses threads a person started: those are mine to answer.

usage() {
  echo "usage: gh-review-reply OWNER/REPO PR COMMENT_ID [BODY]  (BODY from stdin if omitted)" >&2
  exit 2
}

[ $# -eq 3 ] || [ $# -eq 4 ] || usage
repo=$1 pr=$2 id=$3
[[ $repo =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ && $pr =~ ^[0-9]+$ && $id =~ ^[0-9]+$ ]] || usage
case "/$repo/" in */./* | */../*) usage ;; esac

if [ $# -eq 4 ]; then body=$4; else body=$(cat); fi
[ -n "${body//[[:space:]]/}" ] || {
  echo "gh-review-reply: empty reply" >&2
  exit 2
}
trailer='🤖 Agent comment'
[[ $body == *"$trailer" ]] || body+=$'\n\n'"$trailer"

# The thread's first comment says who started it
root=$(gh api "repos/$repo/pulls/comments/$id" --jq '.in_reply_to_id // .id')
starter=$(gh api "repos/$repo/pulls/comments/$root" --jq '[.user.type, .user.login] | @tsv')
read -r type login <<<"$starter"
if [ "$type" != Bot ]; then
  echo "gh-review-reply: $login started this thread, not a bot; leave it to the user" >&2
  exit 1
fi

gh api --method POST "repos/$repo/pulls/$pr/comments/$id/replies" -f body="$body" --jq .html_url
