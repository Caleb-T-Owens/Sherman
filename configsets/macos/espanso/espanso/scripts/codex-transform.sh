#!/bin/bash

DEFAULT_INSTRUCTION="Improve the text for clarity while preserving the original meaning and tone."
WORKDIR="$HOME/Sherman"

cleanup() {
  if [ -n "${PROMPT_FILE:-}" ] && [ -e "$PROMPT_FILE" ]; then rm -f "$PROMPT_FILE"; fi
  if [ -n "${OUT_FILE:-}" ] && [ -e "$OUT_FILE" ]; then rm -f "$OUT_FILE"; fi
  if [ -n "${ERR_FILE:-}" ] && [ -e "$ERR_FILE" ]; then rm -f "$ERR_FILE"; fi
}

trap cleanup EXIT

INPUT_TEXT="${ESPANSO_FORM1_TEXT:-}"
if [ -z "$INPUT_TEXT" ]; then
  INPUT_TEXT="$(pbpaste)"
fi

if [ -z "$INPUT_TEXT" ]; then
  exit 0
fi

INSTRUCTION="${ESPANSO_FORM1_INSTRUCTION:-${1:-}}"
if [ -z "$INSTRUCTION" ]; then
  INSTRUCTION="$DEFAULT_INSTRUCTION"
fi

PROMPT_FILE="$(mktemp)"
OUT_FILE="$(mktemp)"
ERR_FILE="$(mktemp)"

cat > "$PROMPT_FILE" <<EOF
Transform the provided text according to the instruction.

Instruction:
$INSTRUCTION

Text:
<<<TEXT
$INPUT_TEXT
TEXT

Constraints:
- Return only the transformed text.
- Do not add commentary, markdown fences, or labels.
EOF

if codex exec --ephemeral --color never -C "$WORKDIR" -o "$OUT_FILE" - < "$PROMPT_FILE" > /dev/null 2> "$ERR_FILE"; then
  cat "$OUT_FILE"
else
  printf "%s" "$INPUT_TEXT"
fi
