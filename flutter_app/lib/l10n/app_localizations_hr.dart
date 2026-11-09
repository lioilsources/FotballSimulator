// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Croatian (`hr`).
class AppLocalizationsHr extends AppLocalizations {
  AppLocalizationsHr([String locale = 'hr']) : super(locale);

  @override
  String get resultGoal => 'GOL!';

  @override
  String get resultMiss => 'PROMAŠAJ';

  @override
  String get resultLate => 'PREKASNO';

  @override
  String get resultShort => 'PREKRATKO';

  @override
  String kickAir(String ms) {
    return 'U ZRAK! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/h · $spin okr./s · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'SAVRŠENO';

  @override
  String get ratingGood => 'DOBRO';

  @override
  String get ratingEarly => 'PRERANO';

  @override
  String get ratingLate => 'KASNO';

  @override
  String get slowMoOn => 'USPORENO: UKLJ.';

  @override
  String get slowMoOff => 'USPORENO: ISKLJ.';
}
