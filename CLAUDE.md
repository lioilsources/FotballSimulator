# FotballSimulator

## Účel
Simulátor kopání do míče (volej) v Godot 4.7 (Mobile renderer, GDScript),
cíl Android + iOS, plus paralelní Flutter port v `flutter_app/`. Jádro hry je
contact model — kde a kdy nárt potká míč; vše ostatní z toho plyne
deterministicky. Kompletní design: **VOLLEY_PLAN.md**.

**Stav: Fáze 1 hotová** (contact model, swipe input, timing okno s
pre-simulací ideálu, freeze-frame, HUD; hratelná smyčka serve→kick→result).
Další krok: Fáze 2 — verlet síť, flight kamera, heatmapa, tuning pass
(VOLLEY_PLAN.md §7). Audit, známé chyby a plán: **ROADMAP.md** (začít V0/T0).

## Build a test
Cesta k Godotu je v `$GODOT` (viz `.env.example`).

```bash
"$GODOT" --editor --path .          # editor
"$GODOT" --path .                   # spustit hru

# gate před pushem: všechny headless testy (import + tests/*_test.gd, exit 0/1)
GODOT="$GODOT" tests/run_all.sh

# jednotlivě
"$GODOT" --headless --path . --script res://tests/physics_test.gd   # let, odskok, determinismus
"$GODOT" --headless --path . --script res://tests/contact_test.gd   # tabulkové případy kontaktu
"$GODOT" --headless --path . --script res://tests/swipe_test.gd     # geometrie gesta
"$GODOT" --headless --path . --script res://tests/gameplay_test.gd  # end-to-end serve→kop→gól

# po přidání nového class_name souboru před headless během přegenerovat cache
"$GODOT" --headless --path . --import

cd flutter_app && flutter test      # Flutter port
```

Mobilní export (APK, Xcode projekt, adb): `docs/mobile-export.md`.

## Mapa
- `scripts/core/` — fyzika, contact model, serve, game state, brána
- `scripts/input/` — swipe gesto; `scripts/ui/` — freeze-frame, statistiky
- `scripts/util/tuning.gd` — jediný zdroj konstant (autoload `Tuning`)
- `scenes/` — Godot scény (`assets/`, `scripts/net/` zatím prázdné)
- `tests/` — headless SceneTree testy + `run_all.sh`
- `flutter_app/` — Flutter port (`.gdignore`), viz `docs/flutter-port.md`
- `.github/workflows/` — CI a release, generované z Distribution

## Invarianty
- Všechny konstanty v `scripts/util/tuning.gd`; core skripty ho preloadují
  jako `const T` (headless bez autoloadů). Flutter `lib/core/tuning.dart`
  držet synchronní.
- Fyzika letu je vlastní integrace (semi-implicit Euler, 120 Hz) —
  RigidBody3D nemá Magnus, nepoužívat.
- Souřadnice: hráč na origin, kope směrem **-z**.
- Workflowy v `.github/workflows/` needitovat ručně — opravy patří do
  Distribution a pak re-align (`docs/flutter-port.md`).
- Lokálně `flutter build ios --release` selže (CI profil), používat `--profile`.

Detaily (brána, contact model, timing, swipe, testy): `docs/architecture.md`.

## Odchylky
- Odchylka od lang.md: komentáře česky (identifikátory anglicky, handoff
  z VOLLEY_PLAN.md).

## Kam dál
- `VOLLEY_PLAN.md` — design a fáze
- `ROADMAP.md` — audit, chyby, plán
- `docs/architecture.md`, `docs/mobile-export.md`, `docs/flutter-port.md`
