extends Control
class_name Report

@export var title: RichTextLabel

@export var summary_tile_rating: RichTextLabel
@export var summary_colony_size: RichTextLabel
@export var summary_capacity: RichTextLabel

@export var tiles_likes: RichTextLabel
@export var tiles_dislikes: RichTextLabel
@export var tiles_liked: RichTextLabel
@export var tiles_neutral: RichTextLabel
@export var tiles_disliked: RichTextLabel
@export var tiles_rating: RichTextLabel

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
	
	var cap_before := prev_data.max_family
	var health := float(data.family_health)
	var t: float = clamp(health / 100.0, 0.0, 1.0)
	var delta := int(round(2.0 + (16.0 - 2.0) * pow(t, 1.3)))  # +2..+16, eased
	var cap_after := cap_before + delta
	var col := "#63C74D" if delta >= 0 else "#DC4C46"

	if prev_data.family.size() <= 1:
		summary_tile_rating.text = "Health: %.f" % data.family_health
		summary_colony_size.text = "Colony Size: %d" % data.family.size()
	else:
		summary_tile_rating.text = "Health: %.f -> %.f" % [prev_data.family_health, data.family_health]
		summary_colony_size.text = "Colony Size: %d -> %d" % [prev_data.family.size(), data.family.size()]

	summary_capacity.text = "Capacity: %d -> %d [color=%s]%+d[/color] (health [color=%s]%.0f[/color] -> +%d)" % [cap_before, cap_after, col, delta, col, health, delta]

func _update_tiles(M: Mushroom) -> void:
	var data := M.mushroom_data
	if data == null:
		return

	# --- family likes/dislikes (BBCode so Tile.type_to_bbcode works) ---
	if tiles_likes:
		tiles_likes.bbcode_enabled = true
		var likes_bb := ", ".join(data.likes_tiles.map(Tile.type_to_bbcode)) if data.likes_tiles.size() > 0 else "[i]None[/i]"
		tiles_likes.text = "[b]Likes:[/b] " + likes_bb

	if tiles_dislikes:
		tiles_dislikes.bbcode_enabled = true
		var dislikes_bb := ", ".join(data.dislikes_tiles.map(Tile.type_to_bbcode)) if data.dislikes_tiles.size() > 0 else "[i]None[/i]"
		tiles_dislikes.text = "[b]Dislikes:[/b] " + dislikes_bb

	# --- counts ---
	var liked := data.liked_tiles_count
	var neutral := data.neutral_tiles_count
	var disliked := data.disliked_tiles_count
	# var total: int = max(1, liked + neutral + disliked)	# guard div-by-zero

	if tiles_liked: tiles_liked.text = "Liked: [color=%s]%d[/color]" % [Color.GREEN.to_html(), liked]
	if tiles_neutral: tiles_neutral.text = "Neutral: [color=%s]%d[/color]" % [Color.BEIGE.to_html(), neutral]
	if tiles_disliked: tiles_disliked.text = "Disliked: [color=%s]%d[/color]" % [Color.RED.to_html(), disliked]

	var health_change: int = (M.check_family_tiles()[0] * 4) - data.family.size()

	# --- rating ( (liked - disliked) / total ) ---
	var health := float(data.family_health)
	var col := Color.RED.lerp(Color.GREEN, clamp(health / 100.0, 0.0, 1.0)).to_html()

	var _sign := "+" if health_change >= 0 else "-"
	var new_health_string := "New Health: %d %s %d = [color=#%s]%.0f[/color]" % [data.previous_data.family_health, _sign, abs(health_change), col, health]

	if tiles_rating:
		tiles_rating.bbcode_enabled = true
		tiles_rating.text = "[b]Health Change:[/b] (([color=#%s]%d[/color] - [color=#%s]%d[/color]) * 4) - %d = %d\n%s" \
			% [Color.GREEN.to_html(), liked, Color.RED.to_html(), disliked, data.family.size(), health_change, new_health_string]
	
	
func update_report(M: Mushroom, day: int):
	title.text = "Day %d Report" % day
	_update_summary(M)
	_update_tiles(M)
