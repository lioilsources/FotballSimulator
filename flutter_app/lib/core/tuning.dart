import 'dart:math' as math;

import 'vec3.dart';

/// Krátký alias jako `const T` v GDScriptu.
typedef T = Tuning;

/// VŠECHNY herní konstanty na jednom místě (port `scripts/util/tuning.gd`,
/// VOLLEY_PLAN.md §3). Hodnoty musí zůstat synchronní s Godot verzí.
abstract final class Tuning {
  // ── Míč (FIFA size 5) ─────────────────────────────────────────
  static const ballRadius = 0.11; // m
  static const ballMass = 0.43; // kg
  static const ballArea = math.pi * ballRadius * ballRadius; // průřez pro drag

  // ── Let (ball_physics, §3.2) ──────────────────────────────────
  static const gravity = Vec3(0, -9.81, 0);
  static const rho = 1.225; // hustota vzduchu kg/m³
  static const cd = 0.25; // drag koeficient (turbulentní obtékání)
  static const sCoeff = 0.0021; // Magnusův koeficient — ladit pocitově, ne fyzikálně!
  static const spinDecay = 0.15; // exponenciální útlum spinu za sekundu

  // ── Odskok (§3.3) ─────────────────────────────────────────────
  static const restitution = 0.62; // tráva
  static const groundFriction = 0.2; // ztráta horizontální rychlosti na odskok
  static const bounceSpinTransfer = 0.35; // kolik obvodové rychlosti spinu se propíše do xz
  static const bounceSpinRetain = 0.7; // kolik spinu odskok přežije
  static const bounceMinVy = 0.5; // slabší rebound už není odskok, ale kutálení
  static const rollFriction = 1.2; // exponenciální útlum rychlosti při kutálení /s
  static const stopSpeed = 0.3; // pod tímhle míč "usne" → ballStopped

  // ── Kontakt (contact_model, §3.4) ─────────────────────────────
  static const timingSigma = 0.045; // s; šířka gaussovky kvality timingu
  static const timingWindow = 0.12; // s; za tímhle už nárt mine
  static const footSpeedMax = 28.0; // m/s při plné síle a perfektním timingu
  static const footRadius = 0.05; // m; kapsle nártu
  static const footMassEff = 0.63; // m_eff → max výkop ~33 m/s (~120 km/h)
  static const corKick = 0.8;
  static const swingLift = 0.3; // zdvih dráhy nártu (y složka swing_dir)
  static const spinTransfer = 3.0; // faleš z offsetu: omega = ST · v_foot · (u × t)
  static const curveSpin = 2.0; // faleš ze zakřivení swipu
  static const lateShift = 0.35; // posun kontaktu nahoru při pozdním timingu (§3.4/6)

  // ── Timing rating (§3.5, absolutní |error| v s) ───────────────
  static const ratingPerfect = 0.03;
  static const ratingGood = 0.07;
  static const ratingLateEarly = 0.12;

  // ── Timing okno (§3.5) ────────────────────────────────────────
  static const idealKickHeight = 0.55; // m; ideál = míč klesá skrz tuhle výšku

  // ── Swipe input (§4) ──────────────────────────────────────────
  static const swipeDeadzonePx = 8.0; // mikrotřes se nepočítá jako swipe
  static const swipeMinLengthPx = 40.0; // kratší tah = zrušené gesto
  static const swipeMinDuration = 0.02; // s; kratší = šum, ne gesto
  static const swipeSampleMinPx = 2.0; // posun prstu menší než tohle se nevzorkuje
  static const swipeMaxPoints = 256; // strop vzorků dráhy (dlouhý drag v slow-mo)
  static const swipePowerFullIns = 12.0; // rychlost prstu v palcích/s = plná síla
  static const logicalDpi = 160.0; // Flutter logical px ≈ 1/160 palce (Android i iOS)
  static const overlayBallScreenFrac = 0.35; // průměr overlay míče vůči šířce obrazovky
  static const assistDefault = true; // slow-mo od touch-down
  static const assistSlowmo = 0.6;

  // ── Prezentace (§5) ───────────────────────────────────────────
  static const freezeTime = 0.15; // s reálného času; freeze-frame kontaktu
  static const hudFadeDelay = 2.5; // s; jak dlouho drží kick overlay
  static const hudFadeTime = 0.5;
  static const resultPause = 1.4; // s herního času mezi výsledkem a dalším serve
  static const trailMaxPoints = 600;

  // ── Hřiště / brána ────────────────────────────────────────────
  static const goalDistance = 18.0; // m od hráče (origin)
  static const goalHalfWidth = 3.66; // vnitřní polovina šířky brány
  static const goalHeight = 2.44;
  static const goalPostRadius = 0.06;
  static const goalDepth = 2.0; // hloubka sítě (jen vizuál, kolize = Fáze 2)

  // ── Kamera (main.tscn) ────────────────────────────────────────
  static const cameraPos = Vec3(0, 1.4, 3.2);
  static const cameraPitch = -0.06; // rad kolem x
  static const cameraFovDeg = 55.0; // vertikální
  // portrait: s čistě vertikálním FOV by míč v kop-zóně (|x| až ~1.1 m)
  // utíkal ze záběru → minimální horizontální FOV + posun středu obrazu
  // (lens shift) nahoru, ať je víc trávníku a méně nebe
  static const cameraMinHFovDeg = 60.0;
  static const cameraCenterYFrac = 0.32; // optický střed v podílu výšky

  // ── Simulace ──────────────────────────────────────────────────
  static const physicsHz = 120;
  static const physicsDt = 1.0 / physicsHz;

  // ── Serve / debug (Fáze 0) ────────────────────────────────────
  static const serveSeed = -1; // -1 = náhodný seed (hra); pevný = replaye
  static const debugKickSpeed = 25.0; // m/s testovací kop
  static const debugKickAngleDeg = 35.0;
  static const debugSidespin = 50.0; // rad/s
  static const debugTopspin = 40.0; // rad/s
}
