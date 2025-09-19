extends Node3D

var main_scene = preload("res://main.tscn").instantiate()
@export var tutorial_button : Button
@export var play_button : Button

func _ready() -> void:
	$Environment.time_of_day = 0.8
	tutorial_button.pressed.connect(func() -> void: _load_main(true))
	play_button.pressed.connect(func() -> void: _load_main(false))

func _load_main(tutorials: bool) -> void:
	main_scene.tutorials_enabled = tutorials
	get_tree().root.add_child(main_scene)
	get_node("/root/MainMenu").queue_free()
	
