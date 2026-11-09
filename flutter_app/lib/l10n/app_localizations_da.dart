// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Danish (`da`).
class AppLocalizationsDa extends AppLocalizations {
  AppLocalizationsDa([String locale = 'da']) : super(locale);

  @override
  String get resultGoal => 'MÅL!';

  @override
  String get resultMiss => 'FORBI';

  @override
  String get resultLate => 'FOR SENT';

  @override
  String get resultShort => 'FOR KORT';

  @override
  String kickAir(String ms) {
    return 'LUFTSPARK! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/t · $spin omdr./s · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'PERFEKT';

  @override
  String get ratingGood => 'GODT';

  @override
  String get ratingEarly => 'FOR TIDLIGT';

  @override
  String get ratingLate => 'FOR SENT';

  @override
  String get slowMoOn => 'SLOWMOTION TIL';

  @override
  String get slowMoOff => 'SLOWMOTION FRA';
}
