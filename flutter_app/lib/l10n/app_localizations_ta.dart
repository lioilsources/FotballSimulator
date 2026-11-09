// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get resultGoal => 'கோல்!';

  @override
  String get resultMiss => 'தவறியது';

  @override
  String get resultLate => 'மிகத் தாமதம்';

  @override
  String get resultShort => 'எட்டவில்லை';

  @override
  String kickAir(String ms) {
    return 'காற்றில் உதை! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/h · $spin சுற்று/வி · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'அருமை';

  @override
  String get ratingGood => 'நன்று';

  @override
  String get ratingEarly => 'முன்கூட்டியே';

  @override
  String get ratingLate => 'தாமதம்';

  @override
  String get slowMoOn => 'ஸ்லோ-மோ ஆன்';

  @override
  String get slowMoOff => 'ஸ்லோ-மோ ஆஃப்';
}
