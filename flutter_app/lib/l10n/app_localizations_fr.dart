// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get resultGoal => 'BUT !';

  @override
  String get resultMiss => 'RATÉ';

  @override
  String get resultLate => 'TROP TARD';

  @override
  String get resultShort => 'TROP COURT';

  @override
  String kickAir(String ms) {
    return 'DANS LE VIDE ! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/h · $spin tr/s · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'PARFAIT';

  @override
  String get ratingGood => 'BIEN';

  @override
  String get ratingEarly => 'TÔT';

  @override
  String get ratingLate => 'TARD';

  @override
  String get slowMoOn => 'RALENTI : OUI';

  @override
  String get slowMoOff => 'RALENTI : NON';
}
