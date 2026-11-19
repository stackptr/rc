# List a PR's unresolved review threads as JSON, ordered by file and line
# like the Files changed tab. Read-only, so Claude Code runs it without
# asking (development.nix), where `gh api graphql` asks because it can run
# any mutation.

usage() {
  echo "usage: gh-review-threads OWNER/REPO PR" >&2
  exit 2
}

[ $# -eq 2 ] || usage
repo=$1 pr=$2
[[ $repo =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ && $pr =~ ^[0-9]+$ ]] || usage

# shellcheck disable=SC2016 # GraphQL variables, not shell ones
query='query($owner: String!, $name: String!, $number: Int!, $endCursor: String) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      reviewThreads(first: 100, after: $endCursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          isResolved
          isOutdated
          path
          line
          originalLine
          comments(first: 100) {
            nodes { databaseId url body author { __typename login } }
          }
        }
      }
    }
  }
}'
gh api graphql --paginate -f query="$query" -f owner="${repo%%/*}" -f name="${repo#*/}" -F number="$pr" \
  --jq '.data.repository.pullRequest.reviewThreads.nodes[]
    | select(.isResolved | not)
    | {
        comment_id: .comments.nodes[0].databaseId,
        url: .comments.nodes[0].url,
        path, line: (.line // .originalLine), outdated: .isOutdated,
        started_by: {login: .comments.nodes[0].author.login, bot: (.comments.nodes[0].author.__typename == "Bot")},
        comments: [.comments.nodes[] | {id: .databaseId, author: .author.login, bot: (.author.__typename == "Bot"), body}]
      }' |
  jq --slurp 'sort_by(.path, .line)'
