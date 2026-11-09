// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get resultGoal => 'GOL!';

  @override
  String get resultMiss => 'FUORI';

  @override
  String get resultLate => 'TROPPO TARDI';

  @override
  String get resultShort => 'CORTO';

  @override
  String kickAir(String ms) {
    return 'A VUOTO! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/h · $spin giri/s · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'PERFETTO';

  @override
  String get ratingGood => 'BUONO';

  @override
  String get ratingEarly => 'IN ANTICIPO';

  @override
  String get ratingLate => 'IN RITARDO';

  @override
  String get slowMoOn => 'RALLENTY: SÌ';

  @override
  String get slowMoOff => 'RALLENTY: NO';
}
