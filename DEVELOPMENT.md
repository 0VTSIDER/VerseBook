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
`$PATH`, then `$VERSE_BIN`. `$VERSE_BIN` defaults to:

```
/mnt/d/fortniteMain/Engine/Binaries/Win64
```

Set `VERSE_BIN` if your checkout lives elsewhere, rather than editing the
scripts:

```bash
export VERSE_BIN=/mnt/d/fortniteMain/Engine/Binaries/Win64
```

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

This VM is only used by `bin/vtest` for `.verse` files and by `bin/compile`. The
book's test suite is entirely `.versetest`, so the CLR VM is not needed to run
the tests, and it is not built by default.

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

### Compilation

- `bin/compile <directory>` - Compile all .verse files in a directory
