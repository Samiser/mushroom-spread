extends Control

@export var mushroom_description_label: RichTextLabel
@export var tile_description_label: RichTextLabel
@export var end_day_button: Button
@export var show_debug_button: Button

signal end_day

func set_hover_desc(desc: String) -> void:
	mushroom_description_label.text = desc

func set_tile_info(info: String) -> void:
	tile_description_label.text = info

func _end_day() -> void:
	end_day_button.visible = false
	end_day.emit()

func _toggle_debug() -> void:
	mushroom_description_label.visible = !mushroom_description_label.visible
	tile_description_label.visible = !tile_description_label.visible

func _ready() -> void:
	end_day_button.visible = false
	end_day_button.pressed.connect(_end_day)
	show_debug_button.pressed.connect(_toggle_debug)
	
