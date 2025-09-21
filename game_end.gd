extends Control

@export var title_label: RichTextLabel
@export var description_label: RichTextLabel

@export var rank_label: RichTextLabel
@export var colony_size_label: RichTextLabel
@export var tile_rating_label: RichTextLabel
@export var tiles_liked: RichTextLabel
@export var tiles_neutral: RichTextLabel
@export var tiles_disliked: RichTextLabel

@export var new_run_button: Button
@export var endless_button: Button

@export var _report: Report

signal endless

func _ready() -> void:
	new_run_button.pressed.connect(func() -> void: visible = false; get_tree().change_scene_to_file("res://main.tscn"))
	endless_button.pressed.connect(func() -> void: visible = false; endless.emit())

func calculate_rank(m: Mushroom) -> String:
	var THEORETICAL_BEST := 120
	var _size: int = m.mushroom_data.family.size()
	var health := m.mushroom_data.family_health

	var pct: float = clamp((float(_size) / float(THEORETICAL_BEST)) * 100.0, 0.0, 200.0)

	var ranks := [
		"[color=%s]D[/color]" % Color("DC4C46").to_html(),  # red
		"[color=%s]C[/color]" % Color("E59B2A").to_html(),  # amber
		"[color=%s]B[/color]" % Color("E9C46A").to_html(),  # yellow
		"[color=%s]A[/color]" % Color("63C74D").to_html(),  # green
		"[color=%s]S[/color]" % Color("FFD166").to_html()   # gold
	]
	var cuts := [0.0, 50.0, 70.0, 85.0, 95.0]

	var idx := 0
	if pct >= cuts[4]:
		idx = 4
	elif pct >= cuts[3]:
		idx = 3
	elif pct >= cuts[2]:
		idx = 2
	elif pct >= cuts[1]:
		idx = 1
	else:
		idx = 0

	# - Very low health (<35%) demotes one tier (if possible).
	# - Very good health (>=90%) can promote one tier if within 3% of the next cutoff.
	if health < 35.0 and idx > 0:
		idx -= 1
	elif health >= 90.0 and idx < ranks.size() - 1 and pct >= cuts[idx + 1] - 3.0:
		idx += 1

	return ranks[idx]

func show_end_screen(m: Mushroom, day: int, win: bool = true):
	title_label.text = "Victory!" if win else "Game Over!"
	description_label.text = "You made it to day %d! Here's your final stats:" % day if win else "Your colony met an unfortunate demise! Here's your final stats:"

	rank_label.text = "Rank: %s" % "A"
	rank_label.visible = win

	colony_size_label.text = "Final Colony Size: %d" % m.mushroom_data.family.size()
	tile_rating_label.text = "Final Health: %.f" % m.mushroom_data.family_health

	tiles_liked.text = _report.tiles_liked.text
	tiles_neutral.text = _report.tiles_neutral.text
	tiles_disliked.text = _report.tiles_disliked.text

	endless_button.visible = win

	visible = true
