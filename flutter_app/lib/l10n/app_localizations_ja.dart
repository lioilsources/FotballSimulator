// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get resultGoal => 'ゴール！';

  @override
  String get resultMiss => 'ミス';

  @override
  String get resultLate => '遅すぎ';

  @override
  String get resultShort => '届かず';

  @override
  String kickAir(String ms) {
    return '空振り！（$ms ms）';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/h · $spin 回転/秒 · $rating（$ms ms）';
  }

  @override
  String get ratingPerfect => 'パーフェクト';

  @override
  String get ratingGood => 'グッド';

  @override
  String get ratingEarly => '早い';

  @override
  String get ratingLate => '遅い';

  @override
  String get slowMoOn => 'スロー ON';

  @override
  String get slowMoOff => 'スロー OFF';
}
