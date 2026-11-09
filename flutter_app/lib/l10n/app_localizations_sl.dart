// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovenian (`sl`).
class AppLocalizationsSl extends AppLocalizations {
  AppLocalizationsSl([String locale = 'sl']) : super(locale);

  @override
  String get resultGoal => 'GOL!';

  @override
  String get resultMiss => 'MIMO';

  @override
  String get resultLate => 'PREPOZNO';

  @override
  String get resultShort => 'PREKRATKO';

  @override
  String kickAir(String ms) {
    return 'V PRAZNO! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/h · $spin vrt./s · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'POPOLNO';

  @override
  String get ratingGood => 'DOBRO';

  @override
  String get ratingEarly => 'PREZGODAJ';

  @override
  String get ratingLate => 'POZNO';

  @override
  String get slowMoOn => 'POČASNI POSNETEK: VKL.';

  @override
  String get slowMoOff => 'POČASNI POSNETEK: IZKL.';
}
