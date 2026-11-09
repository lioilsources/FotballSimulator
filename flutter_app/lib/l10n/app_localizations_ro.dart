// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Romanian Moldavian Moldovan (`ro`).
class AppLocalizationsRo extends AppLocalizations {
  AppLocalizationsRo([String locale = 'ro']) : super(locale);

  @override
  String get resultGoal => 'GOL!';

  @override
  String get resultMiss => 'PE LÂNGĂ';

  @override
  String get resultLate => 'PREA TÂRZIU';

  @override
  String get resultShort => 'PREA SCURT';

  @override
  String kickAir(String ms) {
    return 'RATARE! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/h · $spin rot/s · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'PERFECT';

  @override
  String get ratingGood => 'BUN';

  @override
  String get ratingEarly => 'DEVREME';

  @override
  String get ratingLate => 'TÂRZIU';

  @override
  String get slowMoOn => 'ÎNCETINIRE: DA';

  @override
  String get slowMoOff => 'ÎNCETINIRE: NU';
}
