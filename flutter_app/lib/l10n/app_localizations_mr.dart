// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get resultGoal => 'गोल!';

  @override
  String get resultMiss => 'चुकला';

  @override
  String get resultLate => 'खूप उशीर';

  @override
  String get resultShort => 'कमी पडला';

  @override
  String kickAir(String ms) {
    return 'हवेत किक! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/h · $spin फेरे/से · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'परफेक्ट';

  @override
  String get ratingGood => 'छान';

  @override
  String get ratingEarly => 'लवकर';

  @override
  String get ratingLate => 'उशिरा';

  @override
  String get slowMoOn => 'स्लो-मो चालू';

  @override
  String get slowMoOff => 'स्लो-मो बंद';
}
