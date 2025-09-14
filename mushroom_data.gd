extends Resource
class_name MushroomData

@export var mushroom_name : String = "unnamed mushroom"

@export var grow_speed := 0.2
@export var max_growth := 1.0

@export var spawn_range := 0.3
@export var max_family := 4

var generational_loss := 0.2 # shrinkage per generation

var family_names : Array[String] = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguaz", "Simpsons"]
