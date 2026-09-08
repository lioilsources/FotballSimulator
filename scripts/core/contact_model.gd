class_name ContactModel
extends RefCounted
## ⭐ Jádro hry (VOLLEY_PLAN.md §3.4): čistá funkce nárt × míč → rychlost + spin.
## Pracuje v lokálním rámci kopu: -z = směr na bránu, +x = doprava (z pohledu
## hráče), +y = nahoru. Převod do světa dělá volající (game_state).
## Žádné závislosti na scéně ani autoloadech — headless testovatelné.

const T := preload("res://scripts/util/tuning.gd")

enum Rating { PERFECT, GOOD, EARLY, LATE, MISS }

## contact_offset: kde na míči (-1..1 od středu, +x vpravo, +y nahoře);
## swing_curve: zakřivení swipu -1..1 (+ = oblouk doprava);
## power: 0..1 z rychlosti swipu;
## timing_error: sekundy od ideálního okamžiku, kladné = pozdě.
##
## Vrací {hit, rating, vel, omega, timing_quality, v_foot, contact_dir}.
static func compute_kick(contact_offset: Vector2, swing_curve: float,
		power: float, timing_error: float) -> Dictionary:
	var rating := rate_timing(timing_error)
	if rating == Rating.MISS:
		# nárt mine — míč letí dál, žádný impuls
		return {
			"hit": false, "rating": rating, "vel": Vector3.ZERO,
			"omega": Vector3.ZERO, "timing_quality": 0.0, "v_foot": 0.0,
			"contact_dir": Vector3.ZERO,
		}

	# §3.4/6 — pozdě: míč už klesl pod záměr, nárt ho trefí VÝŠ na plášti →
	# normála míří dolů dopředu → topspin a nízká dráha ("nedoletí").
	# Brzy symetricky POD míč → vyšší, slabší oblouk. (Plán má ve vzorci
	# `-=`, ale text říká "posouvá NAHORU" — text je záměr, znaménko překlep.)
	var off := contact_offset
	off.y += T.LATE_SHIFT * clampf(timing_error / T.TIMING_WINDOW, -1.0, 1.0)
	off = off.limit_length(0.95)  # kontakt musí zůstat na míči

	# 1–2: kvalita timingu → rychlost nártu
	var timing_quality := exp(-pow(timing_error / T.TIMING_SIGMA, 2.0))
	var v_foot := T.FOOT_SPEED_MAX * power * timing_quality

	# 3: kontaktní bod na přivrácené polokouli (+z strana), normála skrz střed
	var u := Vector3(off.x, off.y,
			sqrt(maxf(0.0, 1.0 - off.length_squared()))).normalized()
	var n := -u

	# dráha nártu: dopředu s mírným zdvihem; energii předává jen složka
	# podél normály — extrémní offsety = slabší, ale točivější zásah
	var swing_dir := Vector3(0, T.SWING_LIFT, -1).normalized()
	var normal_speed := v_foot * maxf(0.0, swing_dir.dot(n))

	# 4: impuls → rychlost míče (§3.4/4)
	var vel := n * (normal_speed * T.COR_KICK * T.FOOT_MASS_EFF / T.BALL_MASS)

	# 5: faleš — tření táhne plášť po tangenciální složce švihu; osa spinu
	# je u × t (odvozeno z τ = r×F; plánův tvar swing×d má pro tuhle
	# geometrii obrácenou orientaci). Emergentně: zásah vpravo → míč letí
	# doleva se spinem, který ho Magnusem vrací doprava (banán kolem zdi);
	# zdvih švihu skrz střed dává mírný topspin (přirozený dip nártové rány).
	var t_vec := swing_dir - swing_dir.dot(n) * n
	var omega := T.SPIN_TRANSFER * v_foot * u.cross(t_vec)
	# zakřivení swipu: oblouk doprava (+) ⇒ faleš doprava ⇒ spin kolem -y
	omega += T.CURVE_SPIN * v_foot * swing_curve * Vector3.DOWN

	return {
		"hit": true, "rating": rating, "vel": vel, "omega": omega,
		"timing_quality": timing_quality, "v_foot": v_foot,
		"contact_dir": u,
	}

## §3.5: perfect < 30 ms, good < 70 ms, late/early < 120 ms, jinak miss.
static func rate_timing(timing_error: float) -> Rating:
	var e := absf(timing_error)
	if e < T.RATING_PERFECT:
		return Rating.PERFECT
	if e < T.RATING_GOOD:
		return Rating.GOOD
	if e < T.RATING_LATE_EARLY:
		return Rating.LATE if timing_error > 0.0 else Rating.EARLY
	return Rating.MISS
