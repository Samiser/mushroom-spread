extends Control

@export var summary_tile_rating: RichTextLabel
@export var summary_colony_size: RichTextLabel
@export var summary_capacity: RichTextLabel

@export var tiles_likes: RichTextLabel
@export var tiles_dislikes: RichTextLabel
@export var tiles_liked: RichTextLabel
@export var tiles_neutral: RichTextLabel
@export var tiles_disliked: RichTextLabel
@export var tiles_rating: RichTextLabel

@export var culls_manual: RichTextLabel
@export var culls_insect: RichTextLabel
@export var culls_animals: RichTextLabel
@export var culls_total: RichTextLabel

@export var next_day_button: Button

signal next_day

func _ready() -> void:
	next_day_button.pressed.connect(end_day)

func end_day() -> void:
	visible = false
	next_day.emit()

func _update_summary(M: Mushroom):
	var data: MushroomData = M.mushroom_data
	var prev_data: MushroomData = data.previous_data
	print(prev_data.family)
	
	if prev_data.family.size() <= 1:
		summary_tile_rating.text = "Tile Rating: %.f" % MushroomUI.get_tile_rating_percent(data)
		summary_colony_size.text = "Colony Size: %d" % data.family.size()
	else:
		summary_tile_rating.text = "Tile Rating: %.f -> %.f" % [MushroomUI.get_tile_rating_percent(prev_data), MushroomUI.get_tile_rating_percent(data)]
		summary_colony_size.text = "Colony Size: %d -> %d" % [prev_data.family.size(), data.family.size()]

func update_report(M: Mushroom):
	_update_summary(M)
