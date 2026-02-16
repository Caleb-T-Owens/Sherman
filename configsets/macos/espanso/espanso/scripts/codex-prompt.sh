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
Take the following text and try to refine it into a prompt for a coding LLM.

We want to phrase the message as a task being given to a colleauge. We should
always encourage the colleauge to ask for clarification at the end of our
message.

This text has been dictated and could do with being refined. Sometimes there are
corrections to previous things that have been spoken that need cleaned up.

If the prompt says not to implement something that was previously asked for in
the dictated text, omit any mention of it entirly. We don't need to complicate
the prompt with any mention of it.

Because the text has been dictated, the order and structure of the origional
text is not good. Try to restructure it to be easy to understand, using markdown
headings and sub-headings. Try to avoid being overly specific, and trust that
the programmer can use their judgement.

If you think there is any ambigous details about the feature in the origional
text, return the origional text verbaitim, followed by "Clarifications:" And
then have a list of clarifications for me to provide.

Don't leave placeholders in the final prompt. Only ask for clarifications if you return the origional text verbaitim.

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
