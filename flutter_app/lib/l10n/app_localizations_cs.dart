// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get resultGoal => 'GÓL!';

  @override
  String get resultMiss => 'MIMO';

  @override
  String get resultLate => 'POZDĚ';

  @override
  String get resultShort => 'NEDOLETĚL';

  @override
  String kickAir(String ms) {
    return 'VZDUCH! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/h · $spin ot/s · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'PERFEKTNÍ';

  @override
  String get ratingGood => 'DOBRÝ';

  @override
  String get ratingEarly => 'BRZY';

  @override
  String get ratingLate => 'POZDĚ';

  @override
  String get slowMoOn => 'ZPOMALENÍ ZAP';

  @override
  String get slowMoOff => 'ZPOMALENÍ VYP';
}
