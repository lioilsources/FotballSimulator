// Všechny jazyky mají všechny texty a placeholdery se dosadí.
import 'package:flutter_test/flutter_test.dart';
import 'package:fotball_simulator/l10n/app_localizations.dart';

void main() {
  test('45 jazyků, angličtina jako výchozí', () {
    expect(AppLocalizations.supportedLocales.length, 45);
    expect(AppLocalizations.supportedLocales.first.languageCode, 'en');
  });

  for (final locale in AppLocalizations.supportedLocales) {
    test('texty pro $locale', () {
      final l = lookupAppLocalizations(locale);
      for (final s in [
        l.resultGoal,
        l.resultMiss,
        l.resultLate,
        l.resultShort,
        l.ratingPerfect,
        l.ratingGood,
        l.ratingEarly,
        l.ratingLate,
        l.slowMoOn,
        l.slowMoOff,
      ]) {
        expect(s.trim(), isNotEmpty);
      }
      expect(l.kickAir('+35'), contains('+35'));
      final stats = l.kickStats(92, '8,4', 'X', '-12');
      expect(stats, allOf(contains('92'), contains('8,4'), contains('-12')));
      expect(stats, isNot(contains('{')));
    });
  }
}
