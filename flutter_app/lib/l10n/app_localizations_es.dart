// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get resultGoal => '¡GOL!';

  @override
  String get resultMiss => 'FUERA';

  @override
  String get resultLate => 'DEMASIADO TARDE';

  @override
  String get resultShort => 'SE QUEDÓ CORTO';

  @override
  String kickAir(String ms) {
    return '¡AL AIRE! ($ms ms)';
  }

  @override
  String kickStats(int speed, String spin, String rating, String ms) {
    return '$speed km/h · $spin rev/s · $rating ($ms ms)';
  }

  @override
  String get ratingPerfect => 'PERFECTO';

  @override
  String get ratingGood => 'BIEN';

  @override
  String get ratingEarly => 'PRONTO';

  @override
  String get ratingLate => 'TARDE';

  @override
  String get slowMoOn => 'CÁMARA LENTA: SÍ';

  @override
  String get slowMoOff => 'CÁMARA LENTA: NO';
}
