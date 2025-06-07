extends Node2D

var menu

func _ready():
	$Timer.start()
	# start loading the main_menu
	menu = load("res://scenes/main_menu.tscn")

func _on_timer_timeout():
	# switch to the main_menu
	get_tree().change_scene_to_packed(menu)
