extends Node3D
class_name ScentMarker

const duration = 30
var id : int = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Timer.wait_time = duration
	$Timer.start()


func _on_timer_timeout() -> void:
	queue_free()
