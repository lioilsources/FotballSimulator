// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovak (`sk`).
class AppLocalizationsSk extends AppLocalizations {
  AppLocalizationsSk([String locale = 'sk']) : super(locale);

  @override
  String get resultGoal => 'GÓL!';

  @override
  String get resultMiss => 'VEDĽA';

  @override
  String get resultLate => 'NESKORO';

  @override
  String get resultShort => 'NEDOLETEL';

  @override
  String kickAir(String ms) {
    return 'VZDUCH! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/h · $spin ot./s · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'PERFEKTNÉ';

  @override
  String get ratingGood => 'DOBRÉ';

  @override
  String get ratingEarly => 'SKORO';

  @override
  String get ratingLate => 'NESKORO';

  @override
  String get slowMoOn => 'SPOMALENIE ZAP';

  @override
  String get slowMoOff => 'SPOMALENIE VYP';
}
