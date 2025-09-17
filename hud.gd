extends Control

@export var mushroom_description_label: RichTextLabel
@export var tile_description_label: RichTextLabel
@export var end_day_button: Button
@export var start_day_button: Button
@export var show_debug_button: Button

signal day_ended
signal day_started

func set_hover_desc(desc: String) -> void:
	mushroom_description_label.text = desc

func set_tile_info(info: String) -> void:
	tile_description_label.text = info

func end_day() -> void:
	end_day_button.visible = false
	start_day_button.visible = true
	day_ended.emit()

func start_day() -> void:
	end_day_button.visible = true
	start_day_button.visible = false
	day_started.emit()

func toggle_debug() -> void:
	mushroom_description_label.visible = !mushroom_description_label.visible
	tile_description_label.visible = !tile_description_label.visible

func _ready() -> void:
	end_day_button.visible = false
	end_day_button.pressed.connect(end_day)
	start_day_button.pressed.connect(start_day)
	show_debug_button.pressed.connect(toggle_debug)
	
