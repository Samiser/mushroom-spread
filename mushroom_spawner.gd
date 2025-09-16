extends Node
class_name MushroomSpawner

@export var even_ring_jitter_deg: float = 12.0 # small random wobble on gen-0 ring
@export var child_cone_deg: float = 60.0 # half-angle for spreading siblings from a child
@export var safety_search_steps: int = 6 # try a few rotated alternatives if blocked
@export var safety_step_deg: float = 12.0

@export var ring_radius_jitter_pct: float = 0.30
@export var child_dist_jitter_pct: float = 0.40
@export var search_radius_step_pct: float = 0.20

@export var spawn_burst_interval: float = 0.2

@export var spawn_check_radius: float = 0.1
@export var spawn_check_height: float = 0.05
@export var spawn_check_y_offset: float = 0.2

@export var debug_visualize_checks: bool = false

#internal
var M: Mushroom
var _branch_dir: Vector3 = Vector3.ZERO

var _spawn_shape := CylinderShape3D.new()
var _spawn_q := PhysicsShapeQueryParameters3D.new()

func setup(mushroom: Mushroom) -> void:
	M = mushroom	
	_spawn_shape.radius = spawn_check_radius
	_spawn_shape.height = spawn_check_height
	_spawn_q.shape = _spawn_shape
	_spawn_q.collide_with_bodies = true

func handle_click() -> void:	
	if M.growth < M.generational_max:
		return

	if M.grown:
		return

	var spawns := _pick_spawn_count()
	spawns = _cap_spawns_to_family(spawns)
	if spawns <= 0:
		return

	if M.generation == 0:
		await _spawn_gen0_ring(spawns)
	else:
		var dir := _resolve_branch_dir()
		await _spawn_child_burst(spawns, dir)

func _pick_spawn_count() -> int:
	return randi_range(3, 4) if M.generation == 0 else randi_range(M.mushroom_data.spawn_min, M.mushroom_data.spawn_max)

func _cap_spawns_to_family(spawns: int) -> int:
	var remaining := M.mushroom_data.max_family - M.parent.family.size()
	return clamp(spawns, 0, max(remaining, 0))

func _resolve_branch_dir() -> Vector3:
	var dir := _branch_dir
	if dir == Vector3.ZERO:
		dir = (M.global_position - M.parent.global_position)
		dir.y = 0.0
		dir = dir.normalized()
		if dir == Vector3.ZERO:
			dir = _xz_dir_from_angle(randf() * TAU)
	return dir

func _xz_dir_from_angle(ang: float) -> Vector3:
	return Vector3(cos(ang), 0.0, sin(ang)).normalized()

func _post_spawn_pause() -> void:
	if spawn_burst_interval > 0.0:
		await get_tree().create_timer(spawn_burst_interval).timeout

func _spawn_burst(spawns: int, dir_at: Callable, dist_at: Callable) -> void:
	M.spore_particles.emitting = true
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

	var dist_at := func(_i: int, _n: int) -> float:
		return M.mushroom_data.spawn_range * randf_range(
			2.0 - ring_radius_jitter_pct,
			2.0 + ring_radius_jitter_pct
		)

	await _spawn_burst(spawns, dir_at, dist_at)

func _spawn_child_burst(spawns: int, dir: Vector3) -> void:
	var dir_at := func(i: int, n: int) -> Vector3:
		var t := 0.5 if (n == 1) else float(i) / float(n - 1)
		var ang_off := deg_to_rad(lerp(-child_cone_deg, child_cone_deg, t))
		return (Basis(Vector3.UP, ang_off) * dir).normalized()

	var dist_at := func(_i: int, n: int) -> float:
		var base := 2.0 if n == 1 else 1.0
		return M.mushroom_data.spawn_range * randf_range(
			base - child_dist_jitter_pct,
			base + child_dist_jitter_pct
		)

	await _spawn_burst(spawns, dir_at, dist_at)

