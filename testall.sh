#!/bin/bash
# Run the snippet tests for every chapter extracted from docs/ by bin/extract_all.
# Per-chapter output lands in ERR_<chapter> (e.g. ERR_08_failure).

set -u

if [ ! -d verse ]; then
  echo "No verse/ directory. Run bin/extract_all first." >&2
  exit 1
fi

status=0

for dir in verse/*/; do
  chapter=$(basename "$dir")
  printf '%-24s ' "$chapter"

  if ! bin/vtest "$dir" --verbose > "ERR_$chapter" 2>&1; then
    status=1
  fi

  # Echo the summary counts so the console shows progress at a glance.
  grep -E '^(Total|Successes|Failures):' "ERR_$chapter" | tr -s ' \n' ' '
  echo
done

echo
echo "Per-chapter details in ERR_* files."
exit $status
