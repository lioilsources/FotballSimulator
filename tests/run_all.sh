#!/usr/bin/env bash
# Spustí všechny headless testy. Cesta k Godotu z $GODOT (default = macOS
# instalace z CLAUDE.md). Exit code 1, pokud cokoliv selže.
set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT:-/Volumes/YOTTA/Applications/Godot_mono.app/Contents/MacOS/Godot}"

"$GODOT" --headless --path . --import >/dev/null 2>&1

fail=0
for t in tests/*_test.gd; do
	echo "▶ $t"
	if ! "$GODOT" --headless --path . --script "res://$t" 2>&1 | grep -v -E '^Godot Engine|^$'; then
		:
	fi
	if [ "${PIPESTATUS[0]}" -ne 0 ]; then
		fail=1
	fi
done
[ $fail -eq 0 ] && echo "✔ všechny testy prošly" || echo "✘ některý test selhal"
exit $fail
