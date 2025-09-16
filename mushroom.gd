extends Node3D
class_name Mushroom

enum MUSHROOM_MOOD {Likes, Dislikes, NoComment}

@export var mushroom_data : MushroomData

var growth := 0.1
var generational_max := 1.0
var grown := false

var grid: ForestGrid
var tile_happiness : MUSHROOM_MOOD

@onready var mushroom_baby := load("res://mushroom.tscn")
var generation := 0 # current mushroom gen
var family : Array[Mushroom] # only the parent tracks this
var parent : Mushroom
var last_in_tree : Mushroom
var family_name : String
var tile_rating : Array[int] = [0, 0] # rating, total
var family_health := 50.0
var is_health_increasing := true

@onready var sprite: Sprite3D = $Sprite3D
@onready var spore_particles: CPUParticles3D = $CPUParticles3D

@onready var spawner: MushroomSpawner = $Spawner
@onready var ui: MushroomUI = $UI

var highlighted := false

signal set_description(desc)

func _ready() -> void:
	add_to_group("mushrooms")
	
	$Area3D.input_event.connect(_on_area_input_event)
	
	if generation == 0:
		parent = self
		family.insert(0, self)
		generational_max = mushroom_data.max_growth
		family_name = mushroom_data.family_names.get(randi_range(0, mushroom_data.family_names.size() - 1))

	spawner.setup(self)
	ui.setup(self)

func is_on_starting_tile(pos: Vector3):
	var tile: Tile = grid.get_at_world(pos)
	return tile and tile.type == mushroom_data.starting_tile

func _process(delta: float) -> void:
	_grow(delta)
	ui.update(delta)
	
	if highlighted:
		parent.set_description.emit(ui.build_description())

func check_family_tiles() -> Array[int]:
	var like_tiles := 0
	var dislike_tiles := 0
	var total := 0
	
	for mushroom in parent.family:
		var tile := grid.get_at_world(mushroom.global_position)
		if !tile:
			continue
			
		if parent.mushroom_data.likes_tiles.has(tile.type):
			like_tiles += 1
			total += 1
			mushroom.tile_happiness = MUSHROOM_MOOD.Likes
		elif parent.mushroom_data.dislikes_tiles.has(tile.type):
			dislike_tiles += 1
			total += 1
			mushroom.tile_happiness = MUSHROOM_MOOD.Dislikes
		else:
			mushroom.tile_happiness = MUSHROOM_MOOD.NoComment
	
	var rating := like_tiles + -dislike_tiles
	return [rating, total]

func _grow(delta: float) -> void:
	if growth >= generational_max:
		return
	
	growth = move_toward(growth, generational_max, delta * mushroom_data.grow_speed)
	scale = Vector3.ONE * growth

func grow_to_full() -> void:
	generational_max = mushroom_data.max_growth

func _on_area_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		spawner.handle_click()

func _on_area_3d_mouse_entered() -> void:
	for mushroom in parent.family:
		mushroom.sprite.shaded = false
	
	highlighted = true

func _on_area_3d_mouse_exited() -> void:
	for mushroom in parent.family:
		mushroom.sprite.shaded = true
	
	highlighted = false
