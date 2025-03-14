extends CanvasLayer

signal player_die
signal start_game
signal level_complete
signal quit_game

@export var total_hearts = 3
@export var current_health = 3

@export var total_bullets = 3
@export var current_bullets = 3

@export var current_level = 0
@export var level_length = 80

var score = 0

var full_heart = load("res://Assets/Icons/heart.png")
var empty_heart = load("res://Assets/Icons/empty_heart.png")

var bullet = load("res://Assets/Bullets/basic_bullet.png")
var empty_bullet = load("res://Assets/Bullets/basic_empty_bullet.png")

# Called when the node enters the scene tree for the first time.
func _ready():
	show_controls()
	pass

# will handle event input
func _input(event: InputEvent):	
	# see if the mouse moved to display mouse and hide cursor:
	if event is InputEventMouseMotion or event is InputEventMouseButton or event is InputEventKey:
			display_control_type("keyboard")
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
			display_control_type("xbox")
		
		
func display_control_type(ct: String):
	$ControlsArea/ShootControlSprite.play(ct)
	$ControlsArea/ParryControlSprite.play(ct)
	$ControlsArea/RollControlSprite.play(ct)
	$ControlsArea/MoveControlSprite.play(ct)

func show_message(text):
	$ScoreLabel.text = text
	$ScoreLabel.show()

func show_game_over():
	show_message("game over")
	
func show_controls():
	$ControlsArea.show()
	display_control_type("keyboard")
	$AnimationPlayer.play("controls_dissappear")

func next_level():
	current_level += 1
	$LevelLabel.text = "Level " + String.num_int64(current_level)
	restart_score()
	
func get_level():
	return current_level
	
func restart_level():
	current_level = 0
	
func reset_health():
	# might need to reset total hearts as well if we end up giving more hearts
	current_health = total_hearts
	
func lose_heart():
	current_health -= 1
	display_hearts()
	if current_health <= 0:
		restart_level()
		player_die.emit()
		$DeathMessageTimer.start()
		show_message("Game Over")

		
func display_hearts():
	# clear all hearts
	var hearts = $HeartArea.get_children()
	for h in hearts:
		h.queue_free()
		
	
	# add each heart
	for i in range(total_hearts):
		var h = Area2D.new()
		var sprite = Sprite2D.new()
		if i < current_health:
			sprite.set_texture(full_heart)
		else:
			sprite.set_texture(empty_heart)

		#figure out display offset
		var position = Vector2.ZERO
		position.x = i * 120 + 60
		position.y = 60
		sprite.position = position

		# scale up the size
		sprite.scale = Vector2(6,6)
		
		# finally add it
		h.add_child(sprite)
		$HeartArea.add_child(h)
		
func reset_all_bullets():
	current_bullets = total_bullets
	display_bullets()

func reclaim_bullet():
	current_bullets += 1
	if current_bullets > total_bullets:
		current_bullets = total_bullets
	display_bullets()
	
func shoot_bullet():
	if current_bullets >= 1:
		current_bullets -= 1
		display_bullets()
		return true
	return false
		
func display_bullets():
	# clear all bullets
	var bullets = $BulletArea.get_children()
	for b in bullets:
		b.queue_free()
	
	# add each bullet
	for i in range(total_bullets):
		var b = Area2D.new()
		var sprite = Sprite2D.new()
		if i < current_bullets:
			sprite.set_texture(bullet)
		else:
			sprite.set_texture(empty_bullet)

		#figure out display offset
		var position = Vector2.ZERO
		position.x = i * 120 + 60
		position.y = -60
		sprite.position = position
		
		# need to scale up the size
		sprite.scale = Vector2(6,6)
		
		# finally add it
		b.add_child(sprite)
		$BulletArea.add_child(b)

func update_score():
	$ScoreLabel.text = str(level_length - score)
	if score >= level_length:
		$ScoreTimer.stop()
		reset_all_bullets()
		level_complete.emit()
		$ScoreLabel.text = "complete"

func _on_score_timer_timeout():
	score += 1
	update_score()
	
func restart_score():
	$ScoreTimer.start()	
	score = 0
	update_score()
	
func stop():
	$ScoreTimer.stop()


func _on_death_message_timer_timeout():
	$DeathSkipArea.show()
