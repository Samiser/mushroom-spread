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
var family_health := 50.0
var is_health_increasing := true
var family: Array[Mushroom]
var family_name: String
var occupied_tiles: Array[Tile]

# family statistics
var tile_rating: Array[int] = [0, 0] # rating, total
var colony_size: int

var liked_tiles_count: int
var neutral_tiles_count: int
var disliked_tiles_count: int

var culls_manual: int
var culls_insect: int
var culls_animals: int
var culls_total: int
