class_name Kicker
extends RefCounted
## Procedurální fotbalista (vizuální zpětná vazba kopu) — 1:1 port
## flutter_app/lib/core/kicker.dart, pózy hlídá tests/golden_test.gd.
##
## Fáze: postoj (dojde za ideální bod kontaktu) → nápřah (drží se prst) →
## úder (puštění; nárt v SKUTEČNÉM kontaktním bodě — pozdě = nad středem
## míče, brzy = pod ním, MISS = kope do místa, kde měl míč být) →
## dokopnutí ve směru výkopu → návrat. Běží v herním čase: freeze-frame
## drží snímek kontaktu, slow-mo zpomalí nápřah.
##
## Gameplay se nemění — kontakt je okamžitý při puštění. Pro „opravdový
## švih“ (ROADMAP D3) stačí volat strike() s lead > 0: noha pak animuje
## došvih z nápřahu do kontaktu, a kontakt v game_state se posune o stejný čas.
## Čistá třída bez scény — vykreslení řeší kicker_view.gd.

const T := preload("res://scripts/util/tuning.gd")

enum Foot { RIGHT, LEFT }
enum Phase { STANCE, WINDUP, STRIKE, RECOVER }

## Kosti pro vykreslení (dvojice jmen kloubů, stejné jako v Dartu).
const BONES := [
	["pelvis", "neck"], ["shoulderL", "shoulderR"], ["hipL", "hipR"],
	["shoulderL", "elbowL"], ["elbowL", "handL"],
	["shoulderR", "elbowR"], ["elbowR", "handR"],
	["hipL", "kneeL"], ["kneeL", "ankleL"], ["ankleL", "toeL"],
	["hipR", "kneeR"], ["kneeR", "ankleR"], ["ankleR", "toeR"],
]

const FLAT_TOE := Vector3(0, -0.15, -1)  # normalizuje se při použití
const STRIKE_FOOT_DIR := Vector3(0, -0.93, -0.37)  # propnutý kotník při kontaktu
const WINDUP_SHIFT := Vector3(0, -0.05, -0.12)  # nápřah: krok k míči, podřep
## Hranice fází s tolerancí: čas je součet ticků a 0.35 s po 42 tickách
## vyjde podle zaokrouhlení těsně pod/nad (JSON dt v Godotu o 2 ULP jinak).
const EPS := 1e-9

var foot: Foot = Foot.RIGHT
var phase: Phase = Phase.STANCE

var _target := Vector3(0, T.IDEAL_KICK_HEIGHT, -1.8)  # ideální střed míče
var _pelvis := Vector3.ZERO
var _placed := false
var _t := 0.0          # čas ve fázi (herní)
var _windup := 0.0     # 0..1 nápřah
var _lead := 0.0       # došvih před kontaktem (0 = okamžitý kontakt)

# úder
var _contact_ankle := Vector3.ZERO
var _contact_toe := Vector3.ZERO
var _follow_ankle := Vector3.ZERO
var _follow_toe := Vector3.ZERO
var _back_ankle := Vector3.ZERO  # kde byla noha v nápřahu (stopa švihu)
var _lean := 0.0                 # náklon trupu vpřed (+) / vzad (−), rad
# pro návrat: póza na konci dokopnutí
var _from_ankle := Vector3.ZERO
var _from_toe := Vector3.ZERO

## Průhledný, dokud míč přilétá — hráč stojí mezi kamerou a míčem a
## nesmí zakrýt timing. Od úderu plně vidět (zpětná vazba kontaktu).
var ghost := true
var opacity := T.KICKER_GHOST_ALPHA

func _init(f: Foot = Foot.RIGHT) -> void:
	foot = f

## Střed míče v ideálním okamžiku kontaktu aktuálního serve.
func ideal_ball() -> Vector3:
	return _target

## +1 kope pravou (+x), −1 levou.
func side() -> float:
	return 1.0 if foot == Foot.RIGHT else -1.0

## Stopa švihu: {from, to, age 0..1}, nebo {} = nekreslit.
func swoosh() -> Dictionary:
	if phase != Phase.STRIKE or _t > T.KICKER_SWOOSH_TIME + EPS:
		return {}
	return {"from": _back_ankle, "to": _contact_ankle, "age": _t / T.KICKER_SWOOSH_TIME}

# ── události ──────────────────────────────────────────────────

## Nový serve: ideal = střed míče v ideálním okamžiku kontaktu.
func on_serve(ideal: Vector3) -> void:
	_target = ideal
	ghost = true
	if not _placed:
		_pelvis = _stance_pelvis()
		_placed = true
	if phase != Phase.RECOVER:
		_enter(Phase.STANCE)

func windup() -> void:
	if phase == Phase.STANCE:
		_enter(Phase.WINDUP)

func cancel_windup() -> void:
	if phase == Phase.WINDUP:
		_enter(Phase.STANCE)

