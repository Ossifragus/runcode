#!/bin/bash
# run_tests.sh -- writeChunk caching regression test.
#
# Exercises the full factorial design behind writeChunk's cache logic:
#   A: \ifruncode true (dev mode, DevModeTest.tex)
#      vs false (cache mode, CacheModeTest.tex, the "cache" package option)
#   B/C: generated/<file>-<label>.txt is missing, fresh (matches the
#      current source), or stale (source changed since it was written)
#
# giving 6 meaningful cells (missing/fresh/stale only apply once the file
# could exist, so this isn't a full 2x2x2). Each cell has a distinct
# expected behavior -- see README.md. Requires --shell-escape-capable
# xelatex on PATH; no R/Python runtime dependency beyond python3 itself
# (writeChunk's own makedirs/hashing calls), since this test only
# exercises \showChunk, never actually executes R code.
#
# Usage: ./run_tests.sh   (run from this directory)

set -u
cd "$(dirname "$0")"

PASS=0
FAIL=0

note() { printf '  %s\n' "$1"; }
pass() { PASS=$((PASS+1)); printf 'PASS: %s\n' "$1"; }
fail() { FAIL=$((FAIL+1)); printf 'FAIL: %s\n' "$1"; }

# A "poisoned" python3 that logs its invocation and fails loudly, used to
# prove "zero subprocess calls" claims instead of just asserting them.
# Prints the fake-bin dir on stdout; the call log is always <dir>/calls.log
# (derived by the caller, not returned separately -- a function invoked via
# $(...) runs in a subshell, so it cannot set a variable in the caller).
make_poisoned_python3() {
  local dir; dir=$(mktemp -d)
  : > "$dir/calls.log"
  cat > "$dir/python3" <<EOF
#!/bin/bash
echo "\$@" >> "$dir/calls.log"
exit 1
EOF
  chmod +x "$dir/python3"
  echo "$dir"
}

compile() {
  local tex="$1" path_prefix="${2:-}"
  PATH="${path_prefix:+$path_prefix:}$PATH" \
    xelatex -shell-escape -interaction=nonstopmode "$tex" \
    > "${tex%.tex}.compile.log" 2>&1
}

reset_source() {
  cat > code/stats.R <<'EOF'
# label===chunk_a
cat("n =", 10, "\n")
# ===end

# label===chunk_b
cat("mean =", 5, "\n")
# ===end
EOF
}

echo "== writeChunk caching regression test =="
echo

# ── Cases 1-3: dev mode (A=true), via DevModeTest.tex ───────────────────
echo "-- Cases 1-3: dev mode (\\ifruncode true) --"
rm -rf generated && mkdir generated
reset_source

# Case 1: dev, missing -> scan runs, extracts correctly.
compile DevModeTest.tex
if [ -f generated/code/stats.R-chunk_a.txt ] && \
   grep -qF 'cat("n =", 10, "\n")' generated/code/stats.R-chunk_a.txt; then
  pass "1: dev+missing extracts correctly"
else
  fail "1: dev+missing did not extract expected content"
fi

# Case 2: dev, fresh -> skip scan, reuse cache (mtime unchanged).
mtime_before=$(stat -f %m generated/code/stats.R-chunk_a.txt 2>/dev/null || stat -c %Y generated/code/stats.R-chunk_a.txt)
sleep 1.5
compile DevModeTest.tex
mtime_after=$(stat -f %m generated/code/stats.R-chunk_a.txt 2>/dev/null || stat -c %Y generated/code/stats.R-chunk_a.txt)
if [ "$mtime_before" = "$mtime_after" ]; then
  pass "2: dev+fresh skips rescan (mtime unchanged)"
else
  fail "2: dev+fresh rescanned an unchanged source (mtime changed)"
fi

# Case 3: dev, stale -> source edited, rescan updates the changed chunk
# and still produces correct content for an untouched chunk in the same
# file (staleness is file-level, not per-chunk).
sed -i.bak 's/cat("n =", 10, "\\n")/cat("STALE_TEST_MARKER n =", 10, "\\n")/' code/stats.R
rm -f code/stats.R.bak
compile DevModeTest.tex
ok=true
grep -qF 'STALE_TEST_MARKER' generated/code/stats.R-chunk_a.txt || ok=false
grep -qF 'cat("mean =", 5, "\n")' generated/code/stats.R-chunk_b.txt || ok=false
reset_source
if $ok; then
  pass "3: dev+stale rescans edited chunk, leaves sibling chunk correct"
else
  fail "3: dev+stale did not update correctly"
fi

echo

# ── Cases 4-6: cache mode (A=false), via CacheModeTest.tex ──────────────
echo "-- Cases 4-6: cache mode (\\ifruncode false, the \"cache\" option) --"

# Case 4: cache, missing -> falls back to a real scan (needs real python3
# for its own makedirs call; this is not the staleness check being
# tested, so python3 is not poisoned here).
rm -rf generated && mkdir generated
compile CacheModeTest.tex
if [ -f generated/code/stats.R-chunk_a.txt ] && \
   grep -qF 'cat("n =", 10, "\n")' generated/code/stats.R-chunk_a.txt; then
  pass "4: cache+missing falls back to a scan and extracts correctly"
else
  fail "4: cache+missing did not extract expected content"
fi

# Case 5: cache, fresh -> trusts the existing file outright, zero
# subprocess calls at all (proven with a poisoned python3 on PATH).
fake_dir=$(make_poisoned_python3)
compile CacheModeTest.tex "$fake_dir"
calls=$(wc -l < "$fake_dir/calls.log" | tr -d ' ')
if [ "$calls" = "0" ] && grep -qF 'cat("n =", 10, "\n")' generated/code/stats.R-chunk_a.txt; then
  pass "5: cache+fresh makes zero python3 calls, content correct"
else
  fail "5: cache+fresh called python3 $calls time(s) or content wrong"
fi
rm -rf "$fake_dir"

# Case 6: cache, stale -> by design, cache mode never checks freshness,
# so a deliberately wrong cached file is served as-is, still with zero
# subprocess calls. This is the documented, intentional contract (same
# as \runExtCode/\inln in cache mode), not a bug -- this test exists to
# prove it stays true, not to "fix" it.
printf 'cat("n =", 1, "\\n")  # DELIBERATELY STALE' > generated/code/stats.R-chunk_a.txt
fake_dir=$(make_poisoned_python3)
compile CacheModeTest.tex "$fake_dir"
calls=$(wc -l < "$fake_dir/calls.log" | tr -d ' ')
if [ "$calls" = "0" ] && grep -qF 'DELIBERATELY STALE' generated/code/stats.R-chunk_a.txt; then
  pass "6: cache+stale blindly serves stale content, zero python3 calls"
else
  fail "6: cache+stale called python3 $calls time(s) or did not serve the stale content as expected"
fi
rm -rf "$fake_dir"

echo
echo "== $PASS passed, $FAIL failed =="
rm -rf generated *.aux *.log *.mw *.pdf *.compile.log
[ "$FAIL" = "0" ]
