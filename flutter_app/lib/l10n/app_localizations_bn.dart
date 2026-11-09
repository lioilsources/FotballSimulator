// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get resultGoal => 'গোল!';

  @override
  String get resultMiss => 'মিস';

  @override
  String get resultLate => 'অনেক দেরি';

  @override
  String get resultShort => 'পৌঁছায়নি';

  @override
  String kickAir(String ms) {
    return 'বাতাসে কিক! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/h · $spin পাক/সে · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'নিখুঁত';

  @override
  String get ratingGood => 'ভালো';

  @override
  String get ratingEarly => 'আগে';

  @override
  String get ratingLate => 'দেরিতে';

  @override
  String get slowMoOn => 'স্লো-মো চালু';

  @override
  String get slowMoOff => 'স্লো-মো বন্ধ';
}
