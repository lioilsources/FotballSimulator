// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get resultGoal => 'MÅL!';

  @override
  String get resultMiss => 'MISS';

  @override
  String get resultLate => 'FÖR SENT';

  @override
  String get resultShort => 'FÖR KORT';

  @override
  String kickAir(String ms) {
    return 'LUFTSPARK! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/h · $spin varv/s · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'PERFEKT';

  @override
  String get ratingGood => 'BRA';

  @override
  String get ratingEarly => 'FÖR TIDIGT';

  @override
  String get ratingLate => 'FÖR SENT';

  @override
  String get slowMoOn => 'SLOWMOTION PÅ';

  @override
  String get slowMoOff => 'SLOWMOTION AV';
}
