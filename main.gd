extends Node3D

func _process(delta: float) -> void:
	$CameraPivot.rotation_degrees.y += 5 * delta
	#$DirectionalLight3D.rotation_degrees.x -= 3 * delta
