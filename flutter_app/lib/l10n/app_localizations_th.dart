// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get resultGoal => 'ประตู!';

  @override
  String get resultMiss => 'พลาด';

  @override
  String get resultLate => 'ช้าเกินไป';

  @override
  String get resultShort => 'ไปไม่ถึง';

  @override
  String kickAir(String ms) {
    return 'เตะวืด! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed กม./ชม. · $spin รอบ/วิ · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'สมบูรณ์แบบ';

  @override
  String get ratingGood => 'ดี';

  @override
  String get ratingEarly => 'เร็วไป';

  @override
  String get ratingLate => 'ช้าไป';

  @override
  String get slowMoOn => 'สโลว์โมชัน: เปิด';

  @override
  String get slowMoOff => 'สโลว์โมชัน: ปิด';
}
