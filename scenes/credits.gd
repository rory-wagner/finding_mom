extends Node2D


func _process(_delta):
	if Input.is_action_just_pressed("pause"):
		# TODO: eventually change this to change scenes
		get_tree().quit(0)
		

func _input(_event):
	$ExitTimer.start(3.0)
	$SkipArea.show()


func _on_exit_timer_timeout():
	$SkipArea.hide()
