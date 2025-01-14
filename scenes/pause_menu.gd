extends Node

signal resume
signal return_menu

func _on_resume_button_pressed():
	resume.emit()

func _on_settings_button_pressed():
	if $MainPauseMenu.visible:
		$MainPauseMenu.hide()
		$SettingsMenu.show()
		$SettingsMenu.take_focus()
	else:
		$MainPauseMenu.show()
		$SettingsMenu.hide()
		take_focus()

func _on_quit_button_pressed():
	return_menu.emit()

func _process(_delta):
	if Input.is_action_just_pressed("pause"):
		_on_resume_button_pressed()
	pass
	
# this grabs the focus when the menu or settings is switched to this scene
func take_focus():
	$MainPauseMenu/ReferenceRect/ResumeButton.grab_focus()
