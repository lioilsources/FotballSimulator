// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get resultGoal => '골!';

  @override
  String get resultMiss => '빗나감';

  @override
  String get resultLate => '너무 늦음';

  @override
  String get resultShort => '거리 부족';

  @override
  String kickAir(String ms) {
    return '헛발질! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/h · $spin 회전/초 · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => '퍼펙트';

  @override
  String get ratingGood => '굿';

  @override
  String get ratingEarly => '빠름';

  @override
  String get ratingLate => '늦음';

  @override
  String get slowMoOn => '슬로모션 켬';

  @override
  String get slowMoOff => '슬로모션 끔';
}
