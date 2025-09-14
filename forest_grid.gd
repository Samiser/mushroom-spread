extends Node3D
class_name GridMapPick

@export var ground_map_path: NodePath
@export var thing_map_paths: Array[NodePath] = []

var _ground: GridMap
var _things: Array[GridMap] = []

func _ready() -> void:
	_ground = get_node_or_null(ground_map_path) as GridMap
	_things.clear()
	for p in thing_map_paths:
		var m := get_node_or_null(p) as GridMap
		if m:
			_things.append(m)

func get_at_world(world_pos: Vector3) -> Dictionary:
	var result := {
		"ground": {},
		"thing": {}
	}

	if _ground:
		var gcell := world_to_cell(world_pos)
		var gid := _ground.get_cell_item(gcell)
		if gid != GridMap.INVALID_CELL_ITEM:
			result.ground = {
				"map": _ground,
				"cell": gcell,
				"id": gid,
				"name": _item_name(_ground, gid)
			}

	for m in _things:
		var cell := world_to_cell(world_pos)
		var id := m.get_cell_item(cell)
		if id == GridMap.INVALID_CELL_ITEM:
			continue
		result.thing = {
			"map": m,
			"cell": cell,
			"id": id,
			"name": _item_name(m, id)
		}
		break

	return result

func world_to_cell(world_pos: Vector3) -> Vector3i:
	var local := _ground.to_local(world_pos)
	return _ground.local_to_map(local)

func cell_to_world(cell: Vector3i) -> Vector3:
	var local_center := _ground.map_to_local(cell)
	return _ground.to_global(local_center)

func _item_name(gm: GridMap, item_id: int) -> String:
	return gm.mesh_library.get_item_name(item_id) if gm and gm.mesh_library else ""
