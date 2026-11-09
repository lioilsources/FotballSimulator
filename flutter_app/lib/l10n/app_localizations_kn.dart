// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kannada (`kn`).
class AppLocalizationsKn extends AppLocalizations {
  AppLocalizationsKn([String locale = 'kn']) : super(locale);

  @override
  String get resultGoal => 'ಗೋಲ್!';

  @override
  String get resultMiss => 'ತಪ್ಪಿತು';

  @override
  String get resultLate => 'ತುಂಬಾ ತಡ';

  @override
  String get resultShort => 'ತಲುಪಲಿಲ್ಲ';

  @override
  String kickAir(String ms) {
    return 'ಗಾಳಿಯಲ್ಲಿ ಕಿಕ್! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/h · $spin ಸುತ್ತು/ಸೆ · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'ಪರ್ಫೆಕ್ಟ್';

  @override
  String get ratingGood => 'ಉತ್ತಮ';

  @override
  String get ratingEarly => 'ಬೇಗ';

  @override
  String get ratingLate => 'ತಡ';

  @override
  String get slowMoOn => 'ಸ್ಲೋ-ಮೋ ಆನ್';

  @override
  String get slowMoOff => 'ಸ್ಲೋ-ಮೋ ಆಫ್';
}
