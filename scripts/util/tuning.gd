extends Node
## VŠECHNY herní konstanty na jednom místě (VOLLEY_PLAN.md §3).
## Registrováno jako autoload "Tuning" — scénové skripty píšou Tuning.X.
## Čistě fyzikální skripty (ball_physics, serve_generator, později
## contact_model) si tenhle soubor místo toho preloadují jako `const T`,
## takže fungují i headless v testech (--script), nezávisle na autoloadech.

# ── Míč (FIFA size 5) ─────────────────────────────────────────
const BALL_RADIUS := 0.11            # m
const BALL_MASS := 0.43              # kg
const BALL_AREA := PI * BALL_RADIUS * BALL_RADIUS  # průřez pro drag

# ── Let (ball_physics.gd, §3.2) ───────────────────────────────
const GRAVITY := Vector3(0, -9.81, 0)
const RHO := 1.225                   # hustota vzduchu kg/m³
const CD := 0.25                     # drag koeficient (turbulentní obtékání)
const S_COEFF := 0.0021              # Magnusův koeficient — ladit pocitově, ne fyzikálně!
const SPIN_DECAY := 0.15             # exponenciální útlum spinu za sekundu

# ── Odskok (§3.3) ─────────────────────────────────────────────
const RESTITUTION := 0.62            # tráva
const GROUND_FRICTION := 0.2         # ztráta horizontální rychlosti na odskok
const BOUNCE_SPIN_TRANSFER := 0.35   # kolik obvodové rychlosti spinu se propíše do xz
const BOUNCE_SPIN_RETAIN := 0.7      # kolik spinu odskok přežije
const BOUNCE_MIN_VY := 0.5           # slabší rebound už není odskok, ale kutálení
const ROLL_FRICTION := 1.2           # exponenciální útlum rychlosti při kutálení /s
const STOP_SPEED := 0.3              # pod tímhle míč "usne" → ball_stopped

# ── Kontakt (contact_model.gd, §3.4) ──────────────────────────
const TIMING_SIGMA := 0.045          # s; šířka gaussovky kvality timingu
const TIMING_WINDOW := 0.12          # s; za tímhle už nárt mine
const FOOT_SPEED_MAX := 28.0         # m/s při plné síle a perfektním timingu
const FOOT_RADIUS := 0.05            # m; kapsle nártu
const FOOT_MASS_EFF := 0.63          # m_eff → max výkop ~33 m/s (~120 km/h)
const COR_KICK := 0.8
const SWING_LIFT := 0.3              # zdvih dráhy nártu (y složka swing_dir)
const SPIN_TRANSFER := 3.0           # faleš z offsetu: omega = ST · v_foot · (u × t)
const CURVE_SPIN := 2.0              # faleš ze zakřivení swipu (rad/s na m/s·jednotku)
const LATE_SHIFT := 0.35             # posun kontaktu nahoru při pozdním timingu (§3.4/6)

# ── Timing rating (§3.5, absolutní |error| v s) ───────────────
const RATING_PERFECT := 0.03
const RATING_GOOD := 0.07
const RATING_LATE_EARLY := 0.12

# ── Timing okno (§3.5) ────────────────────────────────────────
const IDEAL_KICK_HEIGHT := 0.55      # m; ideál = míč klesá skrz tuhle výšku

# ── Swipe input (§4) ──────────────────────────────────────────
const SWIPE_DEADZONE_PX := 8.0       # mikrotřes se nepočítá jako swipe
const SWIPE_MIN_LENGTH_PX := 40.0    # kratší tah = zrušené gesto
const SWIPE_MIN_DURATION := 0.02     # s; kratší = šum, ne gesto
const SWIPE_SAMPLE_MIN_PX := 2.0     # posun prstu menší než tohle se nevzorkuje
const SWIPE_MAX_POINTS := 256        # strop vzorků dráhy (dlouhý drag v slow-mo)
const SWIPE_POWER_FULL_INS := 12.0   # rychlost prstu v palcích/s = plná síla (DPI normalizace)
const OVERLAY_BALL_SCREEN_FRAC := 0.35  # průměr overlay míče vůči šířce obrazovky
const ASSIST_DEFAULT := true         # slow-mo od touch-down (klávesa A přepíná)
const ASSIST_SLOWMO := 0.6

# ── Prezentace (§5) ───────────────────────────────────────────
const FREEZE_TIME := 0.15            # s reálného času; freeze-frame kontaktu
const HUD_FADE_DELAY := 2.5          # s; jak dlouho drží kick overlay

# ── Hřiště / brána ────────────────────────────────────────────
# Bránu staví goal.gd z těchhle hodnot (tyče, břevno, umístění) — scéna
# pitch.tscn nemá žádné rozměry natvrdo.
const GOAL_DISTANCE := 18.0          # m od hráče (origin)
const GOAL_HALF_WIDTH := 3.66        # vnitřní polovina šířky brány
const GOAL_HEIGHT := 2.44            # spodní hrana břevna
const POST_RADIUS := 0.06            # tyče i břevno

# ── Serve / debug (Fáze 0) ────────────────────────────────────
const SERVE_SEED := 12345            # -1 = náhodný seed (hra); pevný = replaye
const DEBUG_KICK_SPEED := 25.0       # m/s testovací kop
const DEBUG_KICK_ANGLE_DEG := 35.0
const DEBUG_SIDESPIN := 50.0         # rad/s pro klávesu 2
const DEBUG_TOPSPIN := 40.0          # rad/s pro klávesu 3
