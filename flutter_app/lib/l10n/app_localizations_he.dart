// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get resultGoal => 'גול!';

  @override
  String get resultMiss => 'החטאה';

  @override
  String get resultLate => 'מאוחר מדי';

  @override
  String get resultShort => 'לא הגיע';

  @override
  String kickAir(String ms) {
    return 'בעיטה באוויר! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed קמ״ש · $spin סיבובים/ש׳ · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'מושלם';

  @override
  String get ratingGood => 'טוב';

  @override
  String get ratingEarly => 'מוקדם';

  @override
  String get ratingLate => 'מאוחר';

  @override
  String get slowMoOn => 'הילוך איטי: פועל';

  @override
  String get slowMoOff => 'הילוך איטי: כבוי';
}
