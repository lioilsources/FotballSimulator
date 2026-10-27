// Mapa konstant `scripts/util/tuning.gd` ↔ `lib/core/tuning.dart`.
// Používá ji tuning_sync_test (parsuje tuning.gd a porovná hodnoty) a
// golden_test (snapshot tuningu v shared/golden.json, který kontroluje
// Godot strana). Nová konstanta v jednom z tuning souborů = nový řádek tady,
// jinak tuning_sync_test selže.
import 'dart:io';

import 'package:fotball_simulator/core/tuning.dart';
import 'package:fotball_simulator/core/vec3.dart';

/// Godot jméno → (Dart jméno, Dart hodnota). Vec3 se porovnává po složkách.
final Map<String, (String, Object)> godotTuning = {
  'BALL_RADIUS': ('ballRadius', T.ballRadius),
  'BALL_MASS': ('ballMass', T.ballMass),
  'BALL_AREA': ('ballArea', T.ballArea),
  'GRAVITY': ('gravity', T.gravity),
  'RHO': ('rho', T.rho),
  'CD': ('cd', T.cd),
  'S_COEFF': ('sCoeff', T.sCoeff),
  'SPIN_DECAY': ('spinDecay', T.spinDecay),
  'RESTITUTION': ('restitution', T.restitution),
  'GROUND_FRICTION': ('groundFriction', T.groundFriction),
  'BOUNCE_SPIN_TRANSFER': ('bounceSpinTransfer', T.bounceSpinTransfer),
  'BOUNCE_SPIN_RETAIN': ('bounceSpinRetain', T.bounceSpinRetain),
  'BOUNCE_MIN_VY': ('bounceMinVy', T.bounceMinVy),
  'ROLL_FRICTION': ('rollFriction', T.rollFriction),
  'STOP_SPEED': ('stopSpeed', T.stopSpeed),
  'TIMING_SIGMA': ('timingSigma', T.timingSigma),
  'TIMING_WINDOW': ('timingWindow', T.timingWindow),
  'FOOT_SPEED_MAX': ('footSpeedMax', T.footSpeedMax),
  'FOOT_RADIUS': ('footRadius', T.footRadius),
  'FOOT_MASS_EFF': ('footMassEff', T.footMassEff),
  'COR_KICK': ('corKick', T.corKick),
  'SWING_LIFT': ('swingLift', T.swingLift),
  'SPIN_TRANSFER': ('spinTransfer', T.spinTransfer),
  'CURVE_SPIN': ('curveSpin', T.curveSpin),
  'LATE_SHIFT': ('lateShift', T.lateShift),
  'RATING_PERFECT': ('ratingPerfect', T.ratingPerfect),
  'RATING_GOOD': ('ratingGood', T.ratingGood),
  'RATING_LATE_EARLY': ('ratingLateEarly', T.ratingLateEarly),
  'IDEAL_KICK_HEIGHT': ('idealKickHeight', T.idealKickHeight),
  'SWIPE_DEADZONE_PX': ('swipeDeadzonePx', T.swipeDeadzonePx),
  'SWIPE_MIN_LENGTH_PX': ('swipeMinLengthPx', T.swipeMinLengthPx),
  'SWIPE_MIN_DURATION': ('swipeMinDuration', T.swipeMinDuration),
  'SWIPE_SAMPLE_MIN_PX': ('swipeSampleMinPx', T.swipeSampleMinPx),
  'SWIPE_MAX_POINTS': ('swipeMaxPoints', T.swipeMaxPoints),
  'SWIPE_POWER_FULL_INS': ('swipePowerFullIns', T.swipePowerFullIns),
  'OVERLAY_BALL_SCREEN_FRAC': ('overlayBallScreenFrac', T.overlayBallScreenFrac),
  'OVERLAY_BOTTOM_MARGIN_PX': ('overlayBottomMarginPx', T.overlayBottomMarginPx),
  'ASSIST_DEFAULT': ('assistDefault', T.assistDefault),
  'ASSIST_SLOWMO': ('assistSlowmo', T.assistSlowmo),
  'FREEZE_TIME': ('freezeTime', T.freezeTime),
  'HUD_FADE_DELAY': ('hudFadeDelay', T.hudFadeDelay),
  'HUD_FADE_TIME': ('hudFadeTime', T.hudFadeTime),
  'RESULT_PAUSE': ('resultPause', T.resultPause),
  'TRAIL_MAX_POINTS': ('trailMaxPoints', T.trailMaxPoints),
  'KICKER_THIGH': ('kickerThigh', T.kickerThigh),
  'KICKER_SHIN': ('kickerShin', T.kickerShin),
  'KICKER_FOOT_LEN': ('kickerFootLen', T.kickerFootLen),
  'KICKER_HIP_HEIGHT': ('kickerHipHeight', T.kickerHipHeight),
  'KICKER_HIP_HALF_WIDTH': ('kickerHipHalfWidth', T.kickerHipHalfWidth),
  'KICKER_TORSO': ('kickerTorso', T.kickerTorso),
  'KICKER_SHOULDER_HALF_WIDTH': ('kickerShoulderHalfWidth', T.kickerShoulderHalfWidth),
  'KICKER_UPPER_ARM': ('kickerUpperArm', T.kickerUpperArm),
  'KICKER_FOREARM': ('kickerForearm', T.kickerForearm),
  'KICKER_HEAD_RADIUS': ('kickerHeadRadius', T.kickerHeadRadius),
  'KICKER_STAND_BACK': ('kickerStandBack', T.kickerStandBack),
  'KICKER_STAND_SIDE': ('kickerStandSide', T.kickerStandSide),
  'KICKER_PLANT_SIDE': ('kickerPlantSide', T.kickerPlantSide),
  'KICKER_FOLLOW_RATE': ('kickerFollowRate', T.kickerFollowRate),
  'KICKER_WINDUP_TIME': ('kickerWindupTime', T.kickerWindupTime),
  'KICKER_FOLLOW_TIME': ('kickerFollowTime', T.kickerFollowTime),
  'KICKER_RECOVER_TIME': ('kickerRecoverTime', T.kickerRecoverTime),
  'KICKER_SWOOSH_TIME': ('kickerSwooshTime', T.kickerSwooshTime),
  'KICKER_GHOST_ALPHA': ('kickerGhostAlpha', T.kickerGhostAlpha),
  'KICKER_FADE_RATE': ('kickerFadeRate', T.kickerFadeRate),
  'GOAL_DISTANCE': ('goalDistance', T.goalDistance),
  'GOAL_HALF_WIDTH': ('goalHalfWidth', T.goalHalfWidth),
  'GOAL_HEIGHT': ('goalHeight', T.goalHeight),
  'POST_RADIUS': ('goalPostRadius', T.goalPostRadius),
  'FLIGHT_END_BEYOND_GOAL': ('flightEndBeyondGoal', T.flightEndBeyondGoal),
  'DEBUG_KICK_SPEED': ('debugKickSpeed', T.debugKickSpeed),
  'DEBUG_KICK_ANGLE_DEG': ('debugKickAngleDeg', T.debugKickAngleDeg),
  'DEBUG_SIDESPIN': ('debugSidespin', T.debugSidespin),
  'DEBUG_TOPSPIN': ('debugTopspin', T.debugTopspin),
};

