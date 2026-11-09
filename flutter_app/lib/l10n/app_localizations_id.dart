// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get resultGoal => 'GOL!';

  @override
  String get resultMiss => 'MELESET';

  @override
  String get resultLate => 'TERLAMBAT';

  @override
  String get resultShort => 'KURANG JAUH';

  @override
  String kickAir(String ms) {
    return 'TENDANG ANGIN! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/j · $spin put/dtk · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'SEMPURNA';

  @override
  String get ratingGood => 'BAGUS';

  @override
  String get ratingEarly => 'TERLALU CEPAT';

  @override
  String get ratingLate => 'TERLAMBAT';

  @override
  String get slowMoOn => 'GERAK LAMBAT AKTIF';

  @override
  String get slowMoOff => 'GERAK LAMBAT NONAKTIF';
}
