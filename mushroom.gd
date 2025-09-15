extends Node3D
class_name Mushroom

@export var mushroom_data : MushroomData

var growth := 0.1
var generational_max := 1.0
var grown := false

var grid: ForestGrid

@onready var mushroom_baby := load("res://mushroom.tscn")
var generation := 0 # current mushroom gen
var family : Array[Mushroom] # only the parent tracks this
var parent : Mushroom
var family_name : String

@onready var sprite :Sprite3D= $Sprite3D
var highlighted := false

var even_ring_jitter_deg: float = 12.0 # small random wobble on gen-0 ring
var child_cone_deg: float = 60.0 # half-angle for spreading siblings from a child
var safety_search_steps: int = 6 # try a few rotated alternatives if blocked
var safety_step_deg: float = 12.0

var ring_radius_jitter_pct: float = 0.30
var child_dist_jitter_pct: float = 0.40
var search_radius_step_pct: float = 0.20

var spawn_burst_interval: float = 0.2

var branch_dir: Vector3 = Vector3.ZERO

signal set_description(desc)

func _ready() -> void:
	add_to_group("mushrooms")
	
	$Area3D.input_event.connect(_on_area_input_event)
	
	if generation == 0:
		parent = self
		family.insert(0, self)
		generational_max = mushroom_data.max_growth
		family_name = mushroom_data.family_names.get(randi_range(0, mushroom_data.family_names.size() - 1))

func _process(delta: float) -> void:
	_grow(delta)
	
	if highlighted:
		var growth_percent := roundf((growth / generational_max) * 100)
		var growth_colour : Color = lerp(Color.RED, Color.GREEN, growth_percent / 100.0)
		var desc: String = mushroom_data.mushroom_name + " (" + parent.family_name + ") Gen " + str(generation) +  "\nFamily size: " + str(parent.family.size()) + "/" + str(mushroom_data.max_family) + "\nGrowth: [color=#" + growth_colour.to_html() + "]" + str(growth_percent) + "%[/color]\nTile: " + grid.get_at_world(global_position).type_string() 
		parent.set_description.emit(desc)

func _grow(delta: float) -> void:
	if growth >= generational_max:
		return
	
	growth = move_toward(growth, generational_max, delta * mushroom_data.grow_speed)
	scale = Vector3.ONE * growth

func grow_to_full(duration: float = 0.0) -> void:
	generational_max = mushroom_data.max_growth

func _xz_dir_from_angle(ang: float) -> Vector3:
	return Vector3(cos(ang), 0.0, sin(ang)).normalized()

