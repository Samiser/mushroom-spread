@tool
extends Node3D

@onready var world_environment := $WorldEnvironment
@onready var sun := $DirectionalLight3D
var _env: Environment

@export var auto_run: bool = true
@export var day_length_seconds: float = 120.0
@export_range(0.0, 1.0, 0.001) var time_of_day: float = 0.0: set = set_time
@export var fog_color_gradient: Gradient
@export var time_scale: float = 1.0

@export var sun_azimuth_deg: float = 45.0		# yaw around Y (east->west direction)
@export var sun_elevation_curve: Curve			# maps t(0..1) -> elevation deg
@export var sun_intensity: Curve				# maps t -> 0..1 multiplier
@export var sun_color_gradient: Gradient		# maps t -> Color

func _ready() -> void:
	_env = world_environment.environment
	if not Engine.is_editor_hint():
		time_of_day = 0.

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not auto_run:
		return
	if day_length_seconds <= 0.0:
		return
	var step := (delta / day_length_seconds) * time_scale
	time_of_day = fposmod(time_of_day + step, 1.0)
	_apply_time()

func set_time(v: float) -> void:
	time_of_day = clamp(v, 0.0, 1.0)
	_apply_time()

func _apply_time() -> void:
	_update_fog_and_ambient()
	if sun_elevation_curve and sun_intensity and sun_color_gradient:
		_update_sun()

func _update_sun() -> void:
	var elev_deg := sun_elevation_curve.sample_baked(time_of_day)
	var az_deg := fposmod(-90 + 360.0 * time_of_day, 360.0)
	var dir := _dir_from_az_el(deg_to_rad(az_deg), deg_to_rad(elev_deg))

	sun.rotation_degrees = Vector3(-elev_deg, az_deg, 0.0)
	
	sun.light_color = sun_color_gradient.sample(time_of_day)
	sun.light_energy = sun_intensity.sample_baked(time_of_day)

func _dir_from_az_el(az: float, el: float) -> Vector3:
	var ce := cos(el)
	return Vector3(cos(az) * ce, sin(el), sin(az) * ce)

func _update_fog_and_ambient() -> void:
	if _env:
		_env.fog_enabled = true
		_env.fog_light_color = fog_color_gradient.sample(time_of_day)
