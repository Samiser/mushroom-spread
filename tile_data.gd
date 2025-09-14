extends Resource
class_name Tile

var cell: Vector3i
var center: Vector3

var ground_id: int = GridMap.INVALID_CELL_ITEM
var ground_name: String = ""

var thing_id: int = GridMap.INVALID_CELL_ITEM
var thing_name: String = ""
var thing_map: GridMap = null

var type: String = ""

var fertility: float = 1.0
var has_animal: bool = false
var has_insects: bool = false

var occupied: bool = false

func _to_string() -> String:
	var g_id := ground_id if ground_id != GridMap.INVALID_CELL_ITEM else -1
	var t_id := thing_id if thing_id != GridMap.INVALID_CELL_ITEM else -1
	return "Tile{ cell=%s, world=%s, ground=%s(%d), thing=%s(%d), type=%s, fertility=%.2f, animal=%s, insects=%s, occupied=%s }" % [
		cell,
		center,
		ground_name, g_id,
		thing_name, t_id,
		type,
		fertility,
		has_animal, has_insects,
		occupied
	]
