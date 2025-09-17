@tool
extends Node3D
class_name GridOverlay

@export var gridmap_path: NodePath
@export var y_layer: int = 0					# which GridMap y-slice to draw on
@export var color: Color = Color(1, 1, 1, 0.35)	# line color (with alpha)
@export var y_offset: float = 0.02				# lift lines to avoid z-fight

var _grid: GridMap
var _instance: MeshInstance3D
var _im: ImmediateMesh

func _ready() -> void:
	_grid = get_node_or_null(gridmap_path) as GridMap
	_instance = MeshInstance3D.new()
	add_child(_instance)
	_im = ImmediateMesh.new()
	_instance.mesh = _im

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.disable_receive_shadows = true
	mat.metallic = 0.0
	mat.roughness = 1.0
	mat.albedo_color = color
	_instance.material_override = mat

	rebuild()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		rebuild()

func rebuild() -> void:
	if _grid == null:
		return

	var bx := Vector3.ZERO
	var bz := Vector3.ZERO
	# derive cell step vectors (world space) from map_to_local
	var o := _grid.map_to_local(Vector3i(0, y_layer, 0))
	var ox := _grid.map_to_local(Vector3i(1, y_layer, 0))
	var oz := _grid.map_to_local(Vector3i(0, y_layer, 1))
	bx = ox - o # step vector along +x cells
	bz = oz - o # step vector along +z cells

	var mnx: int
	var mxx: int
	var mnz: int
	var mxz: int

	# compute bounds from used cells on this y-layer
	var first := true
	for c in _grid.get_used_cells():
		var cell := c as Vector3i
		if cell.y != y_layer:
			continue
		if first:
			mnx = cell.x; mxx = cell.x; mnz = cell.z; mxz = cell.z
			first = false
		else:
			mnx = min(mnx, cell.x); mxx = max(mxx, cell.x)
			mnz = min(mnz, cell.z); mxz = max(mxz, cell.z)
	if first:
		# no cells on this layer; nothing to draw
		_im.clear_surfaces()
		return

	# build line surface
	_im.clear_surfaces()
	_im.surface_begin(Mesh.PRIMITIVE_LINES)
	_im.surface_set_color(color)

	var y_up := Vector3.UP * y_offset

	# draw vertical lines (constant x, varying z)
	for x in range(mnx, mxx + 2):
		var a := _grid.map_to_local(Vector3i(x, y_layer, mnz)) - 0.5 * bx - 0.5 * bz + y_up
		var b := _grid.map_to_local(Vector3i(x, y_layer, mxz + 1)) - 0.5 * bx - 0.5 * bz + y_up
		_im.surface_add_vertex(a)
		_im.surface_add_vertex(b)

	# draw horizontal lines (constant z, varying x)
	for z in range(mnz, mxz + 2):
		var a2 := _grid.map_to_local(Vector3i(mnx, y_layer, z)) - 0.5 * bx - 0.5 * bz + y_up
		var b2 := _grid.map_to_local(Vector3i(mxx + 1, y_layer, z)) - 0.5 * bx - 0.5 * bz + y_up
		_im.surface_add_vertex(a2)
		_im.surface_add_vertex(b2)

	_im.surface_end()
