// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian Bokmål (`nb`).
class AppLocalizationsNb extends AppLocalizations {
  AppLocalizationsNb([String locale = 'nb']) : super(locale);

  @override
  String get resultGoal => 'MÅL!';

  @override
  String get resultMiss => 'BOM';

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
  String get ratingGood => 'BRA';

  @override
  String get ratingEarly => 'FOR TIDLIG';

  @override
  String get ratingLate => 'FOR SENT';

  @override
  String get slowMoOn => 'SAKTE FILM PÅ';

  @override
  String get slowMoOff => 'SAKTE FILM AV';
}
