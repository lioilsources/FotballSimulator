// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get resultGoal => 'هدف!';

  @override
  String get resultMiss => 'خارج المرمى';

  @override
  String get resultLate => 'متأخر جدًا';

  @override
  String get resultShort => 'لم تصل';

  @override
  String kickAir(String ms) {
    return 'ركلة في الهواء! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed كم/س · $spin دورة/ث · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'مثالي';

  @override
  String get ratingGood => 'جيد';

  @override
  String get ratingEarly => 'مبكر';

  @override
  String get ratingLate => 'متأخر';

  @override
  String get slowMoOn => 'الحركة البطيئة: تشغيل';

  @override
  String get slowMoOff => 'الحركة البطيئة: إيقاف';
}
