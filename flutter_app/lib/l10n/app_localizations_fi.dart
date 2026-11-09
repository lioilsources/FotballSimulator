// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Finnish (`fi`).
class AppLocalizationsFi extends AppLocalizations {
  AppLocalizationsFi([String locale = 'fi']) : super(locale);

  @override
  String get resultGoal => 'MAALI!';

  @override
  String get resultMiss => 'OHI';

  @override
  String get resultLate => 'LIIAN MYÖHÄÄN';

  @override
  String get resultShort => 'JÄI LYHYEKSI';

  @override
  String kickAir(String ms) {
    return 'HUTI! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/h · $spin kierr./s · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'TÄYDELLINEN';

  @override
  String get ratingGood => 'HYVÄ';

  @override
  String get ratingEarly => 'AIKAISIN';

  @override
  String get ratingLate => 'MYÖHÄÄN';

  @override
  String get slowMoOn => 'HIDASTUS PÄÄLLÄ';

  @override
  String get slowMoOff => 'HIDASTUS POIS';
}
