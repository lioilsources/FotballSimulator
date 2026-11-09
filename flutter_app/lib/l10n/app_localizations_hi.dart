// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get resultGoal => 'गोल!';

  @override
  String get resultMiss => 'चूक गए';

  @override
  String get resultLate => 'बहुत देर';

  @override
  String get resultShort => 'कम पड़ी';

  @override
  String kickAir(String ms) {
    return 'हवा में किक! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/h · $spin चक्कर/से · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'परफ़ेक्ट';

  @override
  String get ratingGood => 'अच्छा';

  @override
  String get ratingEarly => 'जल्दी';

  @override
  String get ratingLate => 'देर से';

  @override
  String get slowMoOn => 'स्लो-मो चालू';

  @override
  String get slowMoOff => 'स्लो-मो बंद';
}
