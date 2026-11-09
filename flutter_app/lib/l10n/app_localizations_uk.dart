// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get resultGoal => 'ГОЛ!';

  @override
  String get resultMiss => 'ПОВЗ';

  @override
  String get resultLate => 'ЗАПІЗНО';

  @override
  String get resultShort => 'НЕДОЛІТ';

  @override
  String kickAir(String ms) {
    return 'ПОВЗ М\'ЯЧ! ($ms мс)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed км/год · $spin об/с · $rating ($ms мс)';
  }

  @override
  String get ratingPerfect => 'ІДЕАЛЬНО';

  @override
  String get ratingGood => 'ДОБРЕ';

  @override
  String get ratingEarly => 'РАНО';

  @override
  String get ratingLate => 'ПІЗНО';

  @override
  String get slowMoOn => 'УПОВІЛЬНЕННЯ УВІМК.';

  @override
  String get slowMoOff => 'УПОВІЛЬНЕННЯ ВИМК.';
}
