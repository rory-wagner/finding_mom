extends Area2D

signal entered
signal exited

func _ready():
	$AnimatedSprite2D.play("spin")


func _on_visible_on_screen_notifier_2d_screen_entered():
	entered.emit()


func _on_visible_on_screen_notifier_2d_screen_exited():
	exited.emit()
