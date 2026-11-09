// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Gujarati (`gu`).
class AppLocalizationsGu extends AppLocalizations {
  AppLocalizationsGu([String locale = 'gu']) : super(locale);

  @override
  String get resultGoal => 'ગોલ!';

  @override
  String get resultMiss => 'ચૂકી ગયા';

  @override
  String get resultLate => 'બહુ મોડું';

  @override
  String get resultShort => 'ઓછું પડ્યું';

  @override
  String kickAir(String ms) {
    return 'હવામાં કિક! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/h · $spin ચક્કર/સે · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'પરફેક્ટ';

  @override
  String get ratingGood => 'સારું';

  @override
  String get ratingEarly => 'વહેલું';

  @override
  String get ratingLate => 'મોડું';

  @override
  String get slowMoOn => 'સ્લો-મો ચાલુ';

  @override
  String get slowMoOff => 'સ્લો-મો બંધ';
}
