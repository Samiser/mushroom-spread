extends Node
class_name MushroomUI

var M: Mushroom
@export var line: Line2D 
@export var world_ui : Node3D
@export var growth_progress_bar : TextureProgressBar
@export var parent_label : RichTextLabel
@export var parent_info_ui : Sprite3D

@export var line_colors: Dictionary[Mushroom.MUSHROOM_MOOD, Color] = {
	Mushroom.MUSHROOM_MOOD.Likes: Color(0.45, 1.0, 0.45, 0.502),
	Mushroom.MUSHROOM_MOOD.Dislikes: Color(1.0, 0.46, 0.46, 0.502),
	Mushroom.MUSHROOM_MOOD.NoComment: Color(1.0, 1.0, 1.0, 0.5)
}

var tween : Tween

func setup(mushroom: Mushroom) -> void:
	M = mushroom
	world_ui.top_level = true
	world_ui.global_position = M.global_position
	world_ui.global_position.y += 0.02

func update(_delta: float) -> void:
	_draw_mood_lines()

func update_parent_ui(display: bool) -> void:
	if tween != null:
		if tween.is_running():
			tween.stop()
	
	tween = get_tree().create_tween()
	if !display:
		tween.tween_property(parent_info_ui, "modulate", Color.TRANSPARENT, 0.6)
		await tween.finished
		return
	tween.tween_property(parent_info_ui, "modulate", Color.WHITE, 0.2)
	
	var parent_text : String = "[b]%s[/b]
		%d/%d
		%d Life" % [
		M.mushroom_data.family_name, 
		M.mushroom_data.family.size(), 
		M.mushroom_data.max_family, 
		M.mushroom_data.family_health
		]
	parent_text = parent_text.replace("\t", "")
	parent_label.text = parent_text

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
		
		line.default_color = line_colors[M.tile_happiness]

func build_description() -> String:
	var growth_percent := roundf((M.growth / M.generational_max) * 100)
	var tile_string := M.grid.get_at_world(M.global_position).type_string()
	var increasing_health_colour := Color.GREEN
	if !M.mushroom_data.is_health_increasing:
		increasing_health_colour = Color.RED

	var desc: String = "Family:
		  %s (%s)
		  Size: %d/%d
		  Tile Rating: [color=%s]%d%%[/color]
		  Max Tile Capacity: %d
		  Health: [color=%s]%.f[/color]
		  %s
		Me:
		  Generation: %d
		  Growth: [color=%s]%.f%%[/color]
		  Tile: %s" % [
			M.mushroom_data.mushroom_name, M.mushroom_data.family_name,
			M.mushroom_data.family.size(), M.mushroom_data.max_family, 
			_color_progress_lerp(M.mushroom_data.tile_rating_percentage()).to_html(), M.mushroom_data.tile_rating_percentage(),
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
