extends Control

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
	
	var cap_before := prev_data.max_family
	var rating_pct := float(data.tile_rating_percentage())
	var t: float = clamp(rating_pct / 100.0, 0.0, 1.0)
	var delta := int(round(2.0 + (16.0 - 2.0) * pow(t, 1.3)))  # +2..+16, eased
	var cap_after := cap_before + delta
	var col := "#63C74D" if delta >= 0 else "#DC4C46"

	if prev_data.family.size() <= 1:
		summary_tile_rating.text = "Tile Rating: %.f%%" % data.tile_rating_percentage()
		summary_colony_size.text = "Colony Size: %d" % data.family.size()
	else:
		summary_tile_rating.text = "Tile Rating: %.f%% -> %.f%%" % [prev_data.tile_rating_percentage(), data.tile_rating_percentage()]
		summary_colony_size.text = "Colony Size: %d -> %d" % [prev_data.family.size(), data.family.size()]

	summary_capacity.text = "Capacity: %d → %d [color=%s]%+d[/color] (rating [color=%s]%.0f%%[/color] → +%d)" % [cap_before, cap_after, col, delta, col, rating_pct, delta]

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
	var total: int = max(1, liked + neutral + disliked)	# guard div-by-zero

	if tiles_liked: tiles_liked.text = "Liked: [color=%s]%d[/color]" % [Color.GREEN.to_html(), liked]
	if tiles_neutral: tiles_neutral.text = "Neutral: [color=%s]%d[/color]" % [Color.BEIGE.to_html(), neutral]
	if tiles_disliked: tiles_disliked.text = "Disliked: [color=%s]%d[/color]" % [Color.RED.to_html(), disliked]

	# --- rating ( (liked - disliked) / total ) ---
	var rating_pct := float(data.tile_rating_percentage())
	var col := Color.RED.lerp(Color.GREEN, clamp(rating_pct / 100.0, 0.0, 1.0)).to_html()

	if tiles_rating:
		tiles_rating.bbcode_enabled = true
		tiles_rating.text = "[b]Rating:[/b] ([color=#%s]%d[/color] − [color=#%s]%d[/color]) / [color=#%s]%d[/color] = [color=#%s]%.0f%%[/color]" \
			% [Color.GREEN.to_html(), liked, Color.RED.to_html(), disliked, Color.BEIGE.to_html(), total, col, rating_pct]
	
	

func update_report(M: Mushroom, day: int):
	title.text = "Day %d Report" % day
	_update_summary(M)
	_update_tiles(M)
