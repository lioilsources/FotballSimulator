// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get resultGoal => 'گول!';

  @override
  String get resultMiss => 'چوک گئے';

  @override
  String get resultLate => 'بہت دیر';

  @override
  String get resultShort => 'نہیں پہنچی';

  @override
  String kickAir(String ms) {
    return 'ہوا میں کک! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/h · $spin چکر/سیکنڈ · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'بہترین';

  @override
  String get ratingGood => 'اچھا';

  @override
  String get ratingEarly => 'جلدی';

  @override
  String get ratingLate => 'دیر سے';

  @override
  String get slowMoOn => 'سلو موشن: آن';

  @override
  String get slowMoOff => 'سلو موشن: آف';
}
