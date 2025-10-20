extends CharacterBody2D 

# ---all signals we emit---
signal entered_portal
signal freeze_frame(timeScale: float, duration: float)
signal hit
signal music_note(note)
signal reload
signal shoot(bullet: Resource, direction: float, location: Vector2)

# ---all variables needed---
@export var speed: float = 30000 # How fast the player will move (pixels/sec).
@export var roll_speed: float = 45000
@export var current_state = states.DEAD

# used for controller to remember which direction to rotate the cursor and sprite:
var last_direction_rotation = 0
var last_aim_direction = Vector2(1.0, 0.0).normalized()
var mouse_moved = false

# used for generating bullets and notes in the main_game
var PlayerBullet = preload("res://scenes/bullet.tscn")
var MusicNotes = preload("res://scenes/music_notes.tscn")

# used for animations
var show_flash = true
var right_music_note = true
var portal_position: Vector2

enum states {
	MOVE,
	PARRY,
	ROLL,
	DEAD,
	SHOOT,
	DISABLED,
}

func disable():
	current_state = states.DISABLED
	set_collisions(0)

func live_again():
	current_state = states.MOVE
	start_animations(Vector2.ZERO)

# ---functions---
func _ready():
	current_state = states.DEAD
	hide()
	$InvulnerableTimer.stop() # reset the timer
	_on_invulnerable_timer_timeout() # reset the shader

func start_animations(v: Vector2):
	if current_state == states.ROLL or current_state == states.PARRY:
			$Area2D/LegsSprite.play()
			$Area2D/BodySprite.play()
	elif current_state == states.MOVE or current_state == states.SHOOT:
		if v.length() > 0:
			$Area2D/LegsSprite.play()
			$Area2D/BodySprite.play()
		else:
			$Area2D/LegsSprite.stop()
			$Area2D/BodySprite.stop()

func display_pointer(display: bool):
	if display:
		$PointerSprite.show()
		$PointerSprite.play("point")
	else:
		$PointerSprite.hide()
		$PointerSprite.stop()

func set_portal(portal: Object):
	portal_position = portal.position

func portal_on_screen(on: bool):
	if on:
		$PointerSprite.hide()
	else:
		$PointerSprite.show()

func portal_process():
	if $PointerSprite.is_visible():
		# get the radius of the circle the pointer will be on
		const radius := 800
		var dist := portal_position - global_position
		dist = dist.normalized()
		#var rad := atan2(dist.y, dist.x)
		var final_pos := (dist * radius)

		$PointerSprite.position = final_pos
		$PointerSprite.look_at(portal_position)

