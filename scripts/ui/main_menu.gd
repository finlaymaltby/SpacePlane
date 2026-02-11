extends Control



func _on_start_pressed() -> void:
	$VBoxContainer/Start.text = "LOADING"
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://scenes/game.tscn")
	
func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/options_menu.tscn")

func _on_lore_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/lore.tscn")
	
func _on_quit_pressed() -> void:
	get_tree().quit()