## Úder: contact = bod na plášti míče (svět), normal_out = směr ze středu
## míče ke kontaktu, kick_vel = výsledná rychlost míče (pro dokopnutí).
func strike(contact: Vector3, normal_out: Vector3, kick_vel: Vector3,
		power: float, lead := 0.0) -> void:
	_back_ankle = _ankle_kick(_windup)  # aktuální poloha (nápřah, nebo postoj)
	_lead = lead

	# nárt přiložený zvenku na plášť, špička dolů-dopředu (propnutý kotník)
	var instep := contact + normal_out * 0.045
	_contact_ankle = instep - STRIKE_FOOT_DIR * 0.09
	_contact_toe = instep + STRIKE_FOOT_DIR * (T.KICKER_FOOT_LEN - 0.09)

	# dokopnutí: noha pokračuje ve směru výkopu, výš při silném/podebraném
	# kopu, mírně přes tělo (na stranu stojné nohy)
	var speed := kick_vel.length()
	var dir := kick_vel / speed if speed > 0.01 else Vector3(0, 0, -1)
	var flat := Vector3(dir.x, 0, dir.z).normalized()
	var p := clampf(power, 0.0, 1.0)
	_follow_ankle = _contact_ankle + flat * (0.25 + 0.3 * p) \
			+ Vector3.UP * (0.12 + 0.35 * p * (0.5 + maxf(0.0, dir.y))) \
			+ Vector3(-side() * 0.08, 0, 0)
	_follow_toe = _follow_ankle \
			+ (flat + Vector3(0, 0.2, 0)).normalized() * T.KICKER_FOOT_LEN

	# trup: zásah nad středem (pozdě) = přes míč dopředu, pod střed = záklon
	_lean = 0.12 + 0.35 * clampf(normal_out.y, -1.0, 1.0)
	ghost = false
	opacity = 1.0
	_enter(Phase.STRIKE)

# ── simulace ──────────────────────────────────────────────────

func update(dt: float) -> void:
	_t += dt
	var target_opacity := T.KICKER_GHOST_ALPHA if ghost else 1.0
	opacity += (target_opacity - opacity) * (1.0 - exp(-T.KICKER_FADE_RATE * dt))
	# pánev dojíždí do postoje za aktuální ideál (serve míč se pohybuje)
	var goal := _stance_pelvis() + WINDUP_SHIFT * _windup
	_pelvis = _pelvis.lerp(goal, 1.0 - exp(-T.KICKER_FOLLOW_RATE * dt))

	match phase:
		Phase.WINDUP:
			_windup = minf(1.0, _windup + dt / T.KICKER_WINDUP_TIME)
		Phase.STANCE:
			_windup = maxf(0.0, _windup - dt / T.KICKER_WINDUP_TIME)
		Phase.STRIKE:
			if _t >= _lead + T.KICKER_FOLLOW_TIME - EPS:
				_from_ankle = _follow_ankle
				_from_toe = _follow_toe
				_enter(Phase.RECOVER)
		Phase.RECOVER:
			_windup = maxf(0.0, _windup - dt / T.KICKER_RECOVER_TIME)
			if _t >= T.KICKER_RECOVER_TIME - EPS:
				_enter(Phase.STANCE)

func _enter(p: Phase) -> void:
	phase = p
	_t = 0.0

# ── geometrie ─────────────────────────────────────────────────

func _stance_pelvis() -> Vector3:
	return Vector3(_target.x - side() * T.KICKER_STAND_SIDE, T.KICKER_HIP_HEIGHT,
			_target.z + T.KICKER_STAND_BACK)

func _hip(s: float) -> Vector3:
	return _pelvis + Vector3.RIGHT * (s * T.KICKER_HIP_HALF_WIDTH)

## Kotník kopací nohy mimo úder: postoj ↔ nápřah (pata vzadu nahoře).
func _ankle_kick(w: float) -> Vector3:
	var hip := _hip(side())
	var rest := Vector3(hip.x + side() * 0.05, 0.08, _pelvis.z + 0.12)
	var back := hip + Vector3(side() * 0.04, -0.42, 0.5)
	return rest.lerp(back, _ease(w))

func _ankle_plant() -> Vector3:
	var rest := Vector3(_pelvis.x - side() * 0.14, 0.08, _pelvis.z - 0.02)
	var plant := Vector3(_target.x - side() * T.KICKER_PLANT_SIDE, 0.08, _target.z + 0.15)
	var w := 1.0 if phase == Phase.STRIKE else _ease(_windup)
	return rest.lerp(plant, w)

static func _ease(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)

static func _ease_out(t: float) -> float:
	return 1.0 - (1.0 - t) * (1.0 - t)

