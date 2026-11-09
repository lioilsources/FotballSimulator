// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malay (`ms`).
class AppLocalizationsMs extends AppLocalizations {
  AppLocalizationsMs([String locale = 'ms']) : super(locale);

  @override
  String get resultGoal => 'GOL!';

  @override
  String get resultMiss => 'TERSASAR';

  @override
  String get resultLate => 'TERLAMBAT';

  @override
  String get resultShort => 'TIDAK SAMPAI';

  @override
  String kickAir(String ms) {
    return 'SEPAK ANGIN! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/j · $spin psn/s · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'SEMPURNA';

  @override
  String get ratingGood => 'BAGUS';

  @override
  String get ratingEarly => 'AWAL';

  @override
  String get ratingLate => 'LEWAT';

  @override
  String get slowMoOn => 'GERAK PERLAHAN: HIDUP';

  @override
  String get slowMoOff => 'GERAK PERLAHAN: MATI';
}
