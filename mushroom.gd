extends Node3D

var growth := 0.1
var grow_speed := 0.1
var max_growth := 1.0
@onready var mesh := $mushroom_mesh
@onready var mushroom_baby := load("res://mushroom.tscn")
var tween : Tween

func _ready() -> void:
	$Area3D.input_event.connect(_on_area_input_event)

func _process(delta: float) -> void:
	if growth > max_growth:
		return
	
	if tween != null && tween.is_running():
			return
	
	growth += delta * grow_speed
	scale = Vector3.ONE * growth

func _on_area_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int):
	if event is InputEventMouseButton and event.is_pressed():
		if tween != null && tween.is_running():
			return
		
		if growth >= max_growth:
			growth = 0.2
			
			var count := randi_range(1, 4)
			while count > 0:
				var new_mushroom :Node3D= mushroom_baby.instantiate()
				get_parent().add_child(new_mushroom)
				var spawn_offset := Vector3(randf_range(-1, 1), 0.0, randf_range(-1, 1)).normalized() * 0.25 * count
				new_mushroom.global_position = global_position + spawn_offset
				count -= 1
