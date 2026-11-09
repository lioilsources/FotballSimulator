// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Modern Greek (`el`).
class AppLocalizationsEl extends AppLocalizations {
  AppLocalizationsEl([String locale = 'el']) : super(locale);

  @override
  String get resultGoal => 'ΓΚΟΛ!';

  @override
  String get resultMiss => 'ΑΣΤΟΧΙΑ';

  @override
  String get resultLate => 'ΠΟΛΥ ΑΡΓΑ';

  @override
  String get resultShort => 'ΔΕΝ ΕΦΤΑΣΕ';

  @override
  String kickAir(String ms) {
    return 'ΚΛΩΤΣΙΑ ΣΤΟΝ ΑΕΡΑ! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/h · $spin στρ./s · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'ΤΕΛΕΙΟ';

  @override
  String get ratingGood => 'ΚΑΛΟ';

  @override
  String get ratingEarly => 'ΝΩΡΙΣ';

  @override
  String get ratingLate => 'ΑΡΓΑ';

  @override
  String get slowMoOn => 'ΑΡΓΗ ΚΙΝΗΣΗ: ΝΑΙ';

  @override
  String get slowMoOff => 'ΑΡΓΗ ΚΙΝΗΣΗ: ΟΧΙ';
}