func _on_area_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if not (event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if growth < generational_max:
		return

	$CPUParticles3D.emitting = true

	var spawns := _pick_spawn_count()
	spawns = _cap_spawns_to_family(spawns)
	if spawns <= 0:
		return

	if generation == 0:
		await _spawn_gen0_ring(spawns)
	else:
		var dir := _resolve_branch_dir()
		await _spawn_child_burst(spawns, dir)

func _pick_spawn_count() -> int:
	return randi_range(3, 4) if generation == 0 else randi_range(1, mushroom_data.spawn_max)

func _cap_spawns_to_family(spawns: int) -> int:
	if grown:
		return 0
	var remaining := mushroom_data.max_family - parent.family.size()
	return clamp(spawns, 0, max(remaining, 0))

func _resolve_branch_dir() -> Vector3:
	var dir := branch_dir
	if dir == Vector3.ZERO:
		dir = (global_position - parent.global_position)
		dir.y = 0.0
		dir = dir.normalized()
		if dir == Vector3.ZERO:
			dir = _xz_dir_from_angle(randf() * TAU)
	return dir

func _post_spawn_pause() -> void:
	if spawn_burst_interval > 0.0:
		await get_tree().create_timer(spawn_burst_interval).timeout

func _spawn_burst(spawns: int, dir_at: Callable, dist_at: Callable) -> void:
	for i in spawns:
		var dir: Vector3 = dir_at.call(i, spawns)
		var dist: float = dist_at.call(i, spawns)
		_spawn_baby_with_dir(dir, dist)
		await _post_spawn_pause()

func _spawn_gen0_ring(spawns: int) -> void:
	var base_angle := randf() * TAU

	var dir_at := func(i: int, n: int) -> Vector3:
		var ang := base_angle + float(i) * TAU / float(n)
		var jitter := deg_to_rad(randf_range(-even_ring_jitter_deg, even_ring_jitter_deg))
		return _xz_dir_from_angle(ang + jitter)

	var dist_at := func(i: int, n: int) -> float:
		return mushroom_data.spawn_range * randf_range(
			2.0 - ring_radius_jitter_pct,
			2.0 + ring_radius_jitter_pct
		)

	await _spawn_burst(spawns, dir_at, dist_at)

func _spawn_child_burst(spawns: int, dir: Vector3) -> void:
	var dir_at := func(i: int, n: int) -> Vector3:
		var t := 0.5 if (n == 1) else float(i) / float(n - 1)
		var ang_off := deg_to_rad(lerp(-child_cone_deg, child_cone_deg, t))
		return (Basis(Vector3.UP, ang_off) * dir).normalized()

	var dist_at := func(i: int, n: int) -> float:
		var base := 2.0 if n == 1 else 1.0
		return mushroom_data.spawn_range * randf_range(
			base - child_dist_jitter_pct,
			base + child_dist_jitter_pct
		)

	await _spawn_burst(spawns, dir_at, dist_at)

func is_on_starting_tile(pos: Vector3):
	var tile: Tile = grid.get_at_world(pos)
	return tile and tile.type == mushroom_data.starting_tile

func is_spawn_safe(pos: Vector3) -> bool:
	var tile: Tile = grid.get_at_world(pos)
	
	if !tile:
		return false
	
	if tile.is_fully_occupied(mushroom_data.tile_capacity):
		return false
	
	if tile.has_animal and mushroom_data.animal_resistance > randf_range(0.0, 1.0):
		return false
	
	if tile.has_insects and mushroom_data.insect_resistance > randf_range(0.0, 1.0):
		return false
	
	if randf_range(0.0, 1.0) > tile.fertility:
		return false
	
	return true

func _spawn_baby_with_dir(dir_xz: Vector3, dist: float = -1.0) -> void:
	grown = true

	# ensure direction is horizontal
	var dir := dir_xz
	dir.y = 0.0
	if dir == Vector3.ZERO:
		dir = _xz_dir_from_angle(randf() * TAU)

	# default distance if not passed in
	if dist <= 0.0:
		dist = mushroom_data.spawn_range * randf_range(
			1.0 - child_dist_jitter_pct, 1.0 + child_dist_jitter_pct
		)

	var try_dir := dir
	var try_dist := dist
	var spawn_point := global_position + try_dir * try_dist

	# Try a few rotated (and slightly radial) alternatives if blocked
	var attempts := 0
	while attempts < safety_search_steps and !is_spawn_safe(spawn_point):
		attempts += 1
		var rot := deg_to_rad(safety_step_deg * (attempts if (attempts % 2 == 0) else -attempts))	# zig-zag
		try_dir = (Basis(Vector3.UP, rot) * dir).normalized()

		# gently expand/contract the radius to find a free spot
		var sign := 1.0 if (attempts % 2 == 0) else -1.0
		try_dist = max(0.1, dist * (1.0 + sign * search_radius_step_pct))

		spawn_point = global_position + try_dir * try_dist

	if !is_spawn_safe(spawn_point):
		return

	var new_mushroom: Mushroom = mushroom_baby.instantiate() as Mushroom
	get_tree().root.add_child(new_mushroom)

	new_mushroom.grid = grid

	# inherit + compute growth
	var tile: Tile = grid.get_at_world(spawn_point)
	var new_growth: float = (generational_max - mushroom_data.generational_loss) * (tile.fertility if tile else 1.0)
	new_mushroom.scale = Vector3.ONE * new_growth
	new_mushroom.generational_max = new_growth

	new_mushroom.generation = generation + 1
	new_mushroom.parent = parent
	new_mushroom.branch_dir = try_dir	# predictable future heading

	parent.family.append(new_mushroom)
	new_mushroom.global_position = spawn_point

	if tile:
		tile.mushroom_count += 1

func _on_area_3d_mouse_entered() -> void:
	for mushroom in parent.family:
		mushroom.sprite.shaded = false
	
	highlighted = true

func _on_area_3d_mouse_exited() -> void:
	for mushroom in parent.family:
		mushroom.sprite.shaded = true
	
	highlighted = false
