#!/usr/bin/env python3
# Copyright (C) 2020-2026 by Haim Bar and HaiYing Wang
# Part of the runcode package XXX-Date Version-XXX
# https://github.com/Ossifragus/runcode
#
# This file may be distributed and/or modified under the conditions of
# the LaTeX Project Public License, either version 1.3c of this license
# or (at your option) any later version.
# The latest version of this license is in http://www.latex-project.org/lppl.txt

"""consolidate.py — produce a self-contained LaTeX project from a runcode document.

After a successful build (all code executed, outputs cached in generated/),
this script:
  1. Copies the project to a standalone output directory.
  2. Transforms all .tex files: replaces runcode output commands with their
     cached content so the result compiles without talk2stat or any language
     runtime.
  3. Replaces \\usepackage{runcode} with a minimal shim (tcolorbox + listings).
  4. Optionally compiles the result.

Supported commands (all language variants — R, Python, Julia, MatLab):
  \\runR / \\runPython / ...        removed (output shown via \\includeOutput)
  \\runRIncOut / ...                replaced with cached content
  \\runRChunk / ...                 replaced with cached content
  \\includeOutput{label}[type]      replaced with cached content
  \\inlnR{code}[label][type] / ... replaced with cached content
  \\inln{cmd}{code}[label][type]    replaced with cached content
  \\showCode / \\showChunk          kept; minimal shim uses lstinputlisting

Auto-numbered outputs (no explicit label) are left as-is; review them manually.

Motivated by the Overleaf use case (Overleaf cannot run talk2stat) but the
output is general: any recipient can compile it with plain pdflatex.

Usage:
  python3 consolidate.py [OPTIONS] MAIN.tex

Options:
  --out DIR        output directory (default: standalone)
  --engine CMD     LaTeX engine for compilation (default: pdflatex)
  --no-compile     copy and transform only; skip compilation
  --exclude GLOB   additional glob pattern to exclude (repeatable)
"""

import argparse
import re
import shutil
import subprocess
import sys
from fnmatch import fnmatch
from pathlib import Path


# ── Default copy excludes ──────────────────────────────────────────────────────

DEFAULT_EXCLUDES = frozenset({
    "*.aux", "*.log", "*.out", "*.toc", "*.bbl", "*.blg",
    "*.idx", "*.ilg", "*.ind", "*.mw", "*.xdv", "*.tbc",
    "*.fls", "*.fdb_latexmk", "*.synctex.gz",
    "nohup.out", "serverPID*.txt", "*debug.txt", "talk2stat.log",
    "*.stale", "*.md5",
})


# ── Shim inserted in place of \usepackage[...]{runcode} ───────────────────────

RUNCODE_SHIM = r"""\usepackage{tcolorbox}
\tcbuselibrary{breakable,skins}
\usepackage{listings}
\usepackage{xparse}
% consolidate.py shim: replaces \usepackage{runcode} for standalone compilation
% Display commands (functional via listings):
\NewDocumentCommand{\showCode}{m m O{} O{}}{\lstinputlisting{#2}}
\NewDocumentCommand{\showChunk}{m m m O{} O{}}{\lstinputlisting{generated/#2-#3.txt}}
% Execution commands (no-ops: outputs already inlined by consolidate.py):
\NewDocumentCommand{\runExtCode}{m m m O{}}{}
\NewDocumentCommand{\runCodeIncOut}{m m O{} O{} O{vbox}}{}
\NewDocumentCommand{\runR}{O{} m m O{}}{}
\NewDocumentCommand{\runRIncOut}{O{} m O{} O{} O{vbox}}{}
\NewDocumentCommand{\runRChunk}{O{} m m O{} O{} O{vbox}}{}
\NewDocumentCommand{\runPython}{O{} m m O{}}{}
\NewDocumentCommand{\runPythonIncOut}{O{} m O{} O{} O{vbox}}{}
\NewDocumentCommand{\runPythonChunk}{O{} m m O{} O{} O{vbox}}{}
\NewDocumentCommand{\runJulia}{O{} m m O{}}{}
\NewDocumentCommand{\runJuliaIncOut}{O{} m O{} O{} O{vbox}}{}
\NewDocumentCommand{\runJuliaChunk}{O{} m m O{} O{} O{vbox}}{}
\NewDocumentCommand{\runMatLab}{O{} m m O{}}{}
\NewDocumentCommand{\runMatLabIncOut}{O{} m O{} O{} O{vbox}}{}
\NewDocumentCommand{\runMatLabChunk}{O{} m m O{} O{} O{vbox}}{}
\NewDocumentCommand{\includeOutput}{m O{vbox}}{}
\NewDocumentCommand{\inln}{m m O{} O{inline}}{}
\NewDocumentCommand{\inlnR}{O{} m O{} O{inline}}{}
\NewDocumentCommand{\inlnPython}{O{} m O{} O{inline}}{}
\NewDocumentCommand{\inlnJulia}{O{} m O{} O{inline}}{}
\NewDocumentCommand{\inlnMatLab}{O{} m O{} O{inline}}{}"""


