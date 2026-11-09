#!/bin/bash
# Tracks file read times and injects diffs when files change between read and edit.
# Used as a Claude Code hook for PreToolUse (Edit) and PostToolUse (Read).

TRACKING_DIR="$HOME/.claude/cache/file-read-times"
mkdir -p "$TRACKING_DIR"

INPUT=$(cat)
EVENT="${HOOK_EVENT_NAME:-}"
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // empty')

tracking_key() {
    echo "$1" | md5 | tr -d '\n'
}

if [ "$EVENT" = "PostToolUse" ] && [ "$TOOL_NAME" = "Read" ]; then
    FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty')
    if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
        KEY=$(tracking_key "$FILE_PATH")
        # Store a snapshot of the file at read time
        cp "$FILE_PATH" "$TRACKING_DIR/$KEY.snapshot"
        echo "$FILE_PATH" > "$TRACKING_DIR/$KEY.path"
    fi

elif [ "$EVENT" = "PreToolUse" ] && [ "$TOOL_NAME" = "Edit" ]; then
    FILE_PATH=$(echo "$TOOL_INPUT" | jq -r '.file_path // empty')
    if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
        KEY=$(tracking_key "$FILE_PATH")
        SNAPSHOT="$TRACKING_DIR/$KEY.snapshot"

        if [ -f "$SNAPSHOT" ]; then
            # Compare snapshot (what Claude last read) to current file
            DIFF=$(diff -u "$SNAPSHOT" "$FILE_PATH" 2>/dev/null)

            if [ -n "$DIFF" ]; then
                # File changed — inject the unified diff
                DIFF_ESCAPED=$(echo "$DIFF" | jq -Rs .)

                jq -n --argjson diff "$DIFF_ESCAPED" '{
                    "hookSpecificOutput": {
                        "additionalContext": ("⚠️ File modified externally since your last read. Diff (--- old, +++ current):\n" + $diff)
                    }
                }'

                # Update snapshot to current
                cp "$FILE_PATH" "$SNAPSHOT"
            fi
        fi
    fi
fi
