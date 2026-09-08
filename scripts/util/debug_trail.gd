extends MeshInstance3D
## Debug trail letu (Fáze 0, VOLLEY_PLAN.md §7): line strip za míčem ve
## world space. top_level, aby ho nerotoval/neposouval rodičovský míč.

const MAX_POINTS := 600

var _points := PackedVector3Array()
var _ball: BallPhysics

func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	mesh = ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.45, 0.1)
	material_override = mat
	_ball = get_parent() as BallPhysics

func _physics_process(_delta: float) -> void:
	if _ball == null or not _ball.flying:
		return
	_points.append(_ball.global_position)
	if _points.size() > MAX_POINTS:
		_points = _points.slice(_points.size() - MAX_POINTS)
	_rebuild()

func clear_trail() -> void:
	_points.clear()
	_rebuild()

func _rebuild() -> void:
	var im := mesh as ImmediateMesh
	im.clear_surfaces()
	if _points.size() < 2:
		return
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for p in _points:
		im.surface_add_vertex(p)
	im.surface_end()
