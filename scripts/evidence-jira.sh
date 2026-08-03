#!/usr/bin/env bash
# Jira resolved-by-me in range. Config via env:
#   JIRA_BASE (e.g. https://acme.atlassian.net), JIRA_EMAIL, JIRA_TOKEN
set -euo pipefail
since="${1:?since}"; until="${2:?until}"
if [ -z "${JIRA_BASE:-}" ] || [ -z "${JIRA_EMAIL:-}" ] || [ -z "${JIRA_TOKEN:-}" ]; then
  echo "(Jira not configured — set JIRA_BASE/JIRA_EMAIL/JIRA_TOKEN, or paste tickets at check-in)" >&2
  exit 0
fi
jql="assignee = currentUser() AND resolutiondate >= \"$since\" AND resolutiondate <= \"$until\" ORDER BY resolutiondate"
curl -s -u "$JIRA_EMAIL:$JIRA_TOKEN" -G "$JIRA_BASE/rest/api/3/search" \
  --data-urlencode "jql=$jql" --data-urlencode "fields=key,summary" \
  | jq -r '.issues[]? | "\(.key) \(.fields.summary)"' 2>/dev/null || echo "(Jira query failed)"
