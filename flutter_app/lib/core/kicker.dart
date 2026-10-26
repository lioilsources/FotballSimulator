import 'dart:math' as math;

import 'tuning.dart';
import 'vec3.dart';

enum Foot { right, left }

enum KickerPhase { stance, windup, strike, recover }

/// Klouby kostry. L/R = levá/pravá strana těla (hráč kouká na -z, pravá
/// ruka je na +x).
enum Joint {
  head, neck, pelvis,
  shoulderL, shoulderR, elbowL, elbowR, handL, handR,
  hipL, hipR, kneeL, kneeR, ankleL, ankleR, toeL, toeR,
}

/// Kosti pro vykreslení (a budoucí Godot capsule meshe).
const kickerBones = [
  (Joint.pelvis, Joint.neck),
  (Joint.shoulderL, Joint.shoulderR),
  (Joint.hipL, Joint.hipR),
  (Joint.shoulderL, Joint.elbowL), (Joint.elbowL, Joint.handL),
  (Joint.shoulderR, Joint.elbowR), (Joint.elbowR, Joint.handR),
  (Joint.hipL, Joint.kneeL), (Joint.kneeL, Joint.ankleL), (Joint.ankleL, Joint.toeL),
  (Joint.hipR, Joint.kneeR), (Joint.kneeR, Joint.ankleR), (Joint.ankleR, Joint.toeR),
];

/// Procedurální fotbalista (vizuální zpětná vazba kopu). Čistý Dart bez
/// Flutteru — port do Godotu půjde 1:1 a pózy hlídá golden test.
///
/// Fáze: postoj (dojde za ideální bod kontaktu) → nápřah (drží se prst) →
/// úder (puštění; nárt v SKUTEČNÉM kontaktním bodě — pozdě = nad středem
/// míče, brzy = pod ním, MISS = kope do místa, kde měl míč být) →
/// dokopnutí ve směru výkopu → návrat. Běží v herním čase: freeze-frame
/// drží snímek kontaktu, slow-mo zpomalí nápřah.
///
/// Gameplay se nemění — kontakt je okamžitý při puštění. Pro „opravdový
/// švih“ (ROADMAP D3) stačí volat [strike] s `lead > 0`: noha pak animuje
/// došvih z nápřahu do kontaktu, a kontakt v Game se posune o stejný čas.
class Kicker {
  Foot foot;
  KickerPhase phase = KickerPhase.stance;

  Vec3 _target = const Vec3(0, T.idealKickHeight, -1.8); // ideální střed míče
  Vec3 _pelvis = Vec3.zero;
  bool _placed = false;
  double _t = 0.0; // čas ve fázi (herní)
  double _windup = 0.0; // 0..1 nápřah
  double _lead = 0.0; // došvih před kontaktem (0 = okamžitý kontakt)

  // úder
  Vec3 _contactAnkle = Vec3.zero, _contactToe = Vec3.zero;
  Vec3 _followAnkle = Vec3.zero, _followToe = Vec3.zero;
  Vec3 _backAnkle = Vec3.zero; // kde byla noha v nápřahu (stopa švihu)
  double _lean = 0.0; // náklon trupu vpřed (+) / vzad (−), rad
  // pro návrat: póza na konci dokopnutí
  Vec3 _fromAnkle = Vec3.zero, _fromToe = Vec3.zero;

  /// Průhledný, dokud míč přilétá — hráč stojí mezi kamerou a míčem a
  /// nesmí zakrýt timing. Od úderu plně vidět (zpětná vazba kontaktu).
  bool ghost = true;
  double opacity = T.kickerGhostAlpha;

  /// Hranice fází s tolerancí: čas je součet ticků a 0.35 s po 42 tickách
  /// vyjde podle zaokrouhlení těsně pod/nad — Godot (JSON dt o 2 ULP jinak)
  /// by přešel o tick později než Dart.
  static const _eps = 1e-9;

  Kicker({this.foot = Foot.right});

