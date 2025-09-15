extends Node3D

var mushroom_scene: PackedScene = load("res://mushroom.tscn")

@onready var forest_grid := $ForestGrid
@onready var environment := $Environment

var day := 0

func _ready() -> void:
	$Hud.day_ended.connect(end_day)
	$Hud.day_started.connect(start_day)

func start_day() -> void:
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(environment, "time_of_day", 0.35, 2)

func end_day() -> void:
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(environment, "time_of_day", 1.0, 2)
	await tween.finished
	environment.time_of_day = 0.0
	
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
			$SpotLight3D.position = $ForestGrid.cell_to_world($ForestGrid.world_to_cell(hit.position))
			$SpotLight3D.position.y = 5
			if not tile.occupied and not tile.is_fully_occupied():
				var mushroom : Mushroom = mushroom_scene.instantiate()
				mushroom.position = tile.center
				mushroom.grid = forest_grid

				if !mushroom.is_spawn_safe(mushroom.position):
					return
					
				add_child(mushroom)
				mushroom.set_description.connect($Hud.set_hover_desc)
				tile.occupied = true
