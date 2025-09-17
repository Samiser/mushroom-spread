extends Node
class_name MushroomUI

var M: Mushroom
@export var line: Line2D 
@export var world_ui : Node3D
@export var growth_progress_bar : TextureProgressBar
@export var parent_label : RichTextLabel

func setup(mushroom: Mushroom) -> void:
	M = mushroom
	world_ui.top_level = true
	world_ui.global_position = M.global_position
	world_ui.global_position.y += 0.04
	update_parent_ui()

func update(_delta: float) -> void:
	_draw_mood_lines()

func update_parent_ui() -> void:
	parent_label.text = "[b]" + M.parent.mushroom_data.family_name + "[/b]\n" + str(M.parent.mushroom_data.family.size()) + "/" + str(M.parent.mushroom_data.max_family)

func display_progress_bar() -> void:
	var progress := M.growth / M.generational_max
	growth_progress_bar.value = progress
	growth_progress_bar.modulate = _color_progress_lerp(progress * 100.0)
	growth_progress_bar.visible = progress < 1.0

func _draw_mood_lines() -> void:
	if M.generation > 0:
		var cam := get_viewport().get_camera_3d()
		line.set_point_position(0, cam.unproject_position(M.global_position))
		line.set_point_position(1, cam.unproject_position(M.last_in_tree.global_position))
		
		match M.tile_happiness:
			M.MUSHROOM_MOOD.Likes:
				line.default_color = Color.GREEN
			M.MUSHROOM_MOOD.Dislikes:
				line.default_color = Color.RED
			M.MUSHROOM_MOOD.NoComment:
				line.default_color = Color.WHITE

func build_description() -> String:
	var growth_percent := roundf((M.growth / M.generational_max) * 100)
	var tile_rating_percent := roundf((M.mushroom_data.tile_rating[0] as float / M.mushroom_data.tile_rating[1]) * 100.0)
	var tile_string := M.grid.get_at_world(M.global_position).type_string()
	var increasing_health_colour := Color.GREEN
	if !M.mushroom_data.is_health_increasing:
		increasing_health_colour = Color.RED

	var desc: String = "Family:
		  %s (%s)
		  Size: %d/%d
		  Tile Rating: [color=%s]%.f%%[/color]
		  Max Tile Capacity: %d
		  Health: [color=%s]%.f[/color]
		  %s
		Me:
		  Generation: %d
		  Growth: [color=%s]%.f%%[/color]
		  Tile: %s" % [
			M.mushroom_data.mushroom_name, M.mushroom_data.family_name,
			M.mushroom_data.family.size(), M.mushroom_data.max_family, 
			_color_progress_lerp(tile_rating_percent).to_html(), tile_rating_percent,
			M.mushroom_data.tile_capacity,
			increasing_health_colour.to_html(), M.mushroom_data.family_health,
			_preferences_string(),
			M.generation,
			_color_progress_lerp(growth_percent).to_html(), growth_percent, 
			tile_string,
		]

	return desc.replace("\t", "")

func _preferences_string() -> String:
	return "Likes: %s\n  Dislikes: %s" % [
		", ".join(M.mushroom_data.likes_tiles.map(Tile.type_to_bbcode)),
		", ".join(M.mushroom_data.dislikes_tiles.map(Tile.type_to_bbcode))
	]

func _color_progress_lerp(percent: float) -> Color:
	return lerp(Color.RED, Color.GREEN, percent / 100.0)
