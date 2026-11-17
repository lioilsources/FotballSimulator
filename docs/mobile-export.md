# Mobilní export (Godot)

Přesunuto z CLAUDE.md. Cesta k Godotu je v `$GODOT` (viz `.env.example`).

## Příkazy

```bash
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

## Prostředí

Export templates 4.7.1.stable.mono jsou nainstalované v
`~/Library/Application Support/Godot/export_templates/4.7.1.stable.mono/`
(mono edice editoru vyžaduje mono templates — jiný balík než standard).
Editor settings mají vyplněné Android SDK (`~/Library/Android/sdk`), JDK 21
a debug keystore (`~/.android/debug.keystore`, dědictví Flutteru).

## Android

Preset je bez gradle buildu (rychlá cesta přes předpřipravený template APK),
arm64-v8a, package `com.ol1n.fotballsimulator`, immersive mode. Gradle build
bude potřeba až pro AAB do Play Store (Fáze 3).

## iOS

Preset generuje **Xcode projekt** (`export_project_only=true`), ne rovnou
.ipa — podpis a nahrání na zařízení řeší Xcode, stejný workflow jako
u Flutter projektů. Bundle id `com.ol1n.fotballsimulator`, tým `$APPLE_TEAM_ID`,
min iOS 14, portrait, launch storyboard. Build ověřen přes `xcodebuild`
(BUILD SUCCEEDED, podepsáno Apple Development).

Pozn.: iOS export vypisuje na konci `ERROR: EditorSettings not instantiated
yet ... shutdown_adb_on_exit` — benigní hláška při headless ukončení
editoru, nemá vliv na výsledek.

## Ovládání

Swipe na overlay míči dole (touch-down = kontaktní bod, oblouk = faleš,
rychlost = síla, puštění = timing). Klávesa `A` přepíná assist slow-mo.
Debug kopy: `1` přímý, `2` faleš (sidespin), `3` topspin.
