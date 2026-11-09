// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Telugu (`te`).
class AppLocalizationsTe extends AppLocalizations {
  AppLocalizationsTe([String locale = 'te']) : super(locale);

  @override
  String get resultGoal => 'గోల్!';

  @override
  String get resultMiss => 'తప్పింది';

  @override
  String get resultLate => 'చాలా ఆలస్యం';

  @override
  String get resultShort => 'చేరలేదు';

  @override
  String kickAir(String ms) {
    return 'గాలిలో కిక్! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/h · $spin భ్రమణాలు/సె · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'పర్ఫెక్ట్';

  @override
  String get ratingGood => 'బాగుంది';

  @override
  String get ratingEarly => 'ముందుగా';

  @override
  String get ratingLate => 'ఆలస్యం';

  @override
  String get slowMoOn => 'స్లో-మో ఆన్';

  @override
  String get slowMoOff => 'స్లో-మో ఆఫ్';
}
