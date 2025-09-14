extends Node3D
class_name CameraPivotController

@export var camera_path: NodePath
@export var ground_y: float = 0.0
@export var rotate_sensitivity: float = 0.3
@export var min_ortho_size: float = 4.0
@export var max_ortho_size: float = 200.0
@export var zoom_step: float = 0.9

var _cam: Camera3D
var _panning := false
var _drag_plane := Plane(Vector3.UP, 0.0)

func _ready() -> void:
	_cam = get_node_or_null(camera_path) as Camera3D
	_drag_plane = Plane(Vector3.UP, ground_y)

func _unhandled_input(e: InputEvent) -> void:
	if _cam == null:
		return

	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_MIDDLE:
		_panning = e.pressed
		return

	if e is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		rotation_degrees.y += e.relative.x * rotate_sensitivity

	if e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			_cam.size = clamp(_cam.size * zoom_step, min_ortho_size, max_ortho_size)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_cam.size = clamp(_cam.size / zoom_step, min_ortho_size, max_ortho_size)

	if _panning:
		if e is InputEventScreenDrag:
			_pan_by_screen_delta(e.position, e.relative)
		elif e is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			_pan_by_screen_delta(e.position, e.relative)

# --- helpers ---

func _pan_by_screen_delta(screen_pos: Vector2, screen_delta: Vector2) -> void:
	if screen_delta == Vector2.ZERO:
		return
	var prev := screen_pos - screen_delta

	var a: Vector3 = _mouse_on_plane(prev)
	var b: Vector3 = _mouse_on_plane(screen_pos)
	if a == null or b == null:
		return

	var d := b - a
	# move pivot opposite the drag; keep current Y
	global_position = Vector3(
		global_position.x - d.x,
		global_position.y,
		global_position.z - d.z
	)

func _mouse_on_plane(screen_pos: Vector2) -> Variant:
	var from := _cam.project_ray_origin(screen_pos)
	var dir := _cam.project_ray_normal(screen_pos)
	var hit: Vector3 = _drag_plane.intersects_ray(from, dir)
	return hit if hit is Vector3 else null
