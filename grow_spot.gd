extends Node3D

@onready var _area: Area3D = $Area3D

func _on_area_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int):
	if event is InputEventMouseButton and event.is_pressed():
		$OmniLight3D.visible = !$OmniLight3D.visible

func _ready() -> void:
	_area.input_event.connect(_on_area_input_event)
