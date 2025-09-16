extends Resource
class_name MushroomData

@export var mushroom_name : String = "unnamed mushroom"

@export var grow_speed := 0.2
@export var max_growth := 1.0

@export var spawn_range := 0.3
@export var max_family := 12
@export var tile_capacity := 10
@export var spawn_max := 4
@export var spawn_min := 3

@export_range (0.0, 0.5) var generational_loss := 0.2 # shrinkage per generation

@export_range (0.0, 1.0) var insect_resistance := 0.0
@export_range (0.0, 1.0) var animal_resistance := 0.0

@export var starting_tile : Tile.Type

var family_names : Array[String] = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguaz", "Simpsons"]
