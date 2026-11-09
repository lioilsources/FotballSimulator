// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get resultGoal => 'VÀO!';

  @override
  String get resultMiss => 'TRƯỢT';

  @override
  String get resultLate => 'QUÁ MUỘN';

  @override
  String get resultShort => 'THIẾU LỰC';

  @override
  String kickAir(String ms) {
    return 'ĐÁ HỤT! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/h · $spin vòng/giây · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'HOÀN HẢO';

  @override
  String get ratingGood => 'TỐT';

  @override
  String get ratingEarly => 'SỚM';

  @override
  String get ratingLate => 'MUỘN';

  @override
  String get slowMoOn => 'QUAY CHẬM: BẬT';

  @override
  String get slowMoOff => 'QUAY CHẬM: TẮT';
}
