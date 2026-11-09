// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malayalam (`ml`).
class AppLocalizationsMl extends AppLocalizations {
  AppLocalizationsMl([String locale = 'ml']) : super(locale);

  @override
  String get resultGoal => 'ഗോൾ!';

  @override
  String get resultMiss => 'പിഴച്ചു';

  @override
  String get resultLate => 'വളരെ വൈകി';

  @override
  String get resultShort => 'എത്തിയില്ല';

  @override
  String kickAir(String ms) {
    return 'വായുവിൽ കിക്ക്! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/h · $spin ചുറ്റ്/സെ · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'പെർഫെക്റ്റ്';

  @override
  String get ratingGood => 'നല്ലത്';

  @override
  String get ratingEarly => 'നേരത്തെ';

  @override
  String get ratingLate => 'വൈകി';

  @override
  String get slowMoOn => 'സ്ലോ-മോ ഓൺ';

  @override
  String get slowMoOff => 'സ്ലോ-മോ ഓഫ്';
}