## Aktuální póza kostry (svět): {jméno kloubu: Vector3}.
func pose() -> Dictionary:
	var s := side()
	var flat_toe := FLAT_TOE.normalized()
	# kopací noha: kotník + špička
	var ankle: Vector3
	var toe = null  # null = propnutá špička ve směru holeně (dopočítá se po IK)
	var action := _ease(_windup)  # 0 = klid, 1 = akce (ruce do rovnováhy)
	var lean := 0.0
	match phase:
		Phase.STANCE, Phase.WINDUP:
			ankle = _ankle_kick(_windup)
		Phase.STRIKE:
			action = 1.0
			if _t < _lead:
				# došvih (jen při lead > 0)
				var w := _ease(_t / _lead)
				ankle = _back_ankle.lerp(_contact_ankle, w)
				toe = ankle + (_contact_toe - _contact_ankle) * w
				lean = _lean * w
			else:
				var w := _ease_out(clampf((_t - _lead) / T.KICKER_FOLLOW_TIME, 0.0, 1.0))
				ankle = _contact_ankle.lerp(_follow_ankle, w)
				toe = _contact_toe.lerp(_follow_toe, w)
				lean = _lean * (1.0 - 0.5 * w)
		Phase.RECOVER:
			var w := _ease(clampf(_t / T.KICKER_RECOVER_TIME, 0.0, 1.0))
			var rest := _ankle_kick(0.0)
			ankle = _from_ankle.lerp(rest, w)
			toe = _from_toe.lerp(rest + flat_toe * T.KICKER_FOOT_LEN, w)
			action = 1.0 - w
			lean = _lean * 0.5 * (1.0 - w)

	var plant := _ankle_plant()
	var plant_toe := plant + Vector3(0, -0.05, -1).normalized() * T.KICKER_FOOT_LEN

	var hip_k := _hip(s)
	var hip_p := _hip(-s)
	var kick := _leg(hip_k, ankle, toe if toe != null else ankle)
	if toe == null:
		# klid: špička vodorovně dopředu; nápřah: pokračuje směrem holeně
		var shin: Vector3 = (kick.ankle - kick.knee).normalized()
		var dir := flat_toe.lerp(shin, _ease(_windup)).normalized()
		kick.toe = kick.ankle + dir * T.KICKER_FOOT_LEN
	var stand := _leg(hip_p, plant, plant_toe)

	# trup: náklon vpřed/vzad + odklon od kopací nohy při akci
	var up := Vector3(-s * 0.18 * action, cos(lean), -sin(lean)).normalized()
	var neck := _pelvis + up * T.KICKER_TORSO
	var head := neck + up * (0.08 + T.KICKER_HEAD_RADIUS)
	var sh_l := neck - Vector3.RIGHT * T.KICKER_SHOULDER_HALF_WIDTH
	var sh_r := neck + Vector3.RIGHT * T.KICKER_SHOULDER_HALF_WIDTH
	var arm_l := _arm(sh_l, -1.0, s, action)
	var arm_r := _arm(sh_r, 1.0, s, action)

	var right := s > 0.0
	return {
		"head": head, "neck": neck, "pelvis": _pelvis,
		"shoulderL": sh_l, "shoulderR": sh_r,
		"elbowL": arm_l[0], "elbowR": arm_r[0], "handL": arm_l[1], "handR": arm_r[1],
		"hipL": hip_p if right else hip_k, "hipR": hip_k if right else hip_p,
		"kneeL": stand.knee if right else kick.knee,
		"kneeR": kick.knee if right else stand.knee,
		"ankleL": stand.ankle if right else kick.ankle,
		"ankleR": kick.ankle if right else stand.ankle,
		"toeL": stand.toe if right else kick.toe,
		"toeR": kick.toe if right else stand.toe,
	}

## Ruka: klid = podél těla; akce = ruka stojné strany do strany
## (rovnováha), ruka kopací strany dozadu. Vrací [loket, dlaň].
static func _arm(sh: Vector3, arm_side: float, s: float, action: float) -> Array:
	var balancing := arm_side != s  # stojná strana
	var elbow_rest := sh + Vector3(arm_side * 0.06, -T.KICKER_UPPER_ARM, 0.02)
	var hand_rest := elbow_rest + Vector3(0, -T.KICKER_FOREARM, -0.04)
	var elbow_act := sh + (Vector3(arm_side * 0.27, -0.1, -0.06) if balancing
			else Vector3(arm_side * 0.06, -0.24, 0.16))
	var hand_act := elbow_act + (Vector3(arm_side * 0.24, 0.06, -0.1) if balancing
			else Vector3(0, -0.18, 0.2))
	return [elbow_rest.lerp(elbow_act, action), hand_rest.lerp(hand_act, action)]

## Dvoukloubové IK: koleno v rovině kyčel–kotník, ohnuté dopředu. Mimo
## dosah se kotník (i špička) přitáhne ke kyčli — noha prostě nedosáhne.
static func _leg(hip: Vector3, ankle: Vector3, toe: Vector3) -> Dictionary:
	var l1 := T.KICKER_THIGH
	var l2 := T.KICKER_SHIN
	var d := ankle - hip
	var len := clampf(d.length(), 0.05, l1 + l2 - 1e-4)
	var dir := d / d.length() if d.length() > 1e-6 else Vector3(0, -1, 0)
	var reached := hip + dir * len
	var shift := reached - ankle
	var a := (l1 * l1 - l2 * l2 + len * len) / (2.0 * len)
	var h := sqrt(maxf(0.0, l1 * l1 - a * a))
	var pole := Vector3(0, 0.15, -1)
	var p := pole - dir * pole.dot(dir)
	p = p.normalized() if p.length() > 1e-6 else Vector3(0, 0, -1)
	return {"knee": hip + dir * a + p * h, "ankle": reached, "toe": toe + shift}
