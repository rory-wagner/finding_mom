extends Node2D

func _ready():
	$ReferenceRect/SteamSprite/LinkButton.grab_focus()
	
func _input(event: InputEvent):
	# see if the mouse moved to display mouse and hide cursor:
	if event is InputEventMouseMotion or event is InputEventMouseButton or event is InputEventKey:
		$SkipArea/SkipButtonSprite.play("keyboard")
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		$SkipArea/SkipButtonSprite.play("xbox")
	
func _process(_delta):
	if Input.is_action_just_pressed("pause"):
		get_tree().quit(0)
