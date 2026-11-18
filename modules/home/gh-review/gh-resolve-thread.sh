# Resolve a bot's PR review thread, named by any comment in it. Claude Code
# runs it without asking (development.nix), where `gh api graphql` asks
# because it can run any mutation. It refuses threads a person started.

usage() {
  echo "usage: gh-resolve-thread OWNER/REPO PR COMMENT_ID" >&2
  exit 2
}

[ $# -eq 3 ] || usage
repo=$1 pr=$2 id=$3
[[ $repo =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ && $pr =~ ^[0-9]+$ && $id =~ ^[0-9]+$ ]] || usage

# shellcheck disable=SC2016 # GraphQL variables, not shell ones
query='query($owner: String!, $name: String!, $number: Int!) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          comments(first: 100) { nodes { databaseId author { __typename login } } }
        }
      }
    }
  }
}'
thread=$(gh api graphql -f query="$query" -f owner="${repo%%/*}" -f name="${repo#*/}" -F number="$pr" \
  --jq ".data.repository.pullRequest.reviewThreads.nodes[]
    | select(any(.comments.nodes[]; .databaseId == $id))
    | [.id, .isResolved, .comments.nodes[0].author.__typename, .comments.nodes[0].author.login] | @tsv")
if [ -z "$thread" ]; then
  echo "gh-resolve-thread: no thread on $repo#$pr contains comment $id" >&2
  exit 1
fi
read -r thread_id resolved type login <<<"$thread"
if [ "$type" != Bot ]; then
  echo "gh-resolve-thread: $login started this thread, not a bot; leave it to the user" >&2
  exit 1
fi
if [ "$resolved" = true ]; then
  echo "already resolved"
  exit 0
fi

# shellcheck disable=SC2016
gh api graphql -f query='mutation($id: ID!) { resolveReviewThread(input: {threadId: $id}) { thread { isResolved } } }' \
  -f id="$thread_id" --jq '.data.resolveReviewThread.thread.isResolved'