func _collides_with_thing_at(world_pos: Vector3) -> bool:
	_spawn_shape.radius = spawn_check_radius
	_spawn_shape.height = spawn_check_height

	var xform := Transform3D(Basis.IDENTITY, Vector3(
		world_pos.x,
		world_pos.y + spawn_check_y_offset,
		world_pos.z
	))
	_spawn_q.transform = xform

	var hits := M.get_world_3d().direct_space_state.intersect_shape(_spawn_q, 16)
	var blocked := false
	
	for hit in hits:
		if hit.collider.name in ["Trees", "Stumps"]:
			blocked = true
			break

	if debug_visualize_checks:
		_visualize_check(world_pos, blocked)

	return blocked

func _visualize_check(world_pos: Vector3, blocked: bool) -> void:
	var debug_viz_seconds: float = 0.6
	var debug_ok_color: Color = Color(0.3, 0.9, 0.5, 0.25)
	var debug_block_color: Color = Color(0.95, 0.35, 0.35, 0.35)
	
	if not debug_visualize_checks:
		return
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = spawn_check_radius
	mesh.bottom_radius = spawn_check_radius
	mesh.height = spawn_check_height
	mesh.radial_segments = 24
	mi.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.shadingMode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = debug_block_color if blocked else debug_ok_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.disable_receive_shadows = true
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	mi.global_position = Vector3(world_pos.x, world_pos.y + spawn_check_y_offset, world_pos.z)
	get_tree().current_scene.add_child(mi)

	var t := get_tree().create_timer(debug_viz_seconds)
	t.timeout.connect(func(): mi.queue_free())

func is_spawn_safe(pos: Vector3) -> bool:
	var tile: Tile = M.grid.get_at_world(pos)
	
	if !tile:
		return false
	
	if tile.is_fully_occupied(M.mushroom_data.tile_capacity):
		return false
	
	if tile.has_animal and M.mushroom_data.animal_resistance > randf_range(0.0, 1.0):
		return false
	
	if tile.has_insects and M.mushroom_data.insect_resistance > randf_range(0.0, 1.0):
		return false
	
	if randf_range(0.0, 1.0) > tile.fertility:
		return false
	
	if _collides_with_thing_at(pos):
		return false
	
	return true

func _spawn_baby_with_dir(dir_xz: Vector3, dist: float = -1.0) -> void:
	M.grown = true

	# ensure direction is horizontal
	var dir := dir_xz
	dir.y = 0.0
	if dir == Vector3.ZERO:
		dir = _xz_dir_from_angle(randf() * TAU)

	# default distance if not passed in
	if dist <= 0.0:
		dist = M.mushroom_data.spawn_range * randf_range(
			1.0 - child_dist_jitter_pct, 1.0 + child_dist_jitter_pct
		)

	var try_dir := dir
	var try_dist := dist
	var spawn_point := M.global_position + try_dir * try_dist

	# Try a few rotated (and slightly radial) alternatives if blocked
	var attempts := 0
	while attempts < safety_search_steps and !is_spawn_safe(spawn_point):
		attempts += 1
		var rot := deg_to_rad(safety_step_deg * (attempts if (attempts % 2 == 0) else -attempts))	# zig-zag
		try_dir = (Basis(Vector3.UP, rot) * dir).normalized()

		# gently expand/contract the radius to find a free spot
		var change := 1.0 if (attempts % 2 == 0) else -1.0
		try_dist = max(0.1, dist * (1.0 + change * search_radius_step_pct))

		spawn_point = M.global_position + try_dir * try_dist

	if !is_spawn_safe(spawn_point):
		return

	var new_mushroom: Mushroom = M.mushroom_baby.instantiate() as Mushroom
	get_tree().root.add_child(new_mushroom)

	new_mushroom.grid = M.grid

	# inherit + compute growth
	var tile: Tile = M.grid.get_at_world(spawn_point)
	var new_growth: float = (M.generational_max - M.mushroom_data.generational_loss) * (tile.fertility if tile else 1.0)
	new_mushroom.scale = Vector3.ONE * new_growth
	new_mushroom.generational_max = new_growth

	new_mushroom.generation = M.generation + 1
	new_mushroom.parent = M.parent
	new_mushroom.last_in_tree = M
	new_mushroom.spawner._branch_dir = try_dir	# predictable future heading

	M.parent.family.append(new_mushroom)
	new_mushroom.global_position = spawn_point
	
	M.parent.tile_rating = M.check_family_tiles()
	
	if tile:
		tile.mushroom_count += 1
