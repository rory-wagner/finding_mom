extends Node2D

var game = load("res://scenes/main_game.tscn")

var focused_node: Control

func _input(event: InputEvent):
	# see if the mouse moved to display mouse and hide cursor:
	if event is InputEventMouseMotion or event is InputEventMouseButton or event is InputEventKey:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		$SkipArea/SkipButtonSprite.play("keyboard")
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		$SkipArea/SkipButtonSprite.play("xbox")
		
func _process(_delta):
	var now = Time.get_unix_time_from_system()
	var new_position = Vector2($MainMenuCanvas/Title.position.x, $MainMenuCanvas/Title.position.y + (sin(now) / 2)) # sin(now) is the rate, dividing lessens the distance
	$MainMenuCanvas/Title.position = new_position

# here we go through setting up the settings
func _ready():
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
