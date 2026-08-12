# writeChunk caching regression test

Not part of the CTAN release (`.ctan.sh` never copies `examples/`) — this
is a developer-only regression test for `\writeChunk`'s caching logic.

## Why this exists

`\writeChunk` (called by `\showChunk`) used to re-scan its whole source
file line by line on every call, with no caching at all — the slowest
command in the package by far on documents with many `\showChunk` calls.
The fix added a cache, gated on `\ifruncode` to match how `\runExtCode`
and `\inln` already behave:

- **dev mode** (`\ifruncode` true, the default): an MD5 checksum of the
  source file decides whether to trust the cached extraction or rescan.
- **cache mode** (the `cache` package option — used for Overleaf
  submission via `make_overleaf.py`, and for repeated `xelatex` passes
  once a project's own build sets `ForceCache`): the checksum subprocess
  is skipped entirely; an existing `generated/<file>-<label>.txt` is
  trusted outright, with zero `python3` calls. This is what makes
  Overleaf's own compile fast — see the nostarch project's
  `make_overleaf.py` for the pre-extraction step this depends on.

## The factorial design

Two independent factors, each affecting `\writeChunk`'s behavior:

| | A: `\ifruncode` true (dev) | A: `\ifruncode` false (cache) |
|---|---|---|
| **B: missing** | 1. scans, extracts | 4. falls back to a scan |
| **C: exists, fresh** | 2. skips scan, reuses cache | 5. trusts it, **zero subprocess calls** |
| **C: exists, stale** | 3. rescans, updates | 6. **blindly serves the stale content anyway** (by design — cache mode never verifies freshness, matching `\runExtCode`/`\inln`) |

Missing/fresh/stale only apply once the cache file could exist, so this
is 6 meaningful cells, not a full 2x2x2. Case 6 looks like a bug at first
glance but is the documented, intentional contract of cache mode; the
test exists to keep that behavior locked in, not to "fix" it.

## Running it

```
./run_tests.sh
```

Requires `xelatex` with `--shell-escape` and `python3` on `PATH`. No R (or
any other language) runtime is needed — this test only exercises
`\showChunk`, never actually executes code. Cases 5 and 6 prove "zero
subprocess calls" by putting a poisoned `python3` (one that logs its
invocation and exits nonzero) on `PATH` for that compile; the real
`python3` is used everywhere else. The script cleans up all build
artifacts (`generated/`, `.aux`, `.log`, `.mw`, `.pdf`) on exit and
restores `code/stats.R` after case 3's deliberate edit.

Any future change to `\writeChunk`'s caching should re-run this before
being considered verified — see the commit that introduced it for an
example of testing only 3 of these 6 cells and missing a real regression
that a full run would have caught.
