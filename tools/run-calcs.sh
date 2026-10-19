#!/usr/bin/env bash
# Run every numbered calculation script in global order, dispatching by extension.
#   tools/run-calcs.sh            # all scripts
#   tools/run-calcs.sh 03         # only scripts whose name starts with 03
#   LANGS="py" tools/run-calcs.sh # only Python (e.g. on a machine without Mathematica)
set -euo pipefail
cd "$(dirname "$0")/.."

filter="${1:-}"
langs="${LANGS:-wl py jl sh}"

scripts=$(find calc/*/scripts -maxdepth 1 -type f -name "[0-9]*" -name "${filter}*" 2>/dev/null \
	| awk -F/ '{print $NF"\t"$0}' | sort | cut -f2 || true)

if [ -z "$scripts" ]; then
	# A fresh project has no calculations yet: not an error, unless a filter was asked for.
	[ -n "$filter" ] && { echo "no scripts match '${filter}'"; exit 1; }
	echo "no calculation scripts yet (add one with /new-calc)"
fi

for f in $scripts; do
	ext="${f##*.}"
	[[ " $langs " == *" $ext "* ]] || continue
	echo "==> $f"
	case "$ext" in
		wl) wolframscript -file "$f" ;;
		py) uv run python "$f" ;;
		jl) julia --project=calc/julia "$f" ;;
		sh) bash "$f" ;;
	esac
done

uv run python -m hepcalc.results
