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
	out=$("$GODOT" --headless --path . --script "res://$t" 2>&1)
	code=$?
	echo "$out" | grep -v -E '^Godot Engine|^$'
	# Godot vrací 0 i když skript nejde naparsovat → vyžadovat i závěrečný
	# řádek testu, ne jen exit code
	if [ $code -ne 0 ] || ! echo "$out" | grep -q '=== ALL TESTS PASSED ==='; then
		echo "✘ $t selhal (exit $code)"
		fail=1
	fi
done
[ $fail -eq 0 ] && echo "✔ všechny testy prošly" || echo "✘ některý test selhal"
exit $fail
