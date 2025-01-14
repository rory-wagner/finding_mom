extends Node2D

signal exited(n: Node2D)
signal entered(n: Node2D)


func _on_visible_on_screen_notifier_2d_screen_entered():
	entered.emit(self)

func _on_visible_on_screen_notifier_2d_screen_exited():
	exited.emit(self)
	
