extends Control

@export var mushroom_description_label: RichTextLabel
@export var tile_description_label: RichTextLabel
@export var end_day_button: Button
@export var show_debug_button: Button

var day_ended := false

signal end_day 

func set_hover_desc(desc: String) -> void:
	mushroom_description_label.text = desc
	
func display_parent_info(text: String) -> void:
	if day_ended:
		$HoverInfo.visible = false
		return
	
	$HoverInfo.visible = true
	$HoverInfo/parent_label.text = text

func set_tile_info(info: String) -> void:
	tile_description_label.text = info

func _end_day() -> void:
	$HoverInfo.visible = false
	day_ended = true
	end_day_button.visible = false
	end_day.emit()

func on_cap_reached() -> void:
	end_day_button.visible = true

func _toggle_debug() -> void:
	mushroom_description_label.visible = !mushroom_description_label.visible
	tile_description_label.visible = !tile_description_label.visible

func _ready() -> void:
	end_day_button.visible = false
	end_day_button.pressed.connect(_end_day)
	show_debug_button.pressed.connect(_toggle_debug)
	
