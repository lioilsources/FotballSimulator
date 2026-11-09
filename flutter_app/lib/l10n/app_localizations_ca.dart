// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Catalan Valencian (`ca`).
class AppLocalizationsCa extends AppLocalizations {
  AppLocalizationsCa([String locale = 'ca']) : super(locale);

  @override
  String get resultGoal => 'GOL!';

  @override
  String get resultMiss => 'FORA';

  @override
  String get resultLate => 'MASSA TARD';

  @override
  String get resultShort => 'CURT';

  @override
  String kickAir(String ms) {
    return 'A L\'AIRE! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/h · $spin v/s · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'PERFECTE';

  @override
  String get ratingGood => 'BÉ';

  @override
  String get ratingEarly => 'AVIAT';

  @override
  String get ratingLate => 'TARD';

  @override
  String get slowMoOn => 'CÀMERA LENTA: SÍ';

  @override
  String get slowMoOff => 'CÀMERA LENTA: NO';
}
