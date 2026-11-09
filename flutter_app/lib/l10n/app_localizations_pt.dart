// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get resultGoal => 'GOLO!';

  @override
  String get resultMiss => 'AO LADO';

  @override
  String get resultLate => 'TARDE DEMAIS';

  @override
  String get resultShort => 'NÃO CHEGOU';

  @override
  String kickAir(String ms) {
    return 'FALHOU A BOLA! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/h · $spin rot/s · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'PERFEITO';

  @override
  String get ratingGood => 'BOM';

  @override
  String get ratingEarly => 'ADIANTADO';

  @override
  String get ratingLate => 'ATRASADO';

  @override
  String get slowMoOn => 'CÂMARA LENTA: SIM';

  @override
  String get slowMoOff => 'CÂMARA LENTA: NÃO';
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get resultGoal => 'GOL!';

  @override
  String get resultMiss => 'PRA FORA';

  @override
  String get resultLate => 'TARDE DEMAIS';

  @override
  String get resultShort => 'NÃO CHEGOU';

  @override
  String kickAir(String ms) {
    return 'FUROU! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/h · $spin rot/s · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'PERFEITO';

  @override
  String get ratingGood => 'BOM';

  @override
  String get ratingEarly => 'ADIANTADO';

  @override
  String get ratingLate => 'ATRASADO';

  @override
  String get slowMoOn => 'CÂMERA LENTA: SIM';

  @override
  String get slowMoOff => 'CÂMERA LENTA: NÃO';
}