  /// Střed míče v ideálním okamžiku kontaktu aktuálního serve.
  Vec3 get idealBall => _target;

  /// +1 kope pravou (+x), −1 levou.
  double get side => foot == Foot.right ? 1.0 : -1.0;

  /// Stopa švihu: nápřah → kontakt, `age` 0..1 (null = nekreslit).
  ({Vec3 from, Vec3 to, double age})? get swoosh {
    if (phase != KickerPhase.strike || _t > T.kickerSwooshTime + _eps) return null;
    return (from: _backAnkle, to: _contactAnkle, age: _t / T.kickerSwooshTime);
  }

  // ── události ──────────────────────────────────────────────────

  /// Nový serve: [idealBall] = střed míče v ideálním okamžiku kontaktu.
  void onServe(Vec3 idealBall) {
    _target = idealBall;
    ghost = true;
    if (!_placed) {
      _pelvis = _stancePelvis();
      _placed = true;
    }
    if (phase != KickerPhase.recover) _enter(KickerPhase.stance);
  }

  void windup() {
    if (phase == KickerPhase.stance) _enter(KickerPhase.windup);
  }

  void cancelWindup() {
    if (phase == KickerPhase.windup) _enter(KickerPhase.stance);
  }

  /// Úder: [contact] = bod na plášti míče (svět), [normalOut] = směr ze
  /// středu míče ke kontaktu, [kickVel] = výsledná rychlost míče (pro
  /// dokopnutí), [power] 0..1.
  void strike(Vec3 contact, Vec3 normalOut, Vec3 kickVel, double power,
      {double lead = 0.0}) {
    _backAnkle = _ankleKick(_windup); // aktuální poloha (nápřah, nebo postoj)
    _lead = lead;

    // nárt přiložený zvenku na plášť, špička dolů-dopředu (propnutý kotník)
    final instep = contact + normalOut * 0.045;
    const footDir = Vec3(0, -0.93, -0.37);
    _contactAnkle = instep - footDir * 0.09;
    _contactToe = instep + footDir * (T.kickerFootLen - 0.09);

    // dokopnutí: noha pokračuje ve směru výkopu, výš při silném/podebraném
    // kopu, mírně přes tělo (na stranu stojné nohy)
    final speed = kickVel.length;
    final dir = speed > 0.01 ? kickVel / speed : const Vec3(0, 0, -1);
    final flat = dir.withY(0).normalized();
    final p = power.clamp(0.0, 1.0);
    _followAnkle = _contactAnkle +
        flat * (0.25 + 0.3 * p) +
        Vec3.up * (0.12 + 0.35 * p * (0.5 + math.max(0.0, dir.y))) +
        Vec3(-side * 0.08, 0, 0);
    _followToe = _followAnkle + (flat + const Vec3(0, 0.2, 0)).normalized() * T.kickerFootLen;

    // trup: zásah nad středem (pozdě) = přes míč dopředu, pod střed = záklon
    final offY = normalOut.y.clamp(-1.0, 1.0);
    _lean = 0.12 + 0.35 * offY;
    ghost = false;
    opacity = 1.0;
    _enter(KickerPhase.strike);
  }

  // ── simulace ──────────────────────────────────────────────────

  void update(double dt) {
    _t += dt;
    final targetOpacity = ghost ? T.kickerGhostAlpha : 1.0;
    opacity += (targetOpacity - opacity) * (1 - math.exp(-T.kickerFadeRate * dt));
    // pánev dojíždí do postoje za aktuální ideál (serve míč se pohybuje)
    final goal = _stancePelvis() + _windupShift() * _windup;
    _pelvis = _pelvis.lerp(goal, 1 - math.exp(-T.kickerFollowRate * dt));

    switch (phase) {
      case KickerPhase.windup:
        _windup = math.min(1.0, _windup + dt / T.kickerWindupTime);
      case KickerPhase.stance:
        _windup = math.max(0.0, _windup - dt / T.kickerWindupTime);
      case KickerPhase.strike:
        if (_t >= _lead + T.kickerFollowTime - _eps) {
          _fromAnkle = _followAnkle;
          _fromToe = _followToe;
          _enter(KickerPhase.recover);
        }
      case KickerPhase.recover:
        _windup = math.max(0.0, _windup - dt / T.kickerRecoverTime);
        if (_t >= T.kickerRecoverTime - _eps) _enter(KickerPhase.stance);
    }
  }

