// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get resultGoal => 'TOR!';

  @override
  String get resultMiss => 'DANEBEN';

  @override
  String get resultLate => 'ZU SPÄT';

  @override
  String get resultShort => 'ZU KURZ';

  @override
  String kickAir(String ms) {
    return 'LUFTLOCH! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/h · $spin U/s · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'PERFEKT';

  @override
  String get ratingGood => 'GUT';

  @override
  String get ratingEarly => 'ZU FRÜH';

  @override
  String get ratingLate => 'ZU SPÄT';

  @override
  String get slowMoOn => 'ZEITLUPE AN';

  @override
  String get slowMoOff => 'ZEITLUPE AUS';
}
