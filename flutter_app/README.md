# fotball_simulator

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Lokalizace a store texty

- UI texty jsou v `lib/l10n/app_<jazyk>.arb` (gen-l10n, `l10n.yaml`). Šablona a zdroj je
  `app_cs.arb` (jen ona má `@`-metadata), výchozí jazyk pro neznámé locale je angličtina.
  Po změně ARB: `flutter gen-l10n`, vygenerované `app_localizations*.dart` se commitují.
- Jádro hry (`lib/core/`) vrací jen `ShotResult` / `KickReport`, texty skládá `ui/game_screen.dart`.
- 45 jazyků; iOS je má vyjmenované v `CFBundleLocalizations` (Info.plist) a `knownRegions`.
- Store texty: `fastlane/metadata/ios/<locale>/` a `fastlane/metadata/android/<locale>/`
  (fastlane konvence). Limity hlídá `../bin/check-store-metadata.py`. Nahrání je zatím ruční,
  CI metadata neposílá.
