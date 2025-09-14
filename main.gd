extends Node3D

var mushroom_scene: PackedScene = load("res://mushroom.tscn")

@onready var forest_grid := $ForestGrid

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
			var info: Tile = $ForestGrid.get_at_world(hit.position)
			$SpotLight3D.position = $ForestGrid.cell_to_world($ForestGrid.world_to_cell(hit.position))
			$SpotLight3D.position.y = 5
			if not info.occupied:
				print("here")
				var mushroom := mushroom_scene.instantiate()
				mushroom.position = info.center
				mushroom.grid = forest_grid
				add_child(mushroom)
				mushroom.set_description.connect($Hud.set_hover_desc)
				info.occupied = true
			if info:
				print(info)
