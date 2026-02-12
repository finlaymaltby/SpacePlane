extends VSlider

const val_speed = 2

func _process(delta: float) -> void:
	
	if Input.is_action_pressed("thrust_up"):
		set_value(clamp(value + delta * val_speed, min_value, max_value))
	if Input.is_action_pressed("thrust_down"):
		set_value(clamp(value - delta * val_speed, min_value, max_value))

	$"../ThrustLabel".text = str(round(value * 100))
