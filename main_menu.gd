extends Node3D

func _ready() -> void:
	$Environment.time_of_day = 0.8
	$Control/VBoxContainer/Button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://main.tscn"))
