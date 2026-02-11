class_name Game extends Node

@onready var gameoverScene : PackedScene = preload("res://scenes/ui/gameover_menu.tscn")

func end_game() -> void:
	reset()
	var gameover = gameoverScene.instantiate()
	get_tree().current_scene.add_child(gameover)
	get_tree().paused = true

func reset() -> void:
	%Player.reset()
	%MissileSpawner.reset()