  void _enter(KickerPhase p) {
    phase = p;
    _t = 0.0;
  }

  // ── geometrie ─────────────────────────────────────────────────

  Vec3 _stancePelvis() => Vec3(_target.x - side * T.kickerStandSide,
      T.kickerHipHeight, _target.z + T.kickerStandBack);

  /// Nápřah: krok k míči a mírný podřep.
  Vec3 _windupShift() => const Vec3(0, -0.05, -0.12);

  Vec3 _right() => const Vec3(1, 0, 0);

  Vec3 _hip(double s) => _pelvis + _right() * (s * T.kickerHipHalfWidth);

  /// Kotník kopací nohy mimo úder: postoj ↔ nápřah (pata vzadu nahoře).
  Vec3 _ankleKick(double windup) {
    final hip = _hip(side);
    final rest = Vec3(hip.x + side * 0.05, 0.08, _pelvis.z + 0.12);
    final back = hip + Vec3(side * 0.04, -0.42, 0.5);
    return rest.lerp(back, _ease(windup));
  }

  Vec3 _anklePlant() {
    final rest = Vec3(_pelvis.x - side * 0.14, 0.08, _pelvis.z - 0.02);
    final plant = Vec3(_target.x - side * T.kickerPlantSide, 0.08, _target.z + 0.15);
    final w = phase == KickerPhase.strike ? 1.0 : _ease(_windup);
    return rest.lerp(plant, w);
  }

  static double _ease(double t) => t * t * (3 - 2 * t);