# ── Argument parser helpers ────────────────────────────────────────────────────

def find_closing_brace(text: str, pos: int) -> int:
    """Return index of } matching { at text[pos], or -1."""
    depth = 0
    for i in range(pos, len(text)):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                return i
    return -1


def read_optional_arg(text: str, pos: int) -> tuple:
    """Consume [arg] at text[pos:] (skipping whitespace). Returns (content, new_pos)."""
    p = pos
    while p < len(text) and text[p] in " \t\n":
        p += 1
    if p >= len(text) or text[p] != "[":
        return None, pos
    end = text.find("]", p + 1)
    if end == -1:
        return None, pos
    return text[p + 1:end], end + 1


def read_mandatory_arg(text: str, pos: int) -> tuple:
    """Consume {arg} at text[pos:] (skipping whitespace). Returns (content, new_pos)."""
    p = pos
    while p < len(text) and text[p] in " \t\n":
        p += 1
    if p >= len(text) or text[p] != "{":
        return None, pos
    end = find_closing_brace(text, p)
    if end == -1:
        return None, pos
    return text[p + 1:end], end + 1


def read_args(text: str, pos: int, sig: str) -> tuple:
    """
    Parse args per signature: 'm' = mandatory {}, 'O' = optional [].
    Returns (args_list, new_pos). On mandatory failure returns ([], original_pos).
    """
    args = []
    p = pos
    for spec in sig:
        if spec == "m":
            val, new_p = read_mandatory_arg(text, p)
            if val is None:
                return [], pos
            args.append(val)
            p = new_p
        else:  # 'O'
            val, new_p = read_optional_arg(text, p)
            args.append(val)
            if val is not None:
                p = new_p
    return args, p


# ── Command catalog ────────────────────────────────────────────────────────────
#
# Each entry: (commands, signature, handler, label_index)
#
# handler:
#   "drop"   — remove the entire command (run-only, no display)
#   "inline" — replace with cached content; label at label_index in args list
#
# Longer command names must appear before shorter prefixes of themselves in the
# list so that the prefix-check guard (rest.isalpha()) works correctly.

CATALOG = [
    # IncOut: run + display — replace with cached output
    # \runRIncOut[cmd]{src}[displayopts][label][type]  sig: O m O O O
    # label_idx=3; None → auto-numbered (left as-is)
    ({"\\runRIncOut", "\\runPythonIncOut", "\\runJuliaIncOut", "\\runMatLabIncOut"},
     "OmOOO", "inline", 3),

    # Chunk: run chunk + display — replace with cached output
    # \runRChunk[cmd]{src}{chunk}[displayopts][label][type]  sig: O m m O O O
    # handler="chunk": label derived as src-chunk when args[4] is absent
    ({"\\runRChunk", "\\runPythonChunk", "\\runJuliaChunk", "\\runMatLabChunk"},
     "OmmOOO", "chunk", 4),

    # runCodeIncOut: {cmd}{src}[displayopts][label][type]  sig: m m O O O
    ({"\\runCodeIncOut"},
     "mmOOO", "inline", 3),

    # includeOutput: {label}[type]  sig: m O
    ({"\\includeOutput"},
     "mO", "inline", 0),

    # inln (base): {cmd}{code}[label][type]  sig: m m O O
    ({"\\inln"},
     "mmOO", "inline", 2),

    # inlnLANG: [cmd]{code}[label][type]  sig: O m O O
    ({"\\inlnR", "\\inlnPython", "\\inlnJulia", "\\inlnMatLab"},
     "OmOO", "inline", 2),

    # Run-only: just drop (output shown separately via \includeOutput)
    # \runR[cmd]{src}{label}[opts]  sig: O m m O
    ({"\\runR", "\\runPython", "\\runJulia", "\\runMatLab", "\\runExtCode"},
     "OmmO", "drop", -1),
]


