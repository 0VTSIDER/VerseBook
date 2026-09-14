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
