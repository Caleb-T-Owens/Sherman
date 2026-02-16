#!/bin/bash

WORKDIR="$HOME/Sherman"

cleanup() {
  if [ -n "${PROMPT_FILE:-}" ] && [ -e "$PROMPT_FILE" ]; then rm -f "$PROMPT_FILE"; fi
  if [ -n "${OUT_FILE:-}" ] && [ -e "$OUT_FILE" ]; then rm -f "$OUT_FILE"; fi
  if [ -n "${ERR_FILE:-}" ] && [ -e "$ERR_FILE" ]; then rm -f "$ERR_FILE"; fi
}

trap cleanup EXIT

INPUT_TEXT="${ESPANSO_CLIPB:-}"

if [ -z "$INPUT_TEXT" ]; then
  exit 0
fi

PROMPT_FILE="$(mktemp)"
OUT_FILE="$(mktemp)"
ERR_FILE="$(mktemp)"

cat > "$PROMPT_FILE" <<EOF
Transform the provided text according to the instruction.

Instruction:
Take the following text and act as an editor, making sure the message doesn't
come across as negative or has aggressive undertones.

Try to leave the origional message in tact as much as possible.

Please avoid adding any em-dashes or emoji.

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
