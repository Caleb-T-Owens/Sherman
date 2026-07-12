#!/bin/bash
# End-to-end check for sherman.  Builds a throwaway repo + HOME in a temp
# dir and asserts the core semantics: copy verb, dep ordering, hash-skip,
# re-run on change, always, failure poisoning, GC undo, hand-edit guard,
# cycle rejection.  Run: ./test.sh
set -euo pipefail

cd "$(dirname "$0")"
cc -std=c11 -O2 -Wall -Wextra -Werror -o sherman-bin ./*.c

T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT
export HOME="$T/home"
export SHERMAN_DIR="$T/repo"
export SHERMAN_STATE_DIR="$T/state"
mkdir -p "$HOME" "$SHERMAN_DIR/configsets/envs"
BIN="$PWD/sherman-bin"

fail() { echo "TEST FAILED: $*" >&2; exit 1; }

cs() { mkdir -p "$SHERMAN_DIR/configsets/$1"; }

# --- fixture configsets -----------------------------------------------
cs a
echo "hello" > "$SHERMAN_DIR/configsets/a/f.txt"
cat > "$SHERMAN_DIR/configsets/a/sherman.md" <<'EOF'
# a — plain copy verb
```change
copy f.txt $HOME/f.txt
```
EOF

cs b
cat > "$SHERMAN_DIR/configsets/b/sherman.md" <<'EOF'
# b — script with declared out; dep on a must be applied first
```deps
a
```
```install
test -e $HOME/f.txt   # ordering assertion
echo streaming-hello-from-b
echo made-by-b > $HOME/b.txt
```
```out
$HOME/b.txt
```
```uninstall
echo "undo ran" >> $HOME/undo-log.txt
```
EOF

cs boom
cat > "$SHERMAN_DIR/configsets/boom/sherman.md" <<'EOF'
```install
exit 7
```
EOF

cs after-boom
cat > "$SHERMAN_DIR/configsets/after-boom/sherman.md" <<'EOF'
```deps
boom
```
```install
echo should-never-run > $HOME/poison.txt
EOF
echo '```' >> "$SHERMAN_DIR/configsets/after-boom/sherman.md"

cs alw
cat > "$SHERMAN_DIR/configsets/alw/sherman.md" <<'EOF'
```always
```
```install
echo tick >> $HOME/ticks.txt
```
EOF

cs dir
mkdir -p "$SHERMAN_DIR/configsets/dir/tree/sub"
chmod 0700 "$SHERMAN_DIR/configsets/dir/tree/sub"
echo one > "$SHERMAN_DIR/configsets/dir/tree/x.txt"
echo two > "$SHERMAN_DIR/configsets/dir/tree/sub/y.txt"
cat > "$SHERMAN_DIR/configsets/dir/sherman.md" <<'EOF'
```change
copy tree $HOME/.config/tree
```
EOF

cat > "$SHERMAN_DIR/configsets/envs/t1.md" <<'EOF'
```deps
a
b
boom
after-boom
alw
dir
```
EOF

cat > "$SHERMAN_DIR/configsets/envs/t2.md" <<'EOF'
```deps
a
```
EOF

# --- 0: status is strictly read-only, even before state exists ---------
out="$("$BIN" status t1 2>&1)"             || fail "initial status failed: $out"
[ ! -e "$SHERMAN_STATE_DIR" ]              || fail "status created state"

# --- 1: apply t1 — a,b,alw,dir ok; boom fails; after-boom skipped ------
out="$("$BIN" apply t1 2>&1)" && fail "apply t1 should exit nonzero (boom)"
echo "$out" | grep -q '^\[ ok \] a ('        || fail "a did not apply: $out"
echo "$out" | grep -q '^\[ ok \] b ('        || fail "b did not apply"
echo "$out" | grep -q '^\[fail\] boom ('     || fail "boom did not fail"
echo "$out" | grep -q '^\[skip\] after-boom ' || fail "after-boom not skipped"
[ "$(cat "$HOME/f.txt")" = hello ]          || fail "f.txt wrong"
[ "$(cat "$HOME/b.txt")" = made-by-b ]      || fail "b.txt wrong"
[ ! -e "$HOME/poison.txt" ]                 || fail "poisoned node ran"
[ "$(cat "$HOME/.config/tree/sub/y.txt")" = two ] || fail "dir copy wrong"
[ "$(wc -l < "$HOME/ticks.txt")" -eq 1 ]    || fail "always ran wrong count"
echo "$out" | grep -q '^b  *| streaming-hello-from-b$' || fail "stdout not streamed"

# --- 2: re-apply — everything unchanged is skipped, always re-runs -----
out="$("$BIN" apply t1 2>&1)" || true
echo "$out" | grep -q '^\[ = \] a ('         || fail "a not up to date"
echo "$out" | grep -q '^\[ = \] dir ('       || fail "dir not up to date"
[ "$(wc -l < "$HOME/ticks.txt")" -eq 2 ]    || fail "always did not re-run"

# Managed output drift is reconciled even when inputs are unchanged.
expected_mode="$(stat -f %Lp "$SHERMAN_DIR/configsets/a/f.txt" 2>/dev/null ||
                 stat -c %a "$SHERMAN_DIR/configsets/a/f.txt")"
echo tampered > "$HOME/f.txt"
chmod 600 "$HOME/f.txt"
echo extra > "$HOME/.config/tree/extra.txt"
mkdir "$HOME/.config/tree/extra-empty"
chmod 0755 "$HOME/.config/tree/sub"
out="$("$BIN" apply t1 2>&1)" || true
echo "$out" | grep -q '^\[ ok \] a ('         || fail "content/mode drift did not re-run a"
echo "$out" | grep -q '^\[ ok \] dir ('       || fail "directory drift did not re-run dir"
[ "$(cat "$HOME/f.txt")" = hello ]           || fail "drifted file was not restored"
[ ! -e "$HOME/.config/tree/extra.txt" ]       || fail "extra directory output was not removed"
[ ! -e "$HOME/.config/tree/extra-empty" ]     || fail "extra empty output dir was not removed"
[ "$(stat -f %Lp "$HOME/.config/tree/sub" 2>/dev/null || stat -c %a "$HOME/.config/tree/sub")" = 700 ] ||
    fail "drifted directory mode was not restored"
[ "$(stat -f %Lp "$HOME/f.txt" 2>/dev/null || stat -c %a "$HOME/f.txt")" = "$expected_mode" ] ||
    fail "drifted file mode was not restored"

# --- 3: change an input — only that node re-runs -----------------------
echo changed > "$SHERMAN_DIR/configsets/a/f.txt"
out="$("$BIN" apply t1 2>&1)" || true
echo "$out" | grep -q '^\[ ok \] a ('        || fail "a did not re-run on change"
echo "$out" | grep -q '^\[ = \] b ('         || fail "b should stay up to date"
[ "$(cat "$HOME/f.txt")" = changed ]        || fail "f.txt not updated"

# --- 4: status is read-only and reports the plan ------------------------
echo changed-again > "$SHERMAN_DIR/configsets/a/f.txt"
out="$("$BIN" status t1 2>&1)"
echo "$out" | grep -q '^\[  run   \] a ('    || fail "status missed pending a"
echo "$out" | grep -q '^\[up2date \] b$'     || fail "status missed up2date b"
[ "$(cat "$HOME/f.txt")" = changed ]        || fail "status must not write"
"$BIN" apply t1 >/dev/null 2>&1 || true

# --- 5: switch to env t2 — b, dir etc. are undone via GC ---------------
sed -i.bak 's/made-by-b/tampered/' "$HOME/b.txt" && rm -f "$HOME/b.txt.bak"
echo t2 > "$SHERMAN_DIR/CURRENT_ENV"
out="$("$BIN" apply t2 2>&1)" || fail "apply t2 failed: $out"
grep -q "undo ran" "$HOME/undo-log.txt"     || fail "uninstall script not run"
[ -e "$HOME/b.txt" ]                        || fail "hand-edited out was deleted"
[ ! -e "$HOME/.config/tree/x.txt" ]         || fail "dir outs not removed by gc"
[ -e "$HOME/f.txt" ]                        || fail "kept node was wrongly undone"

# --- 6: missing input is a loud failure --------------------------------
cs miss
cat > "$SHERMAN_DIR/configsets/miss/sherman.md" <<'EOF'
```in
does-not-exist.txt
```
EOF
cat > "$SHERMAN_DIR/configsets/envs/t3.md" <<'EOF'
```deps
miss
```
EOF
out="$("$BIN" apply t3 2>&1)" && fail "missing input should fail"
echo "$out" | grep -q 'missing input'       || fail "missing-input message absent"

# --- 7: cycles are rejected at load -------------------------------------
cs cyc1; cs cyc2
printf '```deps\ncyc2\n```\n' > "$SHERMAN_DIR/configsets/cyc1/sherman.md"
printf '```deps\ncyc1\n```\n' > "$SHERMAN_DIR/configsets/cyc2/sherman.md"
printf '```deps\ncyc1\n```\n' > "$SHERMAN_DIR/configsets/envs/t4.md"
out="$("$BIN" status t4 2>&1)" && fail "cycle should be fatal"
echo "$out" | grep -q 'cycle'               || fail "cycle message absent"

# --- 8: a longer fence can carry a script containing bare ``` ----------
cs fence
cat > "$SHERMAN_DIR/configsets/fence/sherman.md" <<'FENCEMD'
````install
cat > $HOME/fence.txt <<'DONE'
```
DONE
echo second >> $HOME/fence.txt
````
FENCEMD
printf '```deps\nfence\n```\n' > "$SHERMAN_DIR/configsets/envs/t8.md"
"$BIN" apply t8 >/dev/null 2>&1             || fail "fence apply failed"
[ "$(wc -l < "$HOME/fence.txt")" -eq 2 ]    || fail "embedded fence truncated the script"
grep -q '^```$' "$HOME/fence.txt"           || fail "embedded fence content wrong"

# --- 9: renaming a configset must not GC the files it still owns -------
cs old-name
echo samecontent > "$SHERMAN_DIR/configsets/old-name/r.txt"
printf '```change\ncopy r.txt $HOME/renamed.txt\n```\n' > "$SHERMAN_DIR/configsets/old-name/sherman.md"
printf '```deps\nold-name\n```\n' > "$SHERMAN_DIR/configsets/envs/t9.md"
echo t9 > "$SHERMAN_DIR/CURRENT_ENV"
"$BIN" apply t9 >/dev/null 2>&1             || fail "t9 apply failed"
cp -R "$SHERMAN_DIR/configsets/old-name" "$SHERMAN_DIR/configsets/new-name"
printf '```deps\nnew-name\n```\n' > "$SHERMAN_DIR/configsets/envs/t9.md"
out="$("$BIN" apply t9 2>&1)"               || fail "t9 rename apply failed: $out"
[ -e "$HOME/renamed.txt" ]                  || fail "GC deleted a renamed node's file"
[ ! -e "$SHERMAN_STATE_DIR/old-name/hash" ] || fail "old state entry not GCed"

# --- 10: an env that differs from CURRENT_ENV must not GC --------------
echo t9 > "$SHERMAN_DIR/CURRENT_ENV"
out="$("$BIN" apply t2 2>&1)" || true
echo "$out" | grep -q 'gc \] skipped'       || fail "gc-skip note missing: $out"
[ -e "$HOME/renamed.txt" ]                  || fail "mismatched env GC'd another env's files"
rm "$SHERMAN_DIR/CURRENT_ENV"

# Missing CURRENT_ENV is also never permission to GC.
out="$("$BIN" apply t2 2>&1)"               || fail "apply without CURRENT_ENV failed: $out"
echo "$out" | grep -q 'CURRENT_ENV is missing' || fail "missing-CURRENT_ENV note absent: $out"
[ -e "$HOME/renamed.txt" ]                  || fail "missing CURRENT_ENV enabled GC"
[ -e "$SHERMAN_STATE_DIR/new-name/hash" ]   || fail "missing CURRENT_ENV removed state"

# --- 11: a chmod on an input re-runs the node --------------------------
"$BIN" apply t2 >/dev/null 2>&1             || fail "t2 re-baseline failed"
chmod 755 "$SHERMAN_DIR/configsets/a/f.txt"
out="$("$BIN" apply t2 2>&1)"               || fail "t2 apply after chmod failed"
echo "$out" | grep -q '^\[ ok \] a ('       || fail "mode change did not re-run node"

# --- 12: concurrent runs are rejected before touching shared state -----
cs slow
printf '```install\nsleep 1\n```\n' > "$SHERMAN_DIR/configsets/slow/sherman.md"
printf '```deps\nslow\n```\n' > "$SHERMAN_DIR/configsets/envs/t12.md"
"$BIN" apply t12 >/dev/null 2>&1 &
first_pid=$!
sleep 0.1
out="$("$BIN" apply t12 2>&1)" && fail "concurrent apply should fail"
echo "$out" | grep -q 'already running'     || fail "concurrent-run message absent: $out"
wait "$first_pid"                           || fail "first concurrent apply failed"

# --- 13: a failed graph must not GC the last known-good config ---------
cs old-good
echo kept > "$SHERMAN_DIR/configsets/old-good/kept.txt"
printf '```change\ncopy kept.txt $HOME/kept.txt\n```\n' > "$SHERMAN_DIR/configsets/old-good/sherman.md"
printf '```deps\nold-good\n```\n' > "$SHERMAN_DIR/configsets/envs/t13-good.md"
printf '```deps\nboom\n```\n' > "$SHERMAN_DIR/configsets/envs/t13-bad.md"
echo t13-good > "$SHERMAN_DIR/CURRENT_ENV"
"$BIN" apply t13-good >/dev/null 2>&1       || fail "good baseline apply failed"
echo t13-bad > "$SHERMAN_DIR/CURRENT_ENV"
out="$("$BIN" apply t13-bad 2>&1)" && fail "bad replacement should fail"
echo "$out" | grep -q 'gc \] deferred'     || fail "failed-GC deferral absent: $out"
[ -e "$HOME/kept.txt" ]                    || fail "failed apply GCed known-good output"
[ -e "$SHERMAN_STATE_DIR/old-good/hash" ]  || fail "failed apply GCed known-good state"

# --- 14: always still validates inputs --------------------------------
cs always-miss
printf '```always\n```\n```in\nmissing.txt\n```\n' > "$SHERMAN_DIR/configsets/always-miss/sherman.md"
printf '```deps\nalways-miss\n```\n' > "$SHERMAN_DIR/configsets/envs/t14.md"
out="$("$BIN" apply t14 2>&1)" && fail "always node accepted a missing input"
echo "$out" | grep -q 'missing input'       || fail "always missing-input message absent: $out"

# --- 15: filesystem aliases are rejected before execution --------------
cs nested/real
printf '```deps\nnested/./real\n```\n' > "$SHERMAN_DIR/configsets/envs/t15-alias.md"
out="$("$BIN" status t15-alias 2>&1)" && fail "dot-component node alias was accepted"
echo "$out" | grep -q 'bad configset name' || fail "node alias error absent: $out"

cs dangerous
mkdir -p "$SHERMAN_DIR/configsets/dangerous/tree" "$HOME/victim"
echo safe > "$HOME/marker"
printf '```change\ncopy tree $HOME/victim/..\n```\n' > "$SHERMAN_DIR/configsets/dangerous/sherman.md"
printf '```deps\ndangerous\n```\n' > "$SHERMAN_DIR/configsets/envs/t15-path.md"
out="$("$BIN" apply t15-path 2>&1)" && fail "dot-component destination was accepted"
echo "$out" | grep -q 'non-canonical path' || fail "destination guard error absent: $out"
[ "$(cat "$HOME/marker")" = safe ]         || fail "unsafe destination modified HOME"

echo source > "$SHERMAN_DIR/configsets/dangerous/file"
echo original > "$HOME/target"
printf '```change\ncopy file $HOME/victim/../target\n```\n' > "$SHERMAN_DIR/configsets/dangerous/sherman.md"
out="$("$BIN" apply t15-path 2>&1)" && fail "file dot-component destination was accepted"
echo "$out" | grep -q 'non-canonical path' || fail "file destination guard error absent: $out"
[ "$(cat "$HOME/target")" = original ]      || fail "unsafe file destination overwrote target"

# --- 16: failed GC keeps state and reports failure ---------------------
cs stubborn
mkdir -p "$HOME/locked"
echo stubborn > "$SHERMAN_DIR/configsets/stubborn/file"
printf '```change\ncopy file $HOME/locked/file\n```\n' > "$SHERMAN_DIR/configsets/stubborn/sherman.md"
printf '```deps\nstubborn\n```\n' > "$SHERMAN_DIR/configsets/envs/t16-full.md"
printf '```deps\n```\n' > "$SHERMAN_DIR/configsets/envs/t16-empty.md"
echo t16-full > "$SHERMAN_DIR/CURRENT_ENV"
"$BIN" apply t16-full >/dev/null 2>&1       || fail "stubborn baseline failed"
echo t16-empty > "$SHERMAN_DIR/CURRENT_ENV"
chmod 0000 "$HOME/locked/file"
out="$("$BIN" apply t16-empty 2>&1)" && fail "unverifiable output should make GC fail"
echo "$out" | grep -q 'cannot verify'      || fail "GC verification failure absent: $out"
[ -e "$SHERMAN_STATE_DIR/stubborn/hash" ]  || fail "unverifiable output discarded state"
chmod 0644 "$HOME/locked/file"
chmod 0555 "$HOME/locked"
out="$("$BIN" apply t16-empty 2>&1)" && fail "failed GC should make apply fail"
echo "$out" | grep -q 'removal failed'     || fail "GC failure message absent: $out"
[ -e "$HOME/locked/file" ]                 || fail "GC failure test lost output unexpectedly"
[ -e "$SHERMAN_STATE_DIR/stubborn/hash" ]  || fail "failed GC discarded state"
chmod 0755 "$HOME/locked"
"$BIN" apply t16-empty >/dev/null 2>&1      || fail "GC retry failed"
[ ! -e "$HOME/locked/file" ]               || fail "GC retry did not remove output"

# --- 17: malformed CLI input is rejected -------------------------------
out="$("$BIN" -j 2oops status t2 2>&1)" && fail "malformed -j was accepted"
echo "$out" | grep -q -- '-j must be'      || fail "malformed -j error absent: $out"
"$BIN" status t2 extra >/dev/null 2>&1 && fail "extra CLI argument was accepted"

# --- 18: a declared empty output directory is reconciled ---------------
cs empty-out
printf '```install\nmkdir -p "$HOME/required-empty"\n```\n```out\n$HOME/required-empty\n```\n' > "$SHERMAN_DIR/configsets/empty-out/sherman.md"
printf '```deps\nempty-out\n```\n' > "$SHERMAN_DIR/configsets/envs/t18.md"
echo t18 > "$SHERMAN_DIR/CURRENT_ENV"
"$BIN" apply t18 >/dev/null 2>&1             || fail "empty-out baseline failed"
rmdir "$HOME/required-empty"
out="$("$BIN" apply t18 2>&1)"               || fail "empty-out reconcile failed: $out"
echo "$out" | grep -q '^\[ ok \] empty-out (' || fail "missing empty output did not re-run"
[ -d "$HOME/required-empty" ]                || fail "empty output directory not restored"

# --- 19: symlinks are preserved and never recursively followed ---------
cs links
echo one > "$SHERMAN_DIR/configsets/links/referent"
ln -s "$SHERMAN_DIR/configsets/links/referent" "$SHERMAN_DIR/configsets/links/link"
ln -s missing "$SHERMAN_DIR/configsets/links/dangling"
mkdir "$SHERMAN_DIR/configsets/links/tree"
ln -s . "$SHERMAN_DIR/configsets/links/tree/loop"
printf '```change\ncopy link $HOME/copied-link\ncopy dangling $HOME/copied-dangling\ncopy tree $HOME/copied-tree\n```\n' > "$SHERMAN_DIR/configsets/links/sherman.md"
printf '```deps\nlinks\n```\n' > "$SHERMAN_DIR/configsets/envs/t19.md"
echo t19 > "$SHERMAN_DIR/CURRENT_ENV"
"$BIN" apply t19 >/dev/null 2>&1             || fail "symlink baseline failed"
[ -L "$HOME/copied-link" ]                  || fail "file symlink was dereferenced"
[ -L "$HOME/copied-dangling" ]              || fail "dangling symlink was rejected"
[ -L "$HOME/copied-tree/loop" ]             || fail "directory symlink was followed"
echo two > "$SHERMAN_DIR/configsets/links/referent"
out="$("$BIN" apply t19 2>&1)"               || fail "symlink reapply failed: $out"
echo "$out" | grep -q '^\[ = \] links ('    || fail "referent-only change reran symlink copy"
[ "$(cat "$HOME/copied-link")" = two ]      || fail "preserved symlink did not expose referent change"

# --- 20: empty input directories and their modes affect the hash -------
cs dir-input
mkdir "$SHERMAN_DIR/configsets/dir-input/input"
printf '```in\ninput\n```\n```install\necho run >> "$HOME/dir-input-runs"\n```\n' > "$SHERMAN_DIR/configsets/dir-input/sherman.md"
printf '```deps\ndir-input\n```\n' > "$SHERMAN_DIR/configsets/envs/t20.md"
echo t20 > "$SHERMAN_DIR/CURRENT_ENV"
"$BIN" apply t20 >/dev/null 2>&1             || fail "dir-input baseline failed"
mkdir "$SHERMAN_DIR/configsets/dir-input/input/empty"
out="$("$BIN" apply t20 2>&1)"               || fail "empty input-dir apply failed: $out"
echo "$out" | grep -q '^\[ ok \] dir-input (' || fail "empty input directory did not change hash"
chmod 0700 "$SHERMAN_DIR/configsets/dir-input/input/empty"
out="$("$BIN" apply t20 2>&1)"               || fail "input dir-mode apply failed: $out"
echo "$out" | grep -q '^\[ ok \] dir-input (' || fail "input directory mode did not change hash"
[ "$(wc -l < "$HOME/dir-input-runs")" -eq 3 ] || fail "dir-input run count wrong"

echo "ALL TESTS PASSED"
