#!/usr/bin/env python3
"""Checks fastlane store metadata against App Store / Google Play length limits.

Usage: bin/check-store-metadata.py [metadata dir]  (default flutter_app/fastlane/metadata)
Exit code 1 when a field is missing, empty or too long.
"""
import pathlib
import sys

LIMITS = {
    "ios": {"name.txt": 30, "subtitle.txt": 30, "keywords.txt": 100,
            "promotional_text.txt": 170, "description.txt": 4000, "release_notes.txt": 4000},
    "android": {"title.txt": 30, "short_description.txt": 80, "full_description.txt": 4000,
                "changelogs/default.txt": 500},
}

root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else
                    pathlib.Path(__file__).resolve().parent.parent / "flutter_app/fastlane/metadata")
errors = 0
for store, fields in LIMITS.items():
    locales = sorted(p for p in (root / store).iterdir() if p.is_dir())
    for loc in locales:
        for name, limit in fields.items():
            f = loc / name
            text = f.read_text(encoding="utf-8").strip() if f.exists() else ""
            if not text or len(text) > limit:
                errors += 1
                print(f"{store}/{loc.name}/{name}: {len(text)} chars (limit {limit})")
        kw = loc / "keywords.txt"
        if kw.exists() and " " in kw.read_text(encoding="utf-8").strip():
            errors += 1
            print(f"{store}/{loc.name}/keywords.txt: contains spaces")
    print(f"{store}: {len(locales)} locales")
sys.exit(1 if errors else 0)
