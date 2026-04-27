# Shared parser helpers for renderers. Sourced, not executed.
#
# metadata.yaml has a known shape:
#   name: <slug>
#   description: "<quoted single-line text>"
#   tools: [A, B, C]
#   model: <scalar>
#   extras:
#     opencode:
#       mode: subagent
#     kilo:
#       mode: subagent
#     codex:
#       sandbox_mode: read-only
#
# These helpers intentionally do not pull pyyaml/yq so the install path has
# zero runtime deps beyond coreutils + awk.

# meta_top <file> <key>
# Prints the raw value after "<key>: " from a top-level YAML scalar line.
# Leaves quoting/brackets intact so callers can re-emit verbatim.
meta_top() {
    local f="$1" k="$2"
    awk -v k="$k" '
        $0 ~ "^"k":" {
            sub("^"k":[[:space:]]*", "")
            sub("[[:space:]]+$", "")
            print
            exit
        }
    ' "$f"
}

# meta_top_unquoted <file> <key>
# Like meta_top but strips surrounding double quotes.
meta_top_unquoted() {
    local raw
    raw=$(meta_top "$1" "$2")
    raw="${raw#\"}"
    raw="${raw%\"}"
    printf '%s' "$raw"
}

# meta_extras <file> <cli> <key>
# Returns the value of extras.<cli>.<key>, or empty if absent.
meta_extras() {
    local f="$1" cli="$2" k="$3"
    awk -v cli="$cli" -v k="$k" '
        /^extras:/ { in_extras=1; next }
        /^[^[:space:]]/ && in_extras { in_extras=0 }
        in_extras && $0 ~ "^  "cli":" { in_cli=1; next }
        in_extras && in_cli && $0 ~ "^  [^ ]" && $0 !~ "^  "cli":" { in_cli=0 }
        in_extras && in_cli && $0 ~ "^    "k":" {
            sub("^    "k":[[:space:]]*", "")
            sub("[[:space:]]+$", "")
            gsub(/^"|"$/, "")
            print
            exit
        }
    ' "$f"
}

# toml_escape_triple <string>
# Checks that body does not contain """; prints to stderr and exits if it does.
# The body must be printed inside a TOML triple-quoted string without escape.
toml_guard_body() {
    local body_file="$1"
    if grep -qF '"""' "$body_file"; then
        echo "toml_guard_body: '$body_file' contains triple-quote, which TOML triple-string cannot hold safely" >&2
        return 1
    fi
}

# tools_as_record <tools-array-string> [indent]
# Converts a YAML inline list like `[Bash, Read, Write]` into a YAML record
# (map) with lowercase keys and `true` values. Optional indent arg (default 2
# spaces) controls the leading whitespace on each emitted line.
#
# OpenCode and Kilo Code reject `tools:` as a list; they expect:
#     tools:
#       bash: true
#       read: true
#
# Claude/Agent-only names that don't exist in OpenCode's tool set are mapped
# to the closest match (Agent → task) or skipped entirely (Skill — no equiv).
tools_as_record() {
    local raw="$1"
    local indent="${2:-  }"

    # Strip brackets and split on commas.
    raw="${raw#\[}"
    raw="${raw%\]}"

    local IFS=,
    for t in $raw; do
        # trim whitespace
        t=$(printf '%s' "$t" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        [ -z "$t" ] && continue
        local lower
        lower=$(printf '%s' "$t" | tr '[:upper:]' '[:lower:]')
        case "$lower" in
            bash|read|write|edit|grep|glob|list|patch|task|todowrite|webfetch)
                printf '%s%s: true\n' "$indent" "$lower"
                ;;
            agent)
                printf '%s%s: true\n' "$indent" "task"
                ;;
            skill)
                # No OpenCode/Kilo equivalent — skip without warning.
                ;;
            *)
                # Unknown tool: emit lowercased and let the CLI complain if it
                # doesn't recognize it. Better than silently dropping.
                printf '%s%s: true\n' "$indent" "$lower"
                ;;
        esac
    done
}
