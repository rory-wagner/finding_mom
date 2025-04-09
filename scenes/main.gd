extends Node

@export var mob_scene: PackedScene

@export var is_demoing = true
@export var music_on = true

func _ready():
	new_game()

func _process(_delta):
	if $Player.current_state == $Player.states.DEAD:
		if Input.is_action_just_pressed("pause"):
			_on_pause_menu_return_menu()

func _on_pause_menu_resume():
	flip_pause_screen()

func flip_pause_screen():
	if !get_tree().paused:
		get_tree().paused = true
		$PauseMenu.show()
		$PauseMenu.take_focus()
	elif get_tree().paused:
		get_tree().paused = false
		$PauseMenu.hide()

func game_over():
	$HUD.stop()
	$Level.stop_spawning()
	$HUD.show_game_over()
	#$Music.stop()#TODO: call level stop_music???
	$DeathSound.play()
	
	$Player.set_is_dead(true)

#this function is called every time the start button is pressed
func new_game():
	play_next_level()
	$Player.live_again()

func play_next_level():
	kill_all_active_things()
	$DeathSound.stop()

	$HUD.display_hearts()
	$HUD.display_bullets()
	
	$Player.start($StartPosition.position)
	$Player.set_is_dead(false)
	
	$Level.next_level()
	$Level.start_spawning()
	
	$HUD.set_level($Level.get_level())
	$HUD.set_level_length($Level.get_level_length())
	
	if music_on:
		$Level.start_music()
	
func _on_player_shoot(bullet, direction, _location):
	# check to see if Player is alive and has bullets to shoot
	if $Player.get_is_dead and $HUD.shoot_bullet():
		#order matters here
		bullet.set_direction(direction)
		bullet.set_is_player_bullet()
		add_child(bullet)
		bullet.play_sound()
		bullet.player_bullet_dequeue.connect(_on_player_bullet_dequeue)
		
func _on_player_music_note(note):
	add_child(note)

func _on_level_spawn_mob(mob):
	# let the mob know where the player is to attack
	mob.set_player($Player)
	mob.shoot.connect(_on_mob_shoot)
	add_child(mob)

func _on_mob_shoot(bullet, direction, location):
	#order matters here
	bullet.set_direction(direction)
	bullet.set_is_enemy_bullet()
	bullet.position = location
	add_child(bullet)
	bullet.play_sound()

func _on_player_bullet_dequeue():
	$HUD.reclaim_bullet()

func _on_player_hit():
	do_damage()

func do_damage():
	$HUD.lose_heart()


func _on_hud_player_die():
	game_over()


func kill_all_active_things():
	get_tree().call_group("enemies", "queue_free")
	get_tree().call_group("bullets", "bullet_die")
	get_tree().call_group("portals", "queue_free")

func _on_hud_level_complete():
	#kill all first before we add another portal
	kill_all_active_things()
	
	# end_level takes care of the portal creation
	$Level.end_level($Player.position)
	
	#TODO: stop current music and play level complete sound?

func _on_player_entered_portal():
	# TODO: on full release, remove this
	if is_demoing:
		var demo_end_screen = preload("res://scenes/demo_end_screen.tscn")
		get_tree().change_scene_to_packed(demo_end_screen)
	else:
		play_next_level()

func _on_pause_menu_return_menu():
	get_tree().paused = false
	var main_menu = preload("res://scenes/main_menu.tscn")
	get_tree().change_scene_to_packed(main_menu)

# just return back to main menu
func _on_hud_quit_game():
	_on_pause_menu_return_menu()
	
func frame_freeze(ts, d):
	Engine.time_scale = ts
	var timer = get_tree().create_timer(d * ts)
	await timer.timeout
	Engine.time_scale = 1.0


func _on_level_1_spawn_portal(portal):
	add_child(portal)

	# connect the portal on screen detection
	portal.entered.connect(_on_portal_entered)
	portal.exited.connect(_on_portal_exited)
	
	# tell the Player about the portal to point to
	$Player.set_portal(portal)
	$Player.display_pointer(true)
	
func _on_portal_entered():
	$Player.portal_on_screen(true)
	
func _on_portal_exited():
	$Player.portal_on_screen(false)

# simply repeat the VHS vinyl sound
func _on_vhs_overlay_finished():
	$VHSOverlay.play()
