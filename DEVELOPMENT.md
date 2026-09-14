# Development Setup

This document describes how to set up the development environment for working with the Verse documentation.

## Prerequisites

- Python 3.8 or higher
- Node.js (for bin scripts)
- Access to fortniteMain repository

## Verse VM Locations

The scripts in `bin/` require the Verse VMs from the fortniteMain repository. As
of the UE6 reorganization, both VMs live in `Engine/Binaries/Win64/`.

The scripts resolve each VM in this order: an explicit environment override, the
`$PATH`, then `$VERSE_BIN`. `$VERSE_BIN` defaults to whichever spelling of the
path the current shell can see:

```
WSL                    /mnt/d/fortniteMain/Engine/Binaries/Win64
Git Bash / cmd / pwsh  D:/fortniteMain/Engine/Binaries/Win64
```

Set `VERSE_BIN` if your checkout lives elsewhere, rather than editing the
scripts. Either spelling works from Git Bash; use the `/mnt/d` form under WSL:

```bash
export VERSE_BIN=/mnt/d/fortniteMain/Engine/Binaries/Win64   # WSL
export VERSE_BIN=D:/fortniteMain/Engine/Binaries/Win64       # Git Bash
```

`bin/vtest` runs from WSL, Git Bash, cmd and PowerShell. The VMs are Windows
executables that need a native Windows path, so the script converts whatever it
is given with `wslpath` under WSL and `cygpath` under Git Bash.

### TestScript VM (for `.versetest` files)

```
$VERSE_BIN/VerseTestScriptCmdVM.exe
```

Override with `$VERSE_TESTSCRIPT_VM`.

**Source Project**: `Engine/Source/Programs/VerseTestScriptCmd`

**Build** (from WSL):

```bash
cmd.exe /c Engine\\Build\\BatchFiles\\Build.bat VerseTestScriptCmdVM Win64 Development
```

Note that a Development build produces the unsuffixed `VerseTestScriptCmdVM.exe`,
while other configurations add a `-Win64-<Config>` suffix. The scripts accept
either name.

### CLR VM (for `.verse` files)

```
$VERSE_BIN/VerseCLRVM.exe
```

Override with `$VERSE_CLR_VM`. **Source Project**:
`Engine/Source/Programs/VerseCLR`.

`bin/vtest` reaches for this VM only when handed a `.verse` file. The book has
none — `bin/extract` emits `.versetest` exclusively — so in practice the CLR VM
is never invoked, is not built by default, and you do not need it to run the
tests.

## Refreshing `Tests/`

`Tests/` is a verbatim copy of the compiler's own test suite. The compiler
maintainers update those tests in lockstep with compiler changes, so a failure in
`Tests/` almost always means the copy is stale rather than that something is
broken. Refresh it wholesale:

```bash
rm -rf Tests && mkdir Tests
cp -r /mnt/d/fortniteMain/Engine/Source/Programs/VerseTestScriptCmd/Tests/. Tests/
bin/vtest Tests --verbose
```

Expect 0 failures after a refresh. Note this is a different directory from the
one named in `fortniteMain/JanInfo/README.md`, which is out of date.

## Available Scripts

### Testing

- `bin/vtest <file-or-directory>` - Run Verse tests
  - `--verbose` - Show detailed error messages
  - `--raw` - Show complete VM output

### Code Extraction

- `bin/extract <markdown-file> -t <target-directory>` - Extract Verse snippets from markdown
- `bin/extract_all` - Extract all snippets from all docs

### Runtime API Summaries

- `bin/verse_api` - Summarise the Verse runtime's intrinsic and native functions
  from the fortniteMain checkout into Markdown or a browsable HTML page

See "Summarising the runtime API" below.

## Summarising the runtime API

Two parts of the Verse runtime are not written in Verse and have no
hand-written chapter in this book:

- **Intrinsics** are synthesised by the compiler. No `.verse` file declares
  them; they are built in `PopulateCoreAPI()` in
  `Engine/Source/Runtime/VerseCompiler/Private/uLang/Semantics/SemanticProgram.cpp`
  and tagged with the private `intrinsic` attribute. This is where the
  operators, container indexing, `Abs`, `Ceil`, `weak_map` and friends live.
- **Natives** are declared in `*.native.verse` files with the `<native>`
  specifier and implemented in C++ behind a VNI-generated binding.
  `<native_callable>` is the mirror image: a Verse body that C++ can call.

`bin/verse_api` reads both out of the engine tree — reconstructing intrinsic
signatures from the compiler source and parsing the `.native.verse`
declarations together with their `@doc` comments — and writes a Markdown
summary. The output is meant to be reviewed and then folded into the book by
hand, so it lands in `build/` (gitignored) rather than in `docs/`:

