// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get resultGoal => 'GÓL!';

  @override
  String get resultMiss => 'MELLÉ';

  @override
  String get resultLate => 'TÚL KÉSŐ';

  @override
  String get resultShort => 'RÖVID LETT';

  @override
  String kickAir(String ms) {
    return 'LEVEGŐBE! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/h · $spin ford./s · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'TÖKÉLETES';

  @override
  String get ratingGood => 'JÓ';

  @override
  String get ratingEarly => 'KORAI';

  @override
  String get ratingLate => 'KÉSŐI';

  @override
  String get slowMoOn => 'LASSÍTÁS BE';

  @override
  String get slowMoOff => 'LASSÍTÁS KI';
}
