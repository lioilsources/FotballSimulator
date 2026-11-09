// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get resultGoal => 'ГОЛ!';

  @override
  String get resultMiss => 'МИМО';

  @override
  String get resultLate => 'СЛИШКОМ ПОЗДНО';

  @override
  String get resultShort => 'НЕДОЛЁТ';

  @override
  String kickAir(String ms) {
    return 'МИМО МЯЧА! ($ms мс)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed км/ч · $spin об/с · $rating ($ms мс)';
  }

  @override
  String get ratingPerfect => 'ИДЕАЛЬНО';

  @override
  String get ratingGood => 'ХОРОШО';

  @override
  String get ratingEarly => 'РАНО';

  @override
  String get ratingLate => 'ПОЗДНО';

  @override
  String get slowMoOn => 'ЗАМЕДЛЕНИЕ ВКЛ';

  @override
  String get slowMoOff => 'ЗАМЕДЛЕНИЕ ВЫКЛ';
}
