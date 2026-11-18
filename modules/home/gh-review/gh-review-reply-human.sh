# Reply to any PR review thread, including one a person started, ending the
# reply with the agent trailer. Not allowed globally like gh-review-reply:
# the address-pr-review skill in llm-profile allows it for the turn it runs
# in, so other agents still ask before answering a person.

usage() {
  echo "usage: gh-review-reply-human OWNER/REPO PR COMMENT_ID [BODY]  (BODY from stdin if omitted)" >&2
  exit 2
}

[ $# -eq 3 ] || [ $# -eq 4 ] || usage
repo=$1 pr=$2 id=$3
[[ $repo =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ && $pr =~ ^[0-9]+$ && $id =~ ^[0-9]+$ ]] || usage
case "/$repo/" in */./* | */../*) usage ;; esac

if [ $# -eq 4 ]; then body=$4; else body=$(cat); fi
[ -n "${body//[[:space:]]/}" ] || {
  echo "gh-review-reply-human: empty reply" >&2
  exit 2
}
trailer='🤖 Agent comment'
[[ $body == *"$trailer" ]] || body+=$'\n\n'"$trailer"

gh api --method POST "repos/$repo/pulls/$pr/comments/$id/replies" -f body="$body" --jq .html_url
