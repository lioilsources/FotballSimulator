extends Node3D
## Vykreslení procedurálního fotbalisty (Kicker) — kapsle mezi klouby,
## trup a trenýrky jako boxy, hlava koule. Póza se čte každý snímek;
## při freeze-frame (paused strom) stojí na snímku kontaktu.
## Barvy a tloušťky odpovídají Flutter ScenePainter._kicker.

const T := preload("res://scripts/util/tuning.gd")

const SKIN := Color(0.88, 0.67, 0.53)
const JERSEY := Color(0.78, 0.19, 0.16)
const SHORTS := Color(0.95, 0.95, 0.95)
const SOCK := Color(0.78, 0.19, 0.16)
const BOOT := Color(0.11, 0.11, 0.12)
const HAIR := Color(0.23, 0.16, 0.12)

## [kloub a, kloub b, průměr, barva, horní barva, podíl horní části]
const SEGMENTS := [
	["hipL", "kneeL", 0.15, SKIN, SHORTS, 0.55],
	["kneeL", "ankleL", 0.11, SOCK, SKIN, 0.2],
	["ankleL", "toeL", 0.095, BOOT, null, 0.0],
	["hipR", "kneeR", 0.15, SKIN, SHORTS, 0.55],
	["kneeR", "ankleR", 0.11, SOCK, SKIN, 0.2],
	["ankleR", "toeR", 0.095, BOOT, null, 0.0],
	["shoulderL", "elbowL", 0.095, SKIN, JERSEY, 0.5],
	["elbowL", "handL", 0.08, SKIN, null, 0.0],
	["shoulderR", "elbowR", 0.095, SKIN, JERSEY, 0.5],
	["elbowR", "handR", 0.08, SKIN, null, 0.0],
	["neck", "head", 0.09, SKIN, null, 0.0],
]

var kicker: Kicker

## jeden kus = {mesh: MeshInstance3D, a, b, from, to} (from/to = podíl kosti)
var _pieces: Array[Dictionary] = []
var _torso: MeshInstance3D
var _shorts: MeshInstance3D
var _head: MeshInstance3D
var _materials: Array[StandardMaterial3D] = []

func _ready() -> void:
	for seg in SEGMENTS:
		var split: float = seg[5]
		if seg[4] != null and split > 0.0:
			_add_piece(seg[0], seg[1], seg[2], seg[4], 0.0, split)
			_add_piece(seg[0], seg[1], seg[2], seg[3], split, 1.0)
		else:
			_add_piece(seg[0], seg[1], seg[2], seg[3], 0.0, 1.0)
	_torso = _box(Vector3(2.0 * T.KICKER_SHOULDER_HALF_WIDTH + 0.06, 1.0, 0.22), JERSEY)
	_shorts = _box(Vector3(2.0 * T.KICKER_HIP_HALF_WIDTH + 0.16, 0.2, 0.24), SHORTS)
	_head = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = T.KICKER_HEAD_RADIUS
	sphere.height = 2.0 * T.KICKER_HEAD_RADIUS
	sphere.material = _mat(HAIR)  # zezadu je vidět hlavně účes
	_head.mesh = sphere
	add_child(_head)

func _process(_delta: float) -> void:
	if kicker == null:
		return
	var p: Dictionary = kicker.pose()
	for piece in _pieces:
		var a: Vector3 = p[piece.a]
		var b: Vector3 = p[piece.b]
		_place(piece.mesh, a.lerp(b, piece.from), a.lerp(b, piece.to))
	# trup: pánev → krk, šířka ramen
	_place_box(_torso, p.pelvis, p.neck)
	var hips: Vector3 = (p.hipL + p.hipR) * 0.5
	_shorts.global_position = hips + Vector3(0, -0.02, 0)
	_head.global_position = p.head
	# duch, dokud míč přilétá (nezakrýt timing); od úderu plně vidět
	var alpha := kicker.opacity
	for m in _materials:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if alpha < 0.999 \
				else BaseMaterial3D.TRANSPARENCY_DISABLED
		m.albedo_color.a = alpha

func _add_piece(a: String, b: String, width: float, color: Color,
		from: float, to: float) -> void:
	var mi := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = width * 0.5
	capsule.material = _mat(color)
	mi.mesh = capsule
	add_child(mi)
	_pieces.append({"mesh": mi, "a": a, "b": b, "from": from, "to": to})

## Kapsle osou Y z a do b (výška vč. polokoulí; mesh je unikátní per kus).
func _place(mi: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var capsule := mi.mesh as CapsuleMesh
	var len := a.distance_to(b)
	capsule.height = maxf(len + 2.0 * capsule.radius, 2.0 * capsule.radius + 0.001)
	mi.global_transform = Transform3D(_basis_y(b - a), (a + b) * 0.5)

## Box trupu: střed mezi a a b, osa Y podél a→b, výška = vzdálenost.
func _place_box(mi: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var basis := _basis_y(b - a)
	mi.global_transform = Transform3D(basis.scaled_local(Vector3(1, a.distance_to(b), 1)),
			(a + b) * 0.5)

## Ortonormální báze s osou Y ve směru dir (X drží co nejblíž světové X).
static func _basis_y(dir: Vector3) -> Basis:
	var y := dir.normalized() if dir.length() > 1e-6 else Vector3.UP
	var x := Vector3.RIGHT - y * Vector3.RIGHT.dot(y)
	x = x.normalized() if x.length() > 1e-6 else Vector3.FORWARD
	var z := x.cross(y)
	return Basis(x, y, z)

func _box(size: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	box.material = _mat(color)
	mi.mesh = box
	add_child(mi)
	return mi

func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.8
	_materials.append(m)
	return m