# should only be handling inputs correlating to movement and moving the cursor
func _process(delta):
	if !get_is_dead():
		
		var v = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		# set last_direction_rotation for rolling
		if v.normalized() != Vector2.ZERO:
			last_direction_rotation = atan2(v.normalized().y, v.normalized().x)

		var speed_used = 0
		match current_state:
			states.MOVE, states.SHOOT:
				# might need to detect shooting here instead
				speed_used = speed
			states.PARRY:
				speed_used = speed
			states.ROLL:
				speed_used = roll_speed
			states.DEAD:
				speed_used = 0
		v = v.normalized() * speed_used * delta
		
		velocity = v
		move_and_slide()
		
		# animate if we have moved
		start_animations(v)
		
		var rotation_rads = atan2(v.y, v.x)
		
		# let the Legs update if in MOVE or PARRY. Let the Body update only in MOVE
		if v != Vector2.ZERO and (current_state == states.MOVE or current_state == states.SHOOT or current_state == states.PARRY):
			# need to figure out how much to rotate the player
			$Area2D/LegsSprite.set_rotation(rotation_rads)
			$Area2D/LegsSprite.animation = "walk"
			if current_state == states.MOVE:
				$Area2D/BodySprite.animation = "walk"
			elif current_state == states.SHOOT:
				$Area2D/BodySprite.animation = "shoot_walk"
		elif current_state == states.MOVE or current_state == states.SHOOT or current_state == states.PARRY:
			$Area2D/LegsSprite.animation = "stand"
			if current_state == states.MOVE:
				$Area2D/BodySprite.animation = "stand"
			elif current_state == states.SHOOT:
				$Area2D/BodySprite.animation = "shoot_stand"
		
		# aim for controller:
		var aim_direction := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
		
		# aim for mouse:
		var mouse_pos = get_global_mouse_position()
		var mouse_direction = mouse_pos - position

		var cursor_position = get_global_mouse_position()
		# if we are aiming with a controller:
		if aim_direction != Vector2.ZERO or !mouse_moved:
			#hide the mouse and show controller cursor
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
			$Cursor.show()
			
			#project cursor to proper position
			if aim_direction == Vector2.ZERO:
				aim_direction = last_aim_direction
			last_aim_direction = aim_direction
			var c_position = aim_direction.normalized() * 600
			$Cursor.position = c_position
			
			cursor_position = c_position + position
			
			# rotate the rest of the body and music notes
			$Area2D/BodySprite.look_at(cursor_position)
			$Area2D/CollisionBox.look_at(cursor_position)
			$WallCollision.look_at(cursor_position)
			mouse_moved = false
			
		#elif we are aiming with the mouse
		elif mouse_direction != Vector2.ZERO and mouse_moved:
			$Area2D/BodySprite.look_at(cursor_position)
			$Area2D/CollisionBox.look_at(cursor_position)
			$WallCollision.look_at(cursor_position)

		# check current state and see what actions we can take
		match current_state:
			states.MOVE, states.SHOOT: # can shoot, parry, roll, and reload
				if Input.is_action_just_pressed("shoot"):
					current_state = states.SHOOT
					shoot_bullet(cursor_position)
				if Input.is_action_just_pressed("parry"):
					current_state = states.PARRY
					parry()
				if Input.is_action_just_pressed("roll"):
					current_state = states.ROLL
					roll()
				#TODO: maybe remove if we don't want reloading? (make sure to remove all reloading functionality)
				#if Input.is_action_just_pressed("reload"):
					#reload_bullets()
			states.PARRY: # can do anything?
				pass
			states.ROLL: # cannot parry or shoot
				# change the body facing direction if we are currently rolling:
				$Area2D/BodySprite.set_rotation(last_direction_rotation)
				$Area2D/CollisionBox.set_rotation(last_direction_rotation)
				pass
			states.DEAD: # cannot do anything
				pass
	portal_process()
	
# emit a reload signal which will allow the player to shoot again
func reload_bullets():
	reload.emit()

# will handle event input
func _input(event):
	# see if the mouse moved to display mouse and hide cursor:
	if event is InputEventMouseMotion:
		mouse_moved = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		$Cursor.hide()

func roll():
	# reset all other actions:
	reset_shoot()
	set_collisions(0)
	$Area2D/BodySprite.animation = "roll"
	$Area2D/BodySprite.play()
	$Area2D/LegsSprite.play()
	$Area2D/LegsSprite.hide()
	
func set_collisions(c: int):
	$Area2D.collision_layer = c
	$Area2D.collision_mask = c
	
func set_parry_collisions(c: int):
	$ParryArea.collision_layer = c
	$ParryArea.collision_mask = c
	
func set_parry_all_collisions(c: int):
	$ParryAreaAll.collision_layer = c
	$ParryAreaAll.collision_mask = c

func shoot_bullet(cursor_position: Vector2):
	# generate a new bullet from the bullet_types in the right direction
	var pb = PlayerBullet.instantiate()
	pb.set_bullet(pb.bullet_types.PLAYER_BULLET)
	var start_position = $Area2D/BodySprite/ShootPoint.global_position
	var direction_vector = cursor_position - start_position
	var direction = atan2(direction_vector.y, direction_vector.x)
	pb.position = start_position
	shoot.emit(pb, direction, start_position)
	$ShootingAnimationTimer.start()
	#$ShootingAnimationTimer. # reset the timer
	return
	
func reset_shoot():
	$ShootingAnimationTimer.stop()
	
func parry():
	# reset all other actions:
	reset_shoot()
	set_parry_collisions(5)
	$ParryArea.rotation = $Area2D/BodySprite.rotation
	$Area2D/BodySprite.animation = "parry"
	$Area2D/BodySprite.play()
	$Area2D/LegsSprite.play()
	$ParryActiveTimer.start()
		
func start_invulnerability():
	set_collisions(0)
	$InvulnerableTimer.start()
	$VisibilityFlashTimer.start()
	_on_visibility_flash_timer_timeout()
	
