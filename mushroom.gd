extends Node3D
class_name Mushroom

var growth := 0.1
var grow_speed := 0.2
var max_growth := 1.0
var spawn_range := 0.3
var max_family := 4
@onready var mushroom_baby := load("res://mushroom.tscn")
@onready var sprite :Sprite3D= $Sprite3D
var grown := false
var generation := 0
var generational_loss := 0.2
var family : Array[Mushroom]
var parent : Mushroom
var grid: ForestGrid
var spawn_height := 0.0
var viewing := false

signal set_description(desc)

func _ready() -> void:
	$Area3D.input_event.connect(_on_area_input_event)
	spawn_height = global_position.y
	
	if generation == 0:
		parent = self
		family.insert(0, self)

func _process(delta: float) -> void:
	_grow(delta)
	
	if viewing:
		var growth_percent := roundf((growth / max_growth) * 100)
		var growth_colour : Color = lerp(Color.RED, Color.GREEN, growth_percent / 100.0)
		var desc : String = "Mushroom gen " + str(generation) +  "\nFamily size: " + str(parent.family.size()) + "/" + str(max_family) + "\nGrowth: [color=#" + growth_colour.to_html() + "]" + str(growth_percent) + "%[/color]\nTile: " + grid.get_tile(global_position).type 
		parent.set_description.emit(desc)

func _grow(delta: float) -> void:
	if growth >= max_growth:
		growth = max_growth
		if !grown and generation < max_family - 1:
			_spread()
		return
	
	growth += delta * grow_speed
	scale = Vector3.ONE * growth

func _on_area_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int):
	if event is InputEventMouseButton:
		if event.is_pressed():
			pass #_spread()

func _spread() -> void:
	_spawn_mushroom()
	grown = true

func _spawn_mushroom() -> void:
	var spawn_offset := Vector3(randf_range(-1, 1), 0.0, randf_range(-1, 1)).normalized() * spawn_range
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
	get_tree().root.add_child(new_mushroom)
	
	new_mushroom.grid = grid
	
	var new_growth := max_growth - generational_loss
	new_growth *= tile.fertility
	new_mushroom.scale = Vector3.ONE * new_growth
	new_mushroom.max_growth = new_growth
	
	new_mushroom.generation = generation + 1
	new_mushroom.parent = parent
	parent.family.append(new_mushroom)

	new_mushroom.global_position = global_position + spawn_offset
		
	print("spawning mushroom on ", tile.type, ", gen: ", new_mushroom.generation)

func _die() -> void:
	pass

func _on_area_3d_mouse_entered() -> void:
	for mushroom in parent.family:
		mushroom.sprite.shaded = false
	
	viewing = true

func _on_area_3d_mouse_exited() -> void:
	for mushroom in parent.family:
		mushroom.sprite.shaded = true
	
	viewing = false
