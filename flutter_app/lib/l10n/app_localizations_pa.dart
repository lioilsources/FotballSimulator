// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Panjabi Punjabi (`pa`).
class AppLocalizationsPa extends AppLocalizations {
  AppLocalizationsPa([String locale = 'pa']) : super(locale);

  @override
  String get resultGoal => 'ਗੋਲ!';

  @override
  String get resultMiss => 'ਖੁੰਝ ਗਿਆ';

  @override
  String get resultLate => 'ਬਹੁਤ ਦੇਰ';

  @override
  String get resultShort => 'ਪਹੁੰਚੀ ਨਹੀਂ';

  @override
  String kickAir(String ms) {
    return 'ਹਵਾ ਵਿੱਚ ਕਿੱਕ! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/h · $spin ਚੱਕਰ/ਸ · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'ਪਰਫ਼ੈਕਟ';

  @override
  String get ratingGood => 'ਵਧੀਆ';

  @override
  String get ratingEarly => 'ਜਲਦੀ';

  @override
  String get ratingLate => 'ਦੇਰ ਨਾਲ';

  @override
  String get slowMoOn => 'ਸਲੋ-ਮੋ ਚਾਲੂ';

  @override
  String get slowMoOff => 'ਸਲੋ-ਮੋ ਬੰਦ';
}
