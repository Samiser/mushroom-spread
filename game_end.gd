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
	new_run_button.pressed.connect(func() -> void: visible = false; get_tree().change_scene_to_file("res://main_menu.tscn"); get_node("/root/Main").queue_free())
	endless_button.pressed.connect(func() -> void: visible = false; endless.emit())

func calculate_rank(_m: Mushroom) -> String:
	return "A"

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
