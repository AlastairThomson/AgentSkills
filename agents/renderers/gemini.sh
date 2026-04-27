#!/usr/bin/env bash
# Render an agent for Gemini CLI.
#   Usage: gemini.sh <agent-base-dir>
#   Emits the final <name>.md file to stdout.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=./_lib.sh
. "$here/_lib.sh"

base="${1:?usage: gemini.sh <agent-base-dir>}"
meta="$base/metadata.yaml"
body="$base/agent.md"

[ -f "$meta" ] || { echo "gemini.sh: no metadata.yaml in $base" >&2; exit 1; }
[ -f "$body" ] || { echo "gemini.sh: no agent.md in $base" >&2; exit 1; }

name=$(meta_top_unquoted "$meta" name)
description=$(meta_top "$meta" description)
tools=$(meta_top "$meta" tools)
model=$(meta_top_unquoted "$meta" model)

cat <<EOF
---
name: $name
description: $description
model: $model
tools: $tools
---

EOF
cat "$body"