# ── Cache reader ───────────────────────────────────────────────────────────────

def read_cached(generated_dir: Path, label: str) -> str | None:
    """Return content of generated/label.tex, or None if missing, '' if empty."""
    path = generated_dir / (label + ".tex")
    if not path.exists():
        return None
    if path.stat().st_size <= 1:
        return ""
    return path.read_text(encoding="utf-8", errors="replace")


def wrap_vbox(content: str) -> str:
    return (
        "\\begin{tcolorbox}\n"
        "\\begin{verbatim}\n"
        + content.rstrip("\n")
        + "\n\\end{verbatim}\n"
        "\\end{tcolorbox}"
    )


def render_cached(generated_dir: Path, label: str, display_type: str | None, original: str) -> str:
    """Return the replacement string for a command with the given label."""
    cached = read_cached(generated_dir, label)
    if cached is None:
        return original          # no cache: keep original command
    if not cached.strip():
        return ""
    dtype = (display_type or "vbox").strip()
    if dtype.startswith("vbox"):
        return wrap_vbox(cached)
    if dtype == "tex":
        return cached
    return cached.strip()        # inline


# ── Single-command transformer ─────────────────────────────────────────────────

def try_replace(text: str, i: int, generated_dir: Path) -> tuple:
    """
    Try to match and replace a runcode command starting at text[i].
    Returns (replacement, new_i) or (None, i) on no match.
    """
    if text[i] != "\\":
        return None, i

    for cmd_set, sig, handler, label_idx in CATALOG:
        for cmd in cmd_set:
            clen = len(cmd)
            if text[i:i + clen] != cmd:
                continue
            # Ensure we matched the full command name (not a prefix of a longer one)
            nxt = text[i + clen: i + clen + 1]
            if nxt and (nxt.isalpha() or nxt == "@"):
                continue

            args, new_i = read_args(text, i + clen, sig)
            if not args and sig:
                continue          # parse failed; try next command

            original = text[i:new_i]

            if handler == "drop":
                return "", new_i

            if handler == "chunk":
                # Label is explicit (args[4]) or derived as src-chunk (args[1]-args[2])
                label = (args[4] if len(args) > 4 and args[4] else None) or \
                        f"{args[1]}-{args[2]}"
                dtype = args[5] if len(args) > 5 else None
                return render_cached(generated_dir, label, dtype, original), new_i

            # handler == "inline"
            label = args[label_idx] if label_idx < len(args) else None
            if not label:
                return None, i    # auto-numbered: leave as-is

            # display type is the arg after the label, if present
            dtype_idx = label_idx + 1
            dtype = args[dtype_idx] if dtype_idx < len(args) else None

            return render_cached(generated_dir, label, dtype, original), new_i

    return None, i


# ── File transformer ───────────────────────────────────────────────────────────

def transform_tex(text: str, generated_dir: Path) -> str:
    """Replace runcode commands in text with cached content."""
    result: list[str] = []
    i = 0
    n = len(text)

    while i < n:
        ch = text[i]

        # Copy % comments verbatim (don't substitute inside them)
        if ch == "%" and (i == 0 or text[i - 1] != "\\"):
            eol = text.find("\n", i)
            if eol == -1:
                result.append(text[i:])
                break
            result.append(text[i:eol + 1])
            i = eol + 1
            continue

        if ch != "\\":
            result.append(ch)
            i += 1
            continue

        repl, new_i = try_replace(text, i, generated_dir)
        if repl is not None:
            result.append(repl)
            i = new_i
            continue

        result.append(ch)
        i += 1

    return "".join(result)


_USEPACKAGE_RE = re.compile(r"\\usepackage(\[[^\]]*\])?\{[^}]*runcode\}")

