extends Node2D

signal finish

var playing = false

# TODO: use the cinematic sfx in the scene

# on load: might want to display something
func _ready():
	$RobotBody/RobotSprite.play("sleep")
	$KidSprite.play("crying")
	$MomSprite.play("crying")
	$BadGuySprite.play("walk")
	$PortalBody/PortalSprite.play("spin")
	
func _process(_delta):
	if Input.is_action_just_pressed("pause") and playing:
		# skip scene:
		end()
	pass
	
func set_robot_falling():
	$RobotBody.flip_gravity_on()

# the main menu will call us when the Start Button is pressed
func start():
	playing = true
	# start the animation node
	$AnimationPlayer.play("opening")
	pass
	
func end():
	finish.emit()
	
func _on_robot_body_body_entered(_body):
	$RobotBody.queue_free()
	$PortalEnteredAudio.play()
