extends Node3D
class_name ForestGrid

@export var ground_map_path: NodePath
@export var thing_map_paths: Array[NodePath] = []

var _ground: GridMap
var _things: Array[GridMap] = []

var _tiles: Dictionary[Vector3i, Tile] = {}

func _ready() -> void:
	_ground = get_node_or_null(ground_map_path) as GridMap
	_things.clear()
	for p in thing_map_paths:
		var m := get_node_or_null(p) as GridMap
		if m:
			_things.append(m)
	_build_index()

func _build_index() -> void:
	_ground = get_node_or_null(ground_map_path) as GridMap
	_tiles.clear()
	if _ground == null:
		push_error("ground_map_path not set")
		return
	
	for cell in _ground.get_used_cells():
		var data := Tile.new()
		data.cell = cell
		data.center = cell_to_world(cell)
		
		var ground_id := _ground.get_cell_item(cell)
		if ground_id != GridMap.INVALID_CELL_ITEM:
			data.ground_id = ground_id
			data.ground_name = _item_name(_ground, ground_id)
		
		var thing: Dictionary = {}
		for map: GridMap in _things:
			var map_cell := world_to_cell_on_map(data.center, map)
			var id := map.get_cell_item(map_cell)
			if id != GridMap.INVALID_CELL_ITEM:
				thing = {
					"map": map,
					"id": id,
					"cell": map_cell,
					"name": _item_name(map, id)
				}
				break

		if thing != {}:
			data.thing_map = thing.map
			data.thing_id = thing.id
			data.thing_name = thing.name
			data.type = _infer_type_from_name(thing.name)

		_tiles[cell] = data

func get_at_world(world_pos: Vector3) -> Tile:
	var cell := world_to_cell(world_pos)
	return get_tile(cell)

func get_tile(cell: Vector3i) -> Tile:
	return _tiles.get(cell, null)

func neighbors4(cell: Vector3i) -> Array[Vector3i]:
	return [
		cell + Vector3i(1,0,0),
		cell + Vector3i(-1,0,0),
		cell + Vector3i(0,0,1),
		cell + Vector3i(0,0,-1)
	]

func _item_name(gm: GridMap, item_id: int) -> String:
	return gm.mesh_library.get_item_name(item_id) if gm and gm.mesh_library else ""

func _infer_type_from_name(thing_name: String) -> Tile.Type:
	if thing_name == "":
		return Tile.Type.UNKNOWN_TYPE
	var i := thing_name.find("_")
	var thing_type: String = thing_name if i == -1 else thing_name.substr(0, i)
	return Tile.type_of_string(thing_type)

func world_to_cell(world_pos: Vector3) -> Vector3i:
	var local := _ground.to_local(world_pos)
	return _ground.local_to_map(local)

func cell_to_world(cell: Vector3i) -> Vector3:
	var local_center := _ground.map_to_local(cell)
	return _ground.to_global(local_center)

func world_to_cell_on_map(world_pos: Vector3, grid: GridMap = _ground) -> Vector3i:
	var local := grid.to_local(world_pos)
	return grid.local_to_map(local)