```bash
bin/verse_api                       # build/verse_runtime_api.md
bin/verse_api --format html         # build/verse_runtime_api.html
```

The Markdown is the form to fold into `docs/`; it uses only extensions already
enabled in `mkdocs.yml` (`admonition`, `def_list`, `tables`).

The HTML is a single self-contained file for reading in a browser — no network,
no npm, no build step. It gives you:

- **Syntax-coloured signatures.** Verse declarations are lexed when the file is
  generated, using the token colours from the book's own TextMate themes in
  `docs/Assets/VerseLight.json` and `VerseDark.json`, so a signature here is
  coloured the way the book colours one.
- **A live filter.** Type in the sidebar box, or press <kbd>/</kbd>, to narrow
  to matching declarations; sections that end up empty hide themselves, in the
  page and in the sidebar. <kbd>Esc</kbd> clears it.
- **Light and dark themes.** Follows the system setting, with a toggle that
  remembers your choice in `localStorage`.
- **Badges** for the things that would otherwise be prose: how a declaration is
  implemented, its access level, `@experimental`, and the Fortnite version it
  became available in.
- A sticky sidebar of contents that tracks the section you are reading, and
  permalinks on every heading.

### Overriding weak doc comments

Some `@doc` comments in the engine are thin, or just restate the name of the
function. `verse_api_overrides.md` in the repository root replaces them without
touching the engine tree: a `##` heading naming a declaration, followed by the
prose to use instead. Anything else in the file, including HTML comments, is
ignored, and a section left empty keeps whatever the engine says.

The loop is:

```bash
bin/verse_api --stubs        # create or top up verse_api_overrides.md
$EDITOR verse_api_overrides.md
bin/verse_api --format html  # regenerate and read the result
```

`--stubs` writes one heading per declaration in the output, with the engine's
current text kept beside it in an `<!-- engine text: -->` comment. It never
edits or removes a section that is already there, so it is safe to re-run after
the engine grows a new function: it only appends the new ones. Pass the same
`--module`/`--access` flags you generate with, if you have widened the scope.

That recorded comment is not just for reference while you write. Every run
compares it against what the engine says now, and reports any override whose
engine text has changed underneath it:

```
Warning: the engine text changed under 2 override(s). Re-read them and update
the "engine text" comment to acknowledge:
  Sqrt
  event.Signal
```

An override is written to answer a question the engine's own comment left open.
When that comment changes, the override may now be redundant, or contradict it.
Re-read both, then update the `<!-- engine text: -->` block to the new wording
to silence the warning — which is a deliberate, manual acknowledgement rather
than something a regeneration does behind your back. `--verbose` prints the old
and new text side by side.

A heading names one declaration, with only as much detail as it takes to be
unambiguous:

```
## Sqrt                                  by name
## ToString(char)                        by name and parameter types
## ToString(Character:char)              parameters copied from the signature
## event.Await                           a member, by qualified name
## String:ToString(char)                 narrowed to one file
## /Verse.org/Verse:Sqrt                 narrowed to one module
```

`--stubs` already picks the shortest form that is unambiguous, so in practice
you do not write these by hand. A heading that matches nothing, or more than
one declaration, is reported on every run rather than quietly ignored — that is
what catches an override going stale when the engine renames or re-signatures
something. Use `--no-overrides` to see the engine's own text again, or
`--overrides <file>` to keep a different set.

### Other options

It finds the engine through `--engine`, then `$FORTNITE_MAIN`, then
`../fortniteMain`. By default it scans `Engine/Plugins`, which is everything
Verse ships as a plugin, and covers every module it finds there: the core
`/Verse.org/Verse`, plus `SceneGraph`, `Simulation`, `SpatialMath`, `Random`,
`Assets` and the rest. Test-suite modules are skipped: they are Verse modules
like any other, but they document a test harness rather than the runtime. Only
declarations that are part of the native runtime surface are included, at
`<public>` access. Useful variations:

```bash
bin/verse_api --module /Verse.org/Verse      # one module instead of all of them
bin/verse_api --access all                   # include internal and epic_internal
bin/verse_api --include-verse                # index the Verse-implemented API too
bin/verse_api --include-tests                # include test-suite modules
bin/verse_api --no-overrides                 # show the engine's own doc comments
bin/verse_api --json build/api.json          # machine-readable model
bin/verse_api --verbose                      # list anything that did not parse
```

`--verbose` matters when the engine moves on: the extractor is a parser, not a
compiler, so a restructured intrinsic table or an unfamiliar declaration shape
shows up as a warning rather than as silently missing output. A clean run
reports no warnings.
