// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Oriya (`or`).
class AppLocalizationsOr extends AppLocalizations {
  AppLocalizationsOr([String locale = 'or']) : super(locale);

  @override
  String get resultGoal => 'ଗୋଲ୍!';

  @override
  String get resultMiss => 'ଚୁକିଗଲା';

  @override
  String get resultLate => 'ବହୁତ ଡେରି';

  @override
  String get resultShort => 'ପହଞ୍ଚିଲା ନାହିଁ';

  @override
  String kickAir(String ms) {
    return 'ପବନରେ କିକ୍! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/h · $spin ଘୂର୍ଣ୍ଣନ/ସେ · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'ପରଫେକ୍ଟ';

  @override
  String get ratingGood => 'ଭଲ';

  @override
  String get ratingEarly => 'ଶୀଘ୍ର';

  @override
  String get ratingLate => 'ଡେରି';

  @override
  String get slowMoOn => 'ସ୍ଲୋ-ମୋ ଚାଲୁ';

  @override
  String get slowMoOff => 'ସ୍ଲୋ-ମୋ ବନ୍ଦ';
}
