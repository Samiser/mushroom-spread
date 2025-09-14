extends Node3D
class_name Mushroom

@export var mushroom_data : MushroomData

var growth := 0.1
var generational_max := 0.1
var grown := false

var grid: ForestGrid

@onready var mushroom_baby := load("res://mushroom.tscn")
var generation := 0 # current mushroom gen
var family : Array[Mushroom] # only the parent tracks this
var parent : Mushroom
var family_name : String

@onready var sprite :Sprite3D= $Sprite3D
var highlighted := false

signal set_description(desc)

func _ready() -> void:
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
		if !grown and generation < mushroom_data.max_family - 1:
			_spawn_mushroom()
		return
	
	growth = move_toward(growth, generational_max, delta * mushroom_data.grow_speed)
	scale = Vector3.ONE * growth

func _on_area_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int):
	if event is InputEventMouseButton:
		if event.is_pressed():
			pass # unused for now

func _spawn_mushroom() -> void:
	grown = true
	var spawn_offset := Vector3(randf_range(-1, 1), 0.0, randf_range(-1, 1)).normalized() * mushroom_data.spawn_range
	var spawn_point := global_position + spawn_offset
	
	var tile: Tile = grid.get_at_world(spawn_point)
	
	if !tile:
		return
	
	if tile.is_fully_occupied():
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
	
	var new_growth : float = generational_max - mushroom_data.generational_loss
	new_growth *= tile.fertility
	new_mushroom.scale = Vector3.ONE * new_growth
	new_mushroom.generational_max = new_growth
	
	new_mushroom.generation = generation + 1
	new_mushroom.parent = parent
	parent.family.append(new_mushroom)

	new_mushroom.global_position = global_position + spawn_offset
	tile.mushroom_count += 1
	print(tile.mushroom_count)

func _on_area_3d_mouse_entered() -> void:
	for mushroom in parent.family:
		mushroom.sprite.shaded = false
	
	highlighted = true

func _on_area_3d_mouse_exited() -> void:
	for mushroom in parent.family:
		mushroom.sprite.shaded = true
	
	highlighted = false
