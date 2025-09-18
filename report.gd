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
	
	var cap_before := prev_data.max_family
	var rating_pct := float(data.tile_rating_percentage())
	var factor := 1.0 + rating_pct / 100.0
	var cap_after := int(roundf(float(cap_before) * factor))
	var delta := cap_after - cap_before
	var col := "#63C74D" if delta >= 0 else "#DC4C46"
	
	if prev_data.family.size() <= 1:
		summary_tile_rating.text = "Tile Rating: %.f%%" % data.tile_rating_percentage()
		summary_colony_size.text = "Colony Size: %d" % data.family.size()
	else:
		summary_tile_rating.text = "Tile Rating: %.f%% -> %.f%%" % [prev_data.tile_rating_percentage(), data.tile_rating_percentage()]
		summary_colony_size.text = "Colony Size: %d -> %d" % [prev_data.family.size(), data.family.size()]

	summary_capacity.text = "Capacity: %d → %d [color=%s]%+d[/color] (changed by [color=%s]%.0f%%[/color])" % [cap_before, cap_after, col, delta, col, rating_pct]


func update_report(M: Mushroom):
	_update_summary(M)
