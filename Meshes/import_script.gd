@tool
extends EditorScenePostImport
class_name TypedMeshLibraryImporter

## -------- CONFIG --------
# Hard-coded types you want libraries for:
const HARD_TYPES := ["tree", "ground", "rock", "plant", "grass", "stump", "flower", "cliff"]

# Where to save each type's MeshLibrary:
var type_to_library_path := {
	"tree": "res://Meshes/libraries//tree_meshlib.tres",
	"ground": "res://Meshes/libraries/ground_meshlib.tres",
	"rock": "res://Meshes/libraries/rock_meshlib.tres",
	"plant": "res://Meshes/libraries/plant_meshlib.tres",
	"grass": "res://Meshes/libraries/grass_meshlib.tres",
	"stump": "res://Meshes/libraries/stump_meshlib.tres",
	"flower": "res://Meshes/libraries/flower_meshlib.tres",
	"cliff": "res://Meshes/libraries/cliff_meshlib.tres"
}

var fallback_library_path: String = "res://Meshes/libraries/misc_meshlib.tres"
var preview_size: int = 128
## ------------------------

func _post_import(scene: Node) -> Object:
	var source := get_source_file()
	var scene_name := scene.name            # <- Item name in the MeshLibrary
	var mesh_type := _extract_type(scene_name)
	var library_path := _resolve_library_path(mesh_type)

	if library_path.is_empty():
		push_warning("TypedMeshLibraryImporter: No library path for type '%s' (scene: %s). Skipping." % [mesh_type, scene_name])
		return scene

	print_rich("[b]Typed Mesh Import[/b]  %s  type=%s  -> %s" % [source, mesh_type, library_path])

	# Ensure directory exists for the .tres
	_ensure_dir_for_resource(library_path)

	# Load/create the library
	var mesh_lib := _load_or_create_meshlibrary(library_path)

	# Collect touched items (id + mesh) to make previews
	var touched: Array[Dictionary] = []
	_iterate_meshes(scene, func(mi: MeshInstance3D):
		_add_or_replace_by_scene_name(mi, mesh_lib, scene_name, touched)
	)

	# Generate previews for touched meshes
	_apply_previews(mesh_lib, touched)

	# Save the library
	var err := ResourceSaver.save(mesh_lib, library_path)
	if err != OK:
		push_error("Error saving MeshLibrary to %s (code %d)" % [library_path, err])
	else:
		print("Saved MeshLibrary: %s" % library_path)

	return scene


# --- helpers ---

func _extract_type(name: String) -> String:
	var lower := name.to_lower()
	var us := lower.find("_")
	return  lower.substr(0, us) if us >= 0 else lower

func _resolve_library_path(mesh_type: String) -> String:
	if mesh_type in HARD_TYPES and type_to_library_path.has(mesh_type):
		return String(type_to_library_path[mesh_type])
	return fallback_library_path

func _ensure_dir_for_resource(res_path: String) -> void:
	var dir := res_path.get_base_dir()
	if dir.is_empty():
		return
	var abs := ProjectSettings.globalize_path(dir)
	if not DirAccess.dir_exists_absolute(abs):
		var mk := DirAccess.make_dir_recursive_absolute(abs)
		if mk != OK:
			push_warning("Could not create folders for %s (code %d)" % [res_path, mk])

func _load_or_create_meshlibrary(path: String) -> MeshLibrary:
	var lib: MeshLibrary = null
	if ResourceLoader.exists(path):
		lib = ResourceLoader.load(path, "MeshLibrary")
		if lib == null:
			push_error("Failed to load MeshLibrary at %s, creating new." % path)
			lib = MeshLibrary.new()
	else:
		print_rich("Creating new MeshLibrary: [b]%s[/b]" % path)
		lib = MeshLibrary.new()
	return lib

func _iterate_meshes(node: Node, cb: Callable) -> void:
	if node is MeshInstance3D:
		cb.call(node)
	for c in node.get_children():
		_iterate_meshes(c, cb)

func _add_or_replace_by_scene_name(mi: MeshInstance3D, mesh_lib: MeshLibrary, item_name: String, touched: Array[Dictionary]) -> void:
	var mesh := mi.mesh
	if mesh == null:
		return
	var existing_id := _find_item_id_by_name(mesh_lib, item_name)
	if existing_id != -1:
		print("Updating mesh '%s' (id %d)" % [item_name, existing_id])
		mesh_lib.set_item_mesh(existing_id, mesh)
		touched.append({ "id": existing_id, "mesh": mesh })
		_sync_item_collision(mesh_lib, existing_id, mi)
	else:
		var id := mesh_lib.get_last_unused_item_id()
		print("Adding mesh '%s' as id %d" % [item_name, id])
		mesh_lib.create_item(id)
		mesh_lib.set_item_name(id, item_name)
		mesh_lib.set_item_mesh(id, mesh)
		touched.append({ "id": id, "mesh": mesh })
		_sync_item_collision(mesh_lib, id, mi)

func _find_item_id_by_name(mesh_lib: MeshLibrary, name: String) -> int:
	for id in mesh_lib.get_item_list():
		if mesh_lib.get_item_name(id) == name:
			return id
	return -1

func _apply_previews(mesh_lib: MeshLibrary, touched: Array[Dictionary]) -> void:
	if touched.is_empty():
		return
	var meshes: Array = []
	for t in touched:
		meshes.append(t["mesh"])
	var previews := EditorInterface.make_mesh_previews(meshes, preview_size)
	if previews.is_empty():
		push_warning("make_mesh_previews returned no previews.")
		return
	var count: int = min(previews.size(), touched.size())
	for i in count:
		var tex: Texture2D = previews[i]
		if tex == null:
			continue
		var id := int(touched[i]["id"])
		mesh_lib.set_item_preview(id, tex)

# Call this right after mesh_lib.set_item_mesh(item_id, mesh)
func _sync_item_collision(mesh_lib: MeshLibrary, item_id: int, mi: MeshInstance3D, prefer_convex := false) -> void:
	# Collect CollisionShape3D → shapes array [Shape3D, Transform3D, ...]
	var pairs := _collect_shapes_relative_to(mi)
	var shapes_arr: Array = []

	if pairs.size() > 0:
		for p in pairs:
			shapes_arr.append(p.shape)   # Shape3D
			shapes_arr.append(p.xform)   # Transform3D (relative to mi)
	else:
		# Fallback: generate from the mesh
		if mi.mesh:
			var shape: Shape3D = mi.mesh.create_convex_shape() if prefer_convex else mi.mesh.create_trimesh_shape()
			if shape:
				shapes_arr = [shape, Transform3D.IDENTITY]

	# In Godot 4, set all shapes at once (empty array clears)
	mesh_lib.set_item_shapes(item_id, shapes_arr)


func _collect_shapes_relative_to(mi: MeshInstance3D) -> Array:
	var out: Array = []
	_collect_shapes_dfs(mi, mi, out)
	return out

func _collect_shapes_dfs(n: Node, root: Node3D, out: Array) -> void:
	if n is CollisionShape3D:
		var cs := n as CollisionShape3D
		if cs.shape:
			out.append({
				"shape": cs.shape,
				"xform": _xform_relative_to(cs, root)
			})
	elif n is Node3D:
		for c in n.get_children():
			_collect_shapes_dfs(c, root, out)

func _xform_relative_to(child: Node3D, ancestor: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var cur: Node = child
	while cur and cur != ancestor:
		t = (cur as Node3D).transform * t
		cur = cur.get_parent()
	# If ancestor wasn’t found, fall back to identity
	return t