/// Konstanty, které se mezi verzemi záměrně liší (jméno je v obou).
const intentionalDiff = {
  // RNG serve se mezi verzemi stejně neshoduje (PCG32 vs Godot RNG), Godot
  // drží pevný seed kvůli headless testům, Flutter hraje náhodně
  'SERVE_SEED': 'serveSeed',
};

/// Dart konstanty bez protějšku v tuning.gd — v Godotu žijí jinde.
const flutterOnly = {
  'logicalDpi', // Godot bere skutečné DPI ze Screen
  'goalDepth', // síť jen vizuálně; v Godotu přijde s verlet sítí
  'cameraPos', 'cameraPitch', 'cameraFovDeg', // Godot: Camera3D v main.tscn
  'cameraMinHFovDeg', 'cameraCenterYFrac', // portrait úprava jen ve Flutteru
  'physicsHz', // Godot: project.godot physics_ticks_per_second (kontroluje test)
  'physicsDt',
};

/// Snapshot tuningu pro golden.json: Godot jména, Vec3 jako [x, y, z].
Map<String, Object> tuningSnapshot() => {
      for (final MapEntry(:key, value: (_, v)) in godotTuning.entries)
        key: v is Vec3 ? [v.x, v.y, v.z] : v,
    };

/// Kořen repa (flutter test běží s cwd = flutter_app).
final repoRoot = Directory.current.parent.path;
