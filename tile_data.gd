extends Resource
class_name Tile

enum Type {TREE, PLANT, GRASS, STUMP, FLOWER, UNKNOWN_TYPE = -1}

var cell: Vector3i
var center: Vector3

var ground_id: int = GridMap.INVALID_CELL_ITEM
var ground_name: String = ""

var thing_id: int = GridMap.INVALID_CELL_ITEM
var thing_name: String = ""
var thing_map: GridMap = null

var type: Type = -1

var mushroom_count_max = 5

# mutable
var fertility: float = 1.0
var has_animal: bool = false
var has_insects: bool = false
var occupied: bool = false
var mushroom_count: int = 0

func type_string() -> String:
	return type_to_string(type)

static func type_to_string(type: Type) -> String:
	match type:
		Type.TREE: return "tree"
		Type.PLANT: return "plant"
		Type.GRASS: return "grass"
		Type.STUMP: return "stump"
		Type.FLOWER: return "flower"
	return "unknown type"

static func type_of_string(string: String) -> Type:
	match string:
		"tree": return Type.TREE
		"plant": return Type.PLANT
		"grass": return Type.GRASS
		"stump": return Type.STUMP
		"flower": return Type.FLOWER
	return Type.UNKNOWN_TYPE

func is_fully_occupied() -> bool:
	return mushroom_count >= mushroom_count_max 

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

func to_bbcode() -> String:
	var g_id := ground_id if ground_id != GridMap.INVALID_CELL_ITEM else -1
	var t_id := thing_id if thing_id != GridMap.INVALID_CELL_ITEM else -1
	var t_col := _type_color(type_to_string(type))

	var parts := []
	parts.append("[b]Tile info:[/b]\n[color=#888]cell[/color]=%s\n[color=#888]world[/color]=%s" % [cell, center])

	parts.append("\n[b]Ground:[/b] %s" % ground_name)

	if thing_id != GridMap.INVALID_CELL_ITEM:
		parts.append("\n[b]Thing:[/b] [color=%s]%s[/color]\n[b]type:[/b] [color=%s]%s[/color]" % [
			t_col, thing_name, t_col, type_to_string(type)
		])
	else:
		parts.append("\n[b]Thing:[/b] [color=#aaa]-[/color]")

	parts.append("\n[b]Fertility:[/b] %.2f" % fertility)

	parts.append("\n" + _bool_rich("Animal", has_animal) + "\n" + _bool_rich("Insects", has_insects) + "\n" + _bool_rich("Occupied", occupied))

	return "".join(parts)

func _bool_rich(label: String, on: bool) -> String:
	var c := "#67c23a" if on else "#9aa3ad"
	var sym := "true" if on else "false"
	return "[color=%s][b]%s[/b][/color]: [color=%s]%s[/color]" % ["#888", label, c, sym]

func _type_color(t: String) -> String:
	var lut := {
		"tree": "#69a34b",
		"flower": "#c94b7a",
		"plant": "#7fbf6b",
		"stump": "#9c6b3a",
		"log": "#8b6f4a",
		"": "#cccccc"
	}
	return String(lut.get(t.to_lower(), "#cccccc"))
