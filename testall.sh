#!/bin/bash
# Run the snippet tests for chapters extracted from docs/ by bin/extract_all.
# Per-chapter output lands in ERR_<chapter> (e.g. ERR_08_failure).
#
# This only ever runs verse/, the snippets extracted from docs/. The Tests/
# suite is separate and is not touched here; run it with `bin/vtest Tests`.
#
# Usage:
#   ./testall.sh                    all chapters (~900 snippets, several minutes)
#   ./testall.sh 10 12              only chapters whose names match 10* and 12*
#   ./testall.sh 10_classes         a full chapter name works too
#
# Passing the chapters you actually edited keeps the edit/test loop short.

set -u

if [ ! -d verse ]; then
  echo "No verse/ directory. Run bin/extract_all first." >&2
  exit 1
fi

# Build the list of chapter directories to run.
dirs=()
if [ "$#" -eq 0 ]; then
  for d in verse/*/; do dirs+=("$d"); done
else
  for pat in "$@"; do
    matched=0
    for d in verse/"$pat"*/; do
      [ -d "$d" ] || continue
      dirs+=("$d"); matched=1
    done
    if [ "$matched" -eq 0 ]; then
      echo "No chapter matches '$pat'" >&2
      exit 1
    fi
  done
fi

status=0
total=0
fails=0

for dir in "${dirs[@]}"; do
  chapter=$(basename "$dir")
  printf '%-24s ' "$chapter"

  if ! bin/vtest "$dir" --verbose > "ERR_$chapter" 2>&1; then
    status=1
  fi

  # Echo the summary counts so the console shows progress at a glance.
  grep -E '^(Total|Successes|Failures):' "ERR_$chapter" | tr -s ' \n' ' '
  echo

  t=$(grep -E '^Total:' "ERR_$chapter" | grep -oE '[0-9]+' | head -1)
  f=$(grep -E '^Failures:' "ERR_$chapter" | grep -oE '[0-9]+' | head -1)
  total=$((total + ${t:-0}))
  fails=$((fails + ${f:-0}))
done

echo
echo "$total snippet(s), $fails failure(s) across ${#dirs[@]} chapter(s)."
echo "Per-chapter details in ERR_* files."
exit $status
