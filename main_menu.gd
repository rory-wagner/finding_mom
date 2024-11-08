extends Node2D

var game = load("res://main_game.tscn")

var focused_node: Control

# here we go through setting up the settings
func _ready():
	$SettingsMenu.load_settings()
	$SettingsMenu.apply_settings()
	$MainMenuCanvas/PLAY_BUTTON.grab_focus()
	focused_node = $MainMenuCanvas/PLAY_BUTTON
	
	get_viewport().connect("gui_focus_changed", focus_changed)
	
func focus_changed(node: Control):
	focused_node = node
	pass

func _on_quit_button_pressed():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit(0)

func _on_play_button_pressed():
	#turn off buttons and start the first scene
	$MainMenuCanvas.hide()
	$OpeningScene.start()
	$SkipLabel.show()

func _on_opening_scene_finish():
	get_tree().change_scene_to_packed(game)

func _on_settings_button_pressed():
	if $MainMenuCanvas.visible:
		$MainMenuCanvas.hide()
		$SettingsMenu.show()
		$SettingsMenu.take_focus()
	else:
		$MainMenuCanvas.show()
		$MainMenuCanvas/PLAY_BUTTON.grab_focus()
		$SettingsMenu.hide()
