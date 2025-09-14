extends Node3D
class_name Mushroom

var growth := 0.1
var grow_speed := 1.0
var click_growth := 0.1
var max_growth := 1.0
var spawn_range := 0.3
var max_spawns := 2
@onready var mushroom_baby := load("res://mushroom.tscn")
@onready var sprite :Sprite3D= $Sprite3D
var grown := false
var generation := 0
var generational_loss := 0.25
var family : Array[Mushroom]
var parent : Mushroom
var grid: ForestGrid
var spawn_height := 0.0

signal set_description(desc)

func _ready() -> void:
	$Area3D.input_event.connect(_on_area_input_event)
	spawn_height = global_position.y
	
	if generation == 0:
		parent = self

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
	if event is InputEventMouseButton:
		if event.is_pressed():
			_spread()

func _spread() -> void:
	if max_growth > 0.4:
		var count := randi_range(1, max_spawns)
		while count > 0:
			_spawn_mushroom(count)
			count -= 1
	grown = true

func _spawn_mushroom(index: int) -> void:
	var spawn_offset := Vector3(randf_range(-1, 1), 0.0, randf_range(-1, 1)).normalized() * spawn_range * index
	var spawn_point := global_position + spawn_offset
	
	var tile: Tile = grid.get_at_world(spawn_point)
	
	if !tile:
		return
	
	if tile.has_animal:
		return
	
	if tile.has_insects:
		if randf_range(0, 4) == 1:
			return
	
	if randf_range(0.0, 1.0) > tile.fertility:
		return
	
	var new_mushroom: Node3D = mushroom_baby.instantiate()
	get_parent().add_child(new_mushroom)
	
	new_mushroom.grid = grid
	
	var new_growth := max_growth - generational_loss
	new_growth *= tile.fertility
	new_mushroom.scale = Vector3.ONE * new_growth
	new_mushroom.max_growth = new_growth
	
	new_mushroom.generation = generation + 1
	new_mushroom.parent = parent
	parent.family.append(self)

	new_mushroom.global_position = global_position + spawn_offset
	
	print("spawning mushroom on ", tile.type, ", parent: ", parent)

func _die() -> void:
	pass


func _on_area_3d_mouse_entered() -> void:
	for mushroom in parent.family:
		mushroom.sprite.shaded = false 
	
	var desc : String = "Mushroom (" + str(generation) +  ")\nFamily size: " + str(parent.family.size()) + "\nGrowth: " + str((max_growth / growth) * 100) + "%"
	set_description.emit(desc)


func _on_area_3d_mouse_exited() -> void:
	for mushroom in parent.family:
		mushroom.sprite.shaded = true 