func start(pos):
	position = pos
	show()
	$Area2D/CollisionBox.disabled = false

func get_is_dead():
	return current_state == states.DEAD
	
# When dead, display death animation
# When alive, display everything, reset collisions, and allow movement
func set_is_dead(d: bool):
	if d:
		current_state = states.DEAD
		$Area2D/BodySprite.play("death")
		$Area2D/LegsSprite.hide()
	else:
		set_collisions(5)
		current_state = states.MOVE
		$Area2D/LegsSprite.show()

func _on_invulnerable_timer_timeout():
	$VisibilityFlashTimer.stop()
	# reset collisions
	set_collisions(5)
	
	# old way of resetting transparency
	#$Area2D/BodySprite.modulate = Color(1, 1, 1, 1)
	#$Area2D/LegsSprite.modulate = Color(1, 1, 1, 1)
	
	show_flash = false
	$Area2D/BodySprite.material.set_shader_parameter("flash_white_on", show_flash)
	$Area2D/LegsSprite.material.set_shader_parameter("flash_white_on", show_flash)
	
func _on_visibility_flash_timer_timeout():
	show_flash = !show_flash
	$Area2D/BodySprite.material.set_shader_parameter("flash_white_on", show_flash)
	$Area2D/LegsSprite.material.set_shader_parameter("flash_white_on", show_flash)

# currently unused (might use if we like transparency shifts more)
func flash_transparency():
	if show_flash:
		$Area2D/BodySprite.modulate = Color(1, 1, 1, 1)
		$Area2D/LegsSprite.modulate = Color(1, 1, 1, 1)
	else:
		$Area2D/BodySprite.modulate = Color(1, 1, 1, 0.6)
		$Area2D/LegsSprite.modulate = Color(1, 1, 1, 0.2)
	pass

# emit the music note to the game
func _on_music_note_timer_timeout():
	if current_state != states.DEAD:
		var note = MusicNotes.instantiate()
		var location
		if right_music_note:
			location = $Area2D/BodySprite/RightSide.global_position
		else:
			location = $Area2D/BodySprite/LeftSide.global_position
		right_music_note = !right_music_note
		note.position = location
		music_note.emit(note)

func _on_area_2d_body_entered(body):
	if $InvulnerableTimer.is_stopped() and current_state != states.ROLL and current_state != states.DEAD:
		if body.is_in_group("player_bullets"):
			pass
		elif body.is_in_group("enemy_bullets"):
			lose_life()
			body.collide_with_target() # used to remove the bullet
		elif body.is_in_group("enemies"):
			lose_life()
		elif body.is_in_group("portals"):
			entered_portal.emit()
			display_pointer(false)
		else:
			pass

func lose_life():
	hit.emit()
	freeze_frame.emit(0.1, 0.3)
	start_invulnerability()

#reset everything after an animation is finished
func _on_body_sprite_animation_finished():
	if $Area2D/BodySprite.animation == "parry" and current_state == states.PARRY:
		$Area2D/BodySprite.animation = "stand"
		current_state = states.MOVE
	elif $Area2D/BodySprite.animation == "roll" and current_state == states.ROLL:
		$Area2D/BodySprite.animation = "stand"
		current_state = states.MOVE
		$Area2D/LegsSprite.show()
		set_collisions(5)
	pass

func _on_parry_area_body_entered(body):
	if body.is_in_group("enemy_bullets"):
		freeze_frame.emit(.1, 0.37)
		set_parry_all_collisions(4)
		$ParrySuccessTimer.start()
		# TODO: implement some shaders on successful parry
		
		# random pitch scale the audio for parry
		$ParryAudioPlayer.pitch_scale = .95 + (randf() * 0.1)
		$ParryAudioPlayer.play()
		pass

func _on_parry_area_all_body_entered(body):
	if body.is_in_group("bullets"):
		body.parried()

func _on_parry_success_timer_timeout():
	set_parry_all_collisions(0)
	$ParrySuccessTimer.stop()

func _on_parry_active_timer_timeout():
	set_parry_collisions(0)
	$ParryActiveTimer.stop()


func _on_shooting_animation_timer_timeout():
	if current_state != states.DEAD:
		current_state = states.MOVE
	$ShootingAnimationTimer.stop()