def patch_usepackage(text: str) -> str:
    """Replace \\usepackage[...]{...runcode} with the shim, skipping comment lines."""
    lines = text.split("\n")
    for idx, line in enumerate(lines):
        if line.lstrip().startswith("%"):
            continue
        lines[idx] = _USEPACKAGE_RE.sub(lambda _: RUNCODE_SHIM, line)
    return "\n".join(lines)


# ── Project copy ───────────────────────────────────────────────────────────────

def excluded(path: Path, project_dir: Path, out_name: str, extra: list) -> bool:
    rel = path.relative_to(project_dir)
    if rel.parts and rel.parts[0] in {out_name, ".git"}:
        return True
    name = path.name
    for pat in list(DEFAULT_EXCLUDES) + extra:
        if fnmatch(name, pat):
            return True
    return False


def copy_project(project_dir: Path, out_dir: Path, extra_excludes: list) -> None:
    if out_dir.exists():
        shutil.rmtree(out_dir)
    out_dir.mkdir()
    for src in sorted(project_dir.rglob("*")):
        if excluded(src, project_dir, out_dir.name, extra_excludes):
            continue
        dst = out_dir / src.relative_to(project_dir)
        if src.is_dir():
            dst.mkdir(parents=True, exist_ok=True)
        else:
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)


# ── Tex-file transformer ───────────────────────────────────────────────────────

def transform_all_tex(out_dir: Path, generated_dir: Path) -> None:
    for tex_file in sorted(out_dir.rglob("*.tex")):
        original = tex_file.read_text(encoding="utf-8", errors="replace")
        text = patch_usepackage(original)
        text = transform_tex(text, generated_dir)
        if text != original:
            tex_file.write_text(text, encoding="utf-8")
            print(f"  transformed: {tex_file.relative_to(out_dir)}")
        else:
            print(f"  unchanged:   {tex_file.relative_to(out_dir)}")


# ── Compilation ────────────────────────────────────────────────────────────────

def compile_pdf(out_dir: Path, main: str, engine: str) -> bool:
    for pass_n in range(1, 3):
        cmd = [engine, "-shell-escape", "-interaction=nonstopmode", f"{main}.tex"]
        print(f"  pass {pass_n}: {' '.join(cmd)}")
        subprocess.run(cmd, cwd=out_dir)
        pdf = out_dir / f"{main}.pdf"
        if not (pdf.exists() and pdf.stat().st_size > 0):
            log = out_dir / f"{main}.log"
            print(f"  ERROR: no PDF after pass {pass_n}")
            if log.exists():
                lines = log.read_text(errors="replace").splitlines()
                print("\n".join(lines[-50:]))
            return False
    pdf = out_dir / f"{main}.pdf"
    print(f"  OK — {pdf} ({pdf.stat().st_size // 1024} KB)")
    return True


# ── Main ───────────────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("main", metavar="MAIN.tex")
    parser.add_argument("--out", default="standalone", metavar="DIR")
    parser.add_argument("--engine", default="pdflatex", metavar="CMD")
    parser.add_argument("--no-compile", action="store_true")
    parser.add_argument("--exclude", action="append", default=[], metavar="GLOB")
    args = parser.parse_args()

    main_tex = Path(args.main).resolve()
    if not main_tex.exists():
        sys.exit(f"ERROR: {args.main} not found")

    project_dir = main_tex.parent
    out_dir = (project_dir / args.out).resolve()
    generated_dir = project_dir / "generated"

    if not generated_dir.exists():
        sys.exit("ERROR: generated/ not found — run a full build first")

    print(f"── Step 1: copy project → {out_dir.name}/ ─────────────────────────────────")
    copy_project(project_dir, out_dir, args.exclude)

    print(f"\n── Step 2: inline cached outputs ──────────────────────────────────────────")
    transform_all_tex(out_dir, generated_dir)

    if not args.no_compile:
        print(f"\n── Step 3: compile {main_tex.stem}.tex ─────────────────────────────────────")
        if not compile_pdf(out_dir, main_tex.stem, args.engine):
            sys.exit("Compilation failed.")

    print(f"\nDone. Standalone project in: {out_dir}/")
    print("Review any auto-numbered \\inln*/\\includeOutput commands manually.")


if __name__ == "__main__":
    main()
