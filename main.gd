extends Node3D

@export var mushroom_scene: Array[PackedScene]
var selected_mushroom := 0

@onready var forest_grid := $ForestGrid
@onready var environment := $Environment
@onready var tutorial: Tutorial = $Tutorial

var day := 0
var family_count := 0

var parents: Array[Mushroom]

func _ready() -> void:
	$Hud.end_day.connect(end_day)
	$Report.next_day.connect(start_day)
	start_day()
	tutorial.next()
	
	selected_mushroom = randi_range(0, mushroom_scene.size() - 1)
	var mushroom: Mushroom = mushroom_scene[selected_mushroom].instantiate()
	
	forest_grid.highlight_starting_tiles(mushroom)
	$Hud.set_preferences(mushroom.mushroom_data.preferences_string())

func start_day() -> void:
	$Hud.start_day(day)
	get_tree().call_group("mushrooms", "tween_glow", false, 2)
	for parent in parents:
		parent.take_data_snapshot()
	environment.is_day = true
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(environment, "time_of_day", 0.3, 2)

func end_day() -> void:
	if tutorial.get_current_title() == "Night falls":
		tutorial.next()
	get_tree().call_group("mushrooms", "grow_to_full")
	get_tree().call_group("mushrooms", "tween_glow", true, 2)
	
	environment.is_day = false
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(environment, "time_of_day", 1.0, 2)
	await tween.finished
	environment.time_of_day = 0.0
	
	for m: Mushroom in get_tree().get_nodes_in_group("roots"):
		if m is Mushroom and m.is_root():
			m.end_day()
			$Report.update_report(m, day)
	$Report.visible = true
	day += 1

func _on_member_added(m: Mushroom):
	if m.mushroom_data.family.size() == 7 and tutorial.get_current_title() == "Spreading Spores":
		tutorial.next()
	elif m.mushroom_data.family.size() == m.mushroom_data.max_family and tutorial.get_current_title() == "Reading the Forest":
		tutorial.next()

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var cam := get_viewport().get_camera_3d()
		var from := cam.project_ray_origin(e.position)
		var to := from + cam.project_ray_normal(e.position) * 2000.0
		var hit := get_world_3d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters3D.create(from, to)
		)
		if hit.has("position"):
			hit.position.y = 0.5
			var tile: Tile = $ForestGrid.get_at_world(hit.position)
			$Hud.set_tile_info(tile.to_bbcode())
			if not tile.occupied and not tile.is_fully_occupied(4) and not family_count >= 1: # TODO: what happens when starting on a spot with mushrooms already on it? can that happen?
				var mushroom : Mushroom = mushroom_scene[selected_mushroom].instantiate()
				mushroom.position = tile.center
				
				if tile.type == Tile.Type.STUMP or tile.type == Tile.Type.TREE:
					mushroom.position += (Vector3.FORWARD * 0.22)
				
				mushroom.grid = forest_grid

				if !mushroom.is_on_starting_tile(mushroom.position):
					return
				
				if tutorial.tutorial_enabled and !tutorial.get_current_title() == "First Fungus":
					return
				
				tutorial.next()
				forest_grid.clear_highlights()
				family_count += 1
				add_child(mushroom)
				mushroom.add_to_group("roots")
				mushroom.set_description.connect($Hud.set_hover_desc)
				mushroom.set_parent_description.connect($Hud.display_parent_info)
				mushroom.take_data_snapshot()
				mushroom.mushroom_data.cap_reached.connect($Hud.on_cap_reached)
				mushroom.mushroom_data.member_added.connect(_on_member_added)
				parents.append(mushroom)
				tile.occupied = true
