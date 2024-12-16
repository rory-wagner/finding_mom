extends Node2D

var game = load("res://main_game.tscn")

var focused_node: Control

func _input(event: InputEvent):
	# see if the mouse moved to display mouse and hide cursor:
	if event is InputEventMouseMotion or event is InputEventMouseButton or event is InputEventKey:
		$SkipArea/SkipButtonSprite.play("keyboard")
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		$SkipArea/SkipButtonSprite.play("xbox")

# here we go through setting up the settings
func _ready():
	$SettingsMenu.load_settings()
	$SettingsMenu.apply_settings()
	$MainMenuCanvas/ReferenceRect/PLAY_BUTTON.grab_focus()
	focused_node = $MainMenuCanvas/ReferenceRect/PLAY_BUTTON
	
	$MenuThemeSong.play()
	
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
	$SkipArea.show()

func _on_opening_scene_finish():
	get_tree().change_scene_to_packed(game)

func _on_settings_button_pressed():
	if $MainMenuCanvas.visible:
		$MainMenuCanvas.hide()
		$SettingsMenu.show()
		$SettingsMenu.take_focus()
	else:
		$MainMenuCanvas.show()
		$MainMenuCanvas/ReferenceRect/PLAY_BUTTON.grab_focus()
		$SettingsMenu.hide()


func _on_menu_theme_song_finished():
	$MenuThemeSong.play()
