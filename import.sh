#!/usr/bin/env bash
set -euo pipefail

PROJECT_ID="PVT_kwHOATf09s4BoZjw"
INPUT="${1:-tasks.txt}"

while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "${line//[[:space:]]/}" ]] && continue

  if [[ "$line" =~ ^\[([^]]+)\][[:space:]]*(.*)$ ]]; then
    category="${BASH_REMATCH[1]}"
    title="${BASH_REMATCH[2]}"
  else
    category="À Trier"
    title="$line"
  fi

  body="Catégorie initiale : ${category}"

  gh api graphql -f query='
    mutation($projectId: ID!, $title: String!, $body: String!) {
      addProjectV2DraftIssue(input: {
        projectId: $projectId,
        title: $title,
        body: $body
      }) {
        projectItem {
          id
        }
      }
    }
  ' -f projectId="$PROJECT_ID" \
    -f title="$title" \
    -f body="$body" >/dev/null

  printf 'Added: [%s] %s\n' "$category" "$title"
done <"$INPUT"

echo "Import complete."
