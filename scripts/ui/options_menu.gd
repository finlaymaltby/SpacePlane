extends Control

@onready var sensitivity = 10

func _on_h_slider_drag_ended(_value_changed: bool) -> void:
	GlobalSettings.sensitivity = $VBoxContainer/HSlider.value


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
