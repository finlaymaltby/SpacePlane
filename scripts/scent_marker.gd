extends Node3D
class_name ScentMarker

const duration: float = 30.0
var id: int = 0

func _ready() -> void:
	$Timer.wait_time = duration
	$Timer.start()


func _on_timer_timeout() -> void:
	queue_free()
