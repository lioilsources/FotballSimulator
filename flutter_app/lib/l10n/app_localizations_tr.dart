// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get resultGoal => 'GOL!';

  @override
  String get resultMiss => 'AUT';

  @override
  String get resultLate => 'ÇOK GEÇ';

  @override
  String get resultShort => 'KISA KALDI';

  @override
  String kickAir(String ms) {
    return 'ISKALADIN! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/sa · $spin dev/sn · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'MÜKEMMEL';

  @override
  String get ratingGood => 'İYİ';

  @override
  String get ratingEarly => 'ERKEN';

  @override
  String get ratingLate => 'GEÇ';

  @override
  String get slowMoOn => 'AĞIR ÇEKİM AÇIK';

  @override
  String get slowMoOff => 'AĞIR ÇEKİM KAPALI';
}
