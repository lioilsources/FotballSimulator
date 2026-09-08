# CLAUDE.md

## Project Overview

FotballSimulator — simulátor kopání do míče (volej) v Godot 4.7 (Mobile
renderer, GDScript), cíl Android + iOS. Kompletní design: **VOLLEY_PLAN.md**
(architektura, fyzikální model, fáze implementace). Jádro hry je contact
model — kde a kdy nárt potká míč; vše ostatní z toho plyne deterministicky.

**Stav: Fáze 1 hotová** (contact model, swipe input, timing okno s
pre-simulací ideálu, freeze-frame, HUD; hratelná smyčka serve→kick→result).
Další krok: Fáze 2 — verlet síť, flight kamera, heatmapa, tuning pass
(viz VOLLEY_PLAN.md §7). Audit stavu, známé chyby a plán testování +
vylepšení: **ROADMAP.md** (začít sekcí V0/T0).

## Commands

```bash
GODOT="/Volumes/YOTTA/Applications/Godot_mono.app/Contents/MacOS/Godot"

# otevřít v editoru
"$GODOT" --editor --path .

# spustit hru
"$GODOT" --path .

# headless testy (exit code 0/1)
"$GODOT" --headless --path . --script res://tests/physics_test.gd   # let, odskok, determinismus
"$GODOT" --headless --path . --script res://tests/contact_test.gd   # tabulkové případy kontaktu
"$GODOT" --headless --path . --script res://tests/gameplay_test.gd  # end-to-end serve→kop→gól

# po přidání nového class_name souboru před headless během přegenerovat cache:
"$GODOT" --headless --path . --import

# Android debug APK (export_presets.cfg → preset "Android")
"$GODOT" --headless --path . --export-debug "Android" build/FotballSimulator.apk

# instalace na připojený telefon (USB debugging)
~/Library/Android/sdk/platform-tools/adb install -r build/FotballSimulator.apk
~/Library/Android/sdk/platform-tools/adb shell am start -n com.ol1n.fotballsimulator/com.godot.game.GodotApp

# iOS: vygenerovat Xcode projekt + build pro zařízení
"$GODOT" --headless --path . --export-debug "iOS" build/ios/FotballSimulator.xcodeproj
cd build/ios && xcodebuild -project FotballSimulator.xcodeproj -scheme FotballSimulator \
    -configuration Debug -destination "generic/platform=iOS" -allowProvisioningUpdates build
```

## Mobilní export

Export templates 4.7.1.stable.mono jsou nainstalované v
`~/Library/Application Support/Godot/export_templates/4.7.1.stable.mono/`
(mono edice editoru vyžaduje mono templates — jiný balík než standard).
Editor settings mají vyplněné Android SDK (`~/Library/Android/sdk`), JDK 21
a debug keystore (`~/.android/debug.keystore`, dědictví Flutteru).

Android preset je bez gradle buildu (rychlá cesta přes předpřipravený
template APK), arm64-v8a, package `com.ol1n.fotballsimulator`, immersive
mode. Gradle build bude potřeba až pro AAB do Play Store (Fáze 3).

iOS preset generuje **Xcode projekt** (`export_project_only=true`), ne rovnou
.ipa — podpis a nahrání na zařízení řeší Xcode, stejný workflow jako
u Flutter projektů. Bundle id `com.ol1n.fotballsimulator`, tým P82HWPG7FN,
min iOS 14, portrait, launch storyboard. Build ověřen přes `xcodebuild`
(BUILD SUCCEEDED, podepsáno Apple Development).

Pozn.: iOS export vypisuje na konci `ERROR: EditorSettings not instantiated
yet ... shutdown_adb_on_exit` — benigní hláška při headless ukončení
editoru, nemá vliv na výsledek.

Ovládání: swipe na overlay míči dole (touch-down = kontaktní bod, oblouk =
faleš, rychlost = síla, puštění = timing). Klávesa `A` přepíná assist
slow-mo. Debug kopy: `1` přímý, `2` faleš (sidespin), `3` topspin.

## Konvence

- Komentáře česky, identifikátory anglicky (handoff z VOLLEY_PLAN.md).
- **Všechny konstanty v `scripts/util/tuning.gd`** — žádná magic numbers
  jinde. Je to autoload `Tuning`; čistě fyzikální skripty (`ball_physics.gd`,
  `serve_generator.gd`, budoucí `contact_model.gd`) ho ale **preloadují jako
  `const T`**, aby fungovaly headless bez autoloadů a bez závislostí na scéně.
- Fyzika letu je vlastní integrace (semi-implicit Euler, 120 Hz physics tick
  v project.godot) — Godot RigidBody3D nemá Magnus, nepoužívat.
- Geometrie brány: scéna `pitch.tscn` má bránu na origin, `game_state.gd` ji
  při startu posouvá na `-Tuning.GOAL_DISTANCE` — zdroj pravdy je tuning.
- Souřadnice: hráč na origin, kope směrem **-z**; topspin pro let -z = spin
  kolem **-x**, sidespin kolem **y**.
- Contact model (`contact_model.gd`): čistá statická funkce v lokálním rámci
  kopu (-z na bránu), převod do světa dělá `game_state`. Osa spinu = `u × t`
  (odvozeno z τ = r × F, ne tvar `swing×d` z plánu — měl obrácenou
  orientaci). Late shift posouvá kontakt **nahoru** (`+=`, překlep v plánu).
- Timing: `game_state` si při serve **pre-simuluje** trajektorii scratch
  instancí `BallPhysics` a najde ideální okamžik (klesání skrz
  `IDEAL_KICK_HEIGHT` po prvním odskoku); `timing_error` = čas puštění swipu
  minus ideál, měřeno v herním čase (nezávislé na assist slow-mo).
- Testy: čisté SceneTree skripty (bez GUT), referenční hodnoty fyziky
  z nezávislé Python implementace stejného modelu (hodnoty v hlavičce
  physics_test.gd). Autoloady v `--script` režimu fungují, ale core skripty
  stejně preloadují `const T` — drží to čistotu závislostí.
