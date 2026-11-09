// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get resultGoal => 'GOL!';

  @override
  String get resultMiss => 'PUDŁO';

  @override
  String get resultLate => 'ZA PÓŹNO';

  @override
  String get resultShort => 'ZA KRÓTKO';

  @override
  String kickAir(String ms) {
    return 'KIKS! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/h · $spin obr./s · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'IDEALNIE';

  @override
  String get ratingGood => 'DOBRZE';

  @override
  String get ratingEarly => 'ZA WCZEŚNIE';

  @override
  String get ratingLate => 'ZA PÓŹNO';

  @override
  String get slowMoOn => 'SPOWOLNIENIE WŁ.';

  @override
  String get slowMoOff => 'SPOWOLNIENIE WYŁ.';
}
