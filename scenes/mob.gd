extends CharacterBody2D

signal shoot(bullet, direction, location)

@export var use_shaders = false

var type = "soldier"

var available_mob_types = [
	"soldier",
	"spider",
	"drone",
]

var player = null

enum states {
	MOVE,
	DEAD,
	SHOOT,
}

var current_state = states.MOVE
var ready_shoot = true
var burn_value = 1.0

var Bullet = preload("res://scenes/bullet.tscn")

func set_type(t: String):
	# default if not found
	if available_mob_types.find(t) == -1:
		t = "spider"
	type = t
	$AnimatedSprite2D.play(type)
	if type == "bug":
		# Add some randomness to the direction.
		velocity = Vector2(randi_range(-360, 360), randi_range(-360, 360)).normalized() * 360
		rotation = atan2(velocity.normalized().y, velocity.normalized().x)
	return

func start_animations(v: Vector2):
	if current_state == states.MOVE:
		if v.length() > 0:
			$AnimatedSprite2D.play()
		else:
			$AnimatedSprite2D.stop()

func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	match type:
		"bug":
			move_bug()
		"spider":
			move_spider()
		"soldier":
			move_soldier()
		"drone":
			move_drone()
	if current_state == states.DEAD and use_shaders:
		update_burn_value()

func update_burn_value():
	burn_value = burn_value - 0.01
	$AnimatedSprite2D.material.set_shader_parameter("dissolve_value", burn_value)
	# once burn_value hits 0.0, dequeue
	if burn_value <= 0.0:
		_on_dead_sprites_animation_finished()
	
func move_bug():
	if ready_shoot == true:
		shoot_bullet()
		
	# the velocity was set at _ready, we can just call move_and_slide()
	move_and_slide()
	
func move_spider():
	if current_state != states.DEAD:
		look_at(player.position)
		var distance: Vector2 = player.position - position
		var motion: Vector2 = distance.normalized()
		motion = motion * 500
		velocity = motion
		move_and_slide()
		
		# the spider will show glowing red eyes if within 450 of player:
		var spider_dist = 450
		if distance.length() < spider_dist and $AnimatedSprite2D.animation == "spider":
			var frame = $AnimatedSprite2D.frame
			$AnimatedSprite2D.play("spider_attack")
			$AnimatedSprite2D.frame = frame
		elif distance.length() >= spider_dist and $AnimatedSprite2D.animation == "spider_attack":
			var frame = $AnimatedSprite2D.frame
			$AnimatedSprite2D.play("spider")
			$AnimatedSprite2D.frame = frame
		
func move_soldier():
	var v = Vector2(0.0, 0.0)
	if player != null:
		v = player.position - position
	var distance_to_player = sqrt((v.x * v.x) + (v.y * v.y))
	
	#logic for shooting at player
	if current_state == states.SHOOT:
		if player != null:
			look_at(player.position)
		if ready_shoot:
			change_living_texture("soldier_attack", false)
		# if we aren't shooting and the player is far away, switch back to MOVE
		elif distance_to_player > 600 and $AnimatedSprite2D.animation != "soldier_attack" and $AnimatedSprite2D.animation != "soldier_attack_end": 
			current_state = states.MOVE

	elif current_state == states.DEAD:
		velocity = Vector2(0, 0)

	#logic for tracking player
	elif current_state == states.MOVE:
		if player != null:
			look_at(player.position)
		if distance_to_player > 600:
			var motion = player.position
			motion = motion - position
			motion = motion.normalized()
			motion = motion * 350
			velocity = motion
		else:
			velocity = Vector2.ZERO
			if ready_shoot:
				current_state = states.SHOOT
				change_living_texture("soldier_attack", false)

	start_animations(velocity)
	move_and_slide()
	
func move_drone():
	var v = Vector2(0.0, 0.0)
	if player != null:
		v = player.position - position
	var distance_to_player = sqrt((v.x * v.x) + (v.y * v.y))
	
	match current_state:
		states.DEAD:
			velocity = Vector2.ZERO
		states.MOVE:
			if player != null:
				look_at(player.position)
			var motion = player.position
			motion = motion - position
			motion = motion.normalized()
			motion = motion * 300
			if distance_to_player > 1000:
				velocity = motion
			else:
				velocity = Vector2(-motion.y, motion.x)
			if ready_shoot:
				current_state = states.SHOOT
				shoot_bullet()
		states.SHOOT:
			current_state = states.MOVE
	move_and_slide()

# called by main game to let us know where the player is
func set_player(p):
	player = p

func _on_bullet_timer_timeout():
	if current_state != states.DEAD:
		ready_shoot = true

func shoot_bullet():
	var b = Bullet.instantiate()
	var bt
	match type:
		"bug":
			bt = b.bullet_types.PURPLE_BALL
		"spider":
			bt = b.bullet_types.PURPLE_BALL
		"soldier":
			bt = b.bullet_types.SOLDIER_BULLET
		"drone":
			#TODO: implement tracking for the missile
			bt = b.bullet_types.DRONE_MISSILE
			#bt = b.bullet_types.PURPLE_BALL
		_:
			bt = b.bullet_types.PURPLE_BALL
	b.set_bullet(bt)
	# get the global units of the ShootPoint
	var global_point = $AnimatedSprite2D/ShootPoint.global_position
	# direction_vector = player(in global units) - starting_point
	var direction_vector = player.position - global_point
	# get the rotation in rads
	var r = atan2(direction_vector.y, direction_vector.x)
	shoot.emit(b, r, global_point)
	ready_shoot = false

func _on_dead_sprites_animation_finished():
	queue_free()

func _on_animated_sprite_2d_animation_looped():
	if $AnimatedSprite2D.animation == "soldier_attack":
		change_living_texture("soldier_attack_end", false)
		shoot_bullet()
	elif $AnimatedSprite2D.animation == "soldier_attack_end":
		change_living_texture("soldier", true)
		current_state = states.MOVE
		
func change_living_texture(animation, repeat):
	$AnimatedSprite2D.play(animation)
	$AnimatedSprite2D.texture_repeat = repeat

func _on_area_2d_body_entered(body):
	if body.is_in_group("player_bullets"):
		if use_shaders:
			# Get the material from the node
			var original_material = $AnimatedSprite2D.material
			# Duplicate the material AND make sure it's a new ShaderMaterial instance
			var unique_material = original_material.duplicate()
			unique_material.set_shader(original_material.shader)
			# Apply it back to just this node
			$AnimatedSprite2D.material = unique_material
			# Now change your shader param safely
			$AnimatedSprite2D.material.set_shader_parameter("dissolve_value", burn_value)
		else:
			$AnimatedSprite2D.stop()
			$AnimatedSprite2D.hide()
			$DeadSprites.look_at(player.position)
			$DeadSprites.show()
			$DeadSprites.play(type)

		current_state = states.DEAD
		# remove from both layers of collision
		collision_layer = 0
		collision_mask = 0
		$Area2D.collision_layer = 0
		$Area2D.collision_mask = 0
		# used to remove the bullet
		body.collide_with_target()
