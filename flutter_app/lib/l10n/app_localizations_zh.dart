// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get resultGoal => '进球！';

  @override
  String get resultMiss => '射偏了';

  @override
  String get resultLate => '太晚了';

  @override
  String get resultShort => '力量不足';

  @override
  String kickAir(String ms) {
    return '踢空了！（$ms 毫秒）';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/h · $spin 转/秒 · $rating（$ms 毫秒）';
  }

  @override
  String get ratingPerfect => '完美';

  @override
  String get ratingGood => '不错';

  @override
  String get ratingEarly => '太早';

  @override
  String get ratingLate => '太晚';

  @override
  String get slowMoOn => '慢动作：开';

  @override
  String get slowMoOff => '慢动作：关';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get resultGoal => '進球！';

  @override
  String get resultMiss => '射偏了';

  @override
  String get resultLate => '太晚了';

  @override
  String get resultShort => '力道不足';

  @override
  String kickAir(String ms) {
    return '踢空了！（$ms 毫秒）';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/h · $spin 轉/秒 · $rating（$ms 毫秒）';
  }

  @override
  String get ratingPerfect => '完美';

  @override
  String get ratingGood => '不錯';

  @override
  String get ratingEarly => '太早';

  @override
  String get ratingLate => '太晚';

  @override
  String get slowMoOn => '慢動作：開';

  @override
  String get slowMoOff => '慢動作：關';
}
