extends CanvasLayer

var all_controller_types = ["keyboard", "xbox", "playstation", "nintendo"]

func display_control_type(ct: String):
	if not ct in all_controller_types:
		return FAILED
	$ReferenceRect/ShootControlSprite.play(ct)
	$ReferenceRect/ParryControlSprite.play(ct)
	$ReferenceRect/RollControlSprite.play(ct)
	$ReferenceRect/MoveControlSprite.play(ct)
	#$ReferenceRect/ReloadControlSprite.play(ct)
	return OK

func start_modulate():
	$AnimationPlayer.play("controls_dissappear")