  /// Aktuální póza kostry (svět).
  Map<Joint, Vec3> pose() {
    final s = side;
    // kopací noha: kotník + špička
    Vec3 ankle;
    Vec3? toe; // null = propnutá špička ve směru holeně (dopočítá se po IK)
    var action = _ease(_windup); // 0 = klid, 1 = akce (ruce do rovnováhy)
    var lean = 0.0;
    switch (phase) {
      case KickerPhase.stance:
      case KickerPhase.windup:
        ankle = _ankleKick(_windup);
      case KickerPhase.strike:
        action = 1.0;
        if (_t < _lead) {
          // došvih (jen při lead > 0)
          final w = _ease(_t / _lead);
          ankle = _backAnkle.lerp(_contactAnkle, w);
          toe = ankle + (_contactToe - _contactAnkle) * w;
          lean = _lean * w;
        } else {
          final w = _easeOut(((_t - _lead) / T.kickerFollowTime).clamp(0.0, 1.0));
          ankle = _contactAnkle.lerp(_followAnkle, w);
          toe = _contactToe.lerp(_followToe, w);
          lean = _lean * (1 - 0.5 * w);
        }
      case KickerPhase.recover:
        final w = _ease((_t / T.kickerRecoverTime).clamp(0.0, 1.0));
        final rest = _ankleKick(0);
        ankle = _fromAnkle.lerp(rest, w);
        toe = _fromToe.lerp(rest + _flatToe * T.kickerFootLen, w);
        action = 1 - w;
        lean = _lean * 0.5 * (1 - w);
    }

    final plant = _anklePlant();
    final plantToe = plant + const Vec3(0, -0.05, -1).normalized() * T.kickerFootLen;

    final hipK = _hip(s), hipP = _hip(-s);
    var kick = _leg(hipK, ankle, toe ?? ankle);
    if (toe == null) {
      // klid: špička vodorovně dopředu; nápřah: pokračuje směrem holeně
      final shin = (kick.ankle - kick.knee).normalized();
      final dir = _flatToe.lerp(shin, _ease(_windup)).normalized();
      kick = (knee: kick.knee, ankle: kick.ankle, toe: kick.ankle + dir * T.kickerFootLen);
    }
    final stand = _leg(hipP, plant, plantToe);

    // trup: náklon vpřed/vzad + odklon od kopací nohy při akci
    final up = Vec3(-s * 0.18 * action, math.cos(lean), -math.sin(lean)).normalized();
    final neck = _pelvis + up * T.kickerTorso;
    final head = neck + up * (0.08 + T.kickerHeadRadius);
    final shL = neck - _right() * T.kickerShoulderHalfWidth;
    final shR = neck + _right() * T.kickerShoulderHalfWidth;

    // ruce: klid = podél těla; akce = ruka stojné strany do strany
    // (rovnováha), ruka kopací strany dozadu
    (Vec3, Vec3) arm(Vec3 sh, double armSide) {
      final balancing = armSide != s; // stojná strana
      final elbowRest = sh + Vec3(armSide * 0.06, -T.kickerUpperArm, 0.02);
      final handRest = elbowRest + Vec3(0, -T.kickerForearm, -0.04);
      final elbowAct = balancing
          ? sh + Vec3(armSide * 0.27, -0.1, -0.06)
          : sh + Vec3(armSide * 0.06, -0.24, 0.16);
      final handAct = balancing
          ? elbowAct + Vec3(armSide * 0.24, 0.06, -0.1)
          : elbowAct + Vec3(0, -0.18, 0.2);
      return (elbowRest.lerp(elbowAct, action), handRest.lerp(handAct, action));
    }

    final (elL, haL) = arm(shL, -1);
    final (elR, haR) = arm(shR, 1);
    final right = s > 0;
    return {
      Joint.head: head, Joint.neck: neck, Joint.pelvis: _pelvis,
      Joint.shoulderL: shL, Joint.shoulderR: shR,
      Joint.elbowL: elL, Joint.elbowR: elR, Joint.handL: haL, Joint.handR: haR,
      Joint.hipL: right ? hipP : hipK, Joint.hipR: right ? hipK : hipP,
      Joint.kneeL: right ? stand.knee : kick.knee,
      Joint.kneeR: right ? kick.knee : stand.knee,
      Joint.ankleL: right ? stand.ankle : kick.ankle,
      Joint.ankleR: right ? kick.ankle : stand.ankle,
      Joint.toeL: right ? stand.toe : kick.toe,
      Joint.toeR: right ? kick.toe : stand.toe,
    };
  }

  static final _flatToe = const Vec3(0, -0.15, -1).normalized();

  static double _easeOut(double t) => 1 - (1 - t) * (1 - t);

  /// Dvoukloubové IK: koleno v rovině kyčel–kotník, ohnuté dopředu. Mimo
  /// dosah se kotník (i špička) přitáhne ke kyčli — noha prostě nedosáhne.
  ({Vec3 knee, Vec3 ankle, Vec3 toe}) _leg(Vec3 hip, Vec3 ankle, Vec3 toe) {
    const l1 = T.kickerThigh, l2 = T.kickerShin;
    final d = ankle - hip;
    final len = d.length.clamp(0.05, l1 + l2 - 1e-4);
    final dir = d.length > 1e-6 ? d / d.length : const Vec3(0, -1, 0);
    final reached = hip + dir * len;
    final shift = reached - ankle;
    final a = (l1 * l1 - l2 * l2 + len * len) / (2 * len);
    final h = math.sqrt(math.max(0.0, l1 * l1 - a * a));
    const pole = Vec3(0, 0.15, -1);
    var p = pole - dir * pole.dot(dir);
    p = p.length > 1e-6 ? p.normalized() : const Vec3(0, 0, -1);
    return (knee: hip + dir * a + p * h, ankle: reached, toe: toe + shift);
  }
}
