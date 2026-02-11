extends VSlider

const VAL_SPEED = 2
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if Input.is_action_pressed("thrust_up"):
		set_value(clamp(value + delta * VAL_SPEED, min_value, max_value))
	if Input.is_action_pressed("thrust_down"):
		set_value(clamp(value - delta * VAL_SPEED, min_value, max_value))

	$"../ThrustLabel".text = str(round(value * 100))
