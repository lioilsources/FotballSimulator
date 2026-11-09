// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get resultGoal => 'GOAL!';

  @override
  String get resultMiss => 'MISS';

  @override
  String get resultLate => 'TOO LATE';

  @override
  String get resultShort => 'FELL SHORT';

  @override
  String kickAir(String ms) {
    return 'AIR KICK! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/h · $spin rev/s · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'PERFECT';

  @override
  String get ratingGood => 'GOOD';

  @override
  String get ratingEarly => 'EARLY';

  @override
  String get ratingLate => 'LATE';

  @override
  String get slowMoOn => 'SLOW-MO ON';

  @override
  String get slowMoOff => 'SLOW-MO OFF';
}
