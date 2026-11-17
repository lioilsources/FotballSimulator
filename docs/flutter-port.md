# Flutter port (`flutter_app/`)

Přesunuto z CLAUDE.md.

Paralelní port Fáze 1 do Flutteru (čistý Dart, bez 3D enginu — scéna
přes vlastní perspektivní projekci v `CustomPainter`). `.gdignore` drží
složku mimo Godot import.

- `lib/core/` — 1:1 port `tuning`, `ball_physics`, `contact_model`,
  `serve_generator`, `game_state` (→ `game.dart`, čistý Dart bez Flutteru).
  **Konstanty držet synchronní s `scripts/util/tuning.gd`.**
- Serve RNG je vlastní PCG32 — sekvence se neshoduje s Godotem.
- Kamera: portrait má navíc minimální horizontální FOV 60° a lens shift
  (`cameraMinHFovDeg`, `cameraCenterYFrac`) — s čistě vertikálním FOV 55°
  míč v kop-zóně utíká ze záběru.
- Slow-mo assist = tlačítko vpravo nahoře; klávesy 1/2/3/A fungují
  s připojenou klávesnicí.

```bash
cd flutter_app
flutter test                       # port physics/contact/gameplay testů
flutter run --profile              # iOS na připojený telefon (Automatic signing)
flutter run --release              # Android (bez key.properties podepíše debug klíčem)
flutter build apk --release        # build/app/outputs/flutter-apk/app-release.apk
```

Bundle/applicationId `com.ol1n.fotballSimulator` (iOS i Android), tým `$APPLE_TEAM_ID`.
Pozor: Godot preset používá `com.ol1n.fotballsimulator` (malé „s“).

## Release CI (`.github/workflows/`)

Workflowy jsou z golden šablon `$DEV_ROOT/Distribution/workflows/`
nasazené skriptem `align-project.sh` (`--app-dir flutter_app --app-name
FotballSimulator`). Needitovat ručně — opravy patří do Distribution a pak
re-align.

- `ci.yml` — push na větev: analyze + test + debug buildy.
- `release-ios.yml` / `release-android.yml` — tag `v*` → TestFlight /
  GitHub Release + Firebase App Distribution. Verze se bere z tagu.
- iOS **Release** konfigurace je Manual + `"Apple Distribution"` +
  placeholder `CI_PROFILE_NAME` (CI dosadí UUID profilu) → lokální
  `flutter build ios --release` selže, lokálně používat `--profile`.
- Android release podpis čte `android/key.properties` (vytváří ho CI ze
  secrets).
