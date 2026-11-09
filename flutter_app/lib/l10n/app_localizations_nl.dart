// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get resultGoal => 'GOAL!';

  @override
  String get resultMiss => 'MIS';

  @override
  String get resultLate => 'TE LAAT';

  @override
  String get resultShort => 'TE KORT';

  @override
  String kickAir(String ms) {
    return 'MISTRAP! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/u · $spin omw./s · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'PERFECT';

  @override
  String get ratingGood => 'GOED';

  @override
  String get ratingEarly => 'TE VROEG';

  @override
  String get ratingLate => 'TE LAAT';

  @override
  String get slowMoOn => 'SLOW-MO AAN';

  @override
  String get slowMoOff => 'SLOW-MO UIT';
}
