extends Resource
class_name MushroomData

# family attributes
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
@export var likes_tiles : Array[Tile.Type]
@export var dislikes_tiles : Array[Tile.Type]

# family data
var previous_data: MushroomData

var family_health := 50.0
var is_health_increasing := true
var family: Array[Mushroom]
var family_name: String
var occupied_tiles: Array[Tile]

# family statistics
var tile_rating: Array[int] = [1, 1] # rating, total
var colony_size: int = 0

var liked_tiles_count: int
var neutral_tiles_count: int
var disliked_tiles_count: int

var culls_manual: int
var culls_insect: int
var culls_animals: int
var culls_total: int

signal member_added(mushroom: Mushroom)
signal cap_reached

func tile_rating_percentage() -> int:
	return int(roundf((tile_rating[0] as float / tile_rating[1]) * 100.0))

func add_member(m: Mushroom) -> void:
	if not family.has(m):
		family.append(m)
		member_added.emit(m)
		if family.size() >= max_family:
			cap_reached.emit()

func preferences_string() -> String:
	return "Likes: %s\nDislikes: %s" % [
		", ".join(likes_tiles.map(Tile.type_to_bbcode)),
		", ".join(dislikes_tiles.map(Tile.type_to_bbcode))
	]
