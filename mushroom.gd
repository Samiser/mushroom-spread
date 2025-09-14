extends Node3D

var growth := 0.1
var grow_speed := 1.0
var click_growth := 0.1
var max_growth := 1.0
var spawn_range := 0.3
var max_spawns := 2
@onready var mesh := $mushroom_mesh
@onready var mushroom_baby := load("res://mushroom.tscn")
var grow_tween : Tween
var grown := false

var grid: ForestGrid

func _ready() -> void:
	$Area3D.input_event.connect(_on_area_input_event)

func _process(delta: float) -> void:
	_grow(delta)

func _grow(delta: float) -> void:
	if growth >= max_growth:
		if !grown:
			_spread()
		return
	
	growth += delta * grow_speed
	scale = Vector3.ONE * growth

func _on_area_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int):
	if event is InputEventMouseButton and event.is_pressed():
		_spread()

func _spread() -> void:
	if max_growth > 0.4:
		var count := randi_range(1, max_spawns)
		while count > 0:
			var new_mushroom: Node3D = mushroom_baby.instantiate()
			get_parent().add_child(new_mushroom)
			
			var new_growth := max_growth - 0.2
			new_mushroom.scale = Vector3.ONE * new_growth
			new_mushroom.max_growth = new_growth

			var spawn_offset := Vector3(randf_range(-1, 1), 0.0, randf_range(-1, 1)).normalized() * spawn_range * count
			new_mushroom.global_position = global_position + spawn_offset

			new_mushroom.grid = grid
			
			var tile: Tile = grid.get_at_world(new_mushroom.global_position)
			if tile and tile.type:
				print(tile.type)
			else:
				print("no type")
			

			count -= 1
	grown = true
