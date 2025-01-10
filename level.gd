extends Node2D
@export var enemies_on = true

signal spawn_mob(m: Resource)
signal spawn_portal(m: Resource)

@export var mob_spawn_scene: PackedScene
@export var mob_scene: PackedScene
@export var portal_scene: PackedScene

var valid_mob_spawn_locations = []

var current_level: int = 1

# TODO: use the time from the HUD as a ratio between "beginning" and "end"
# each of these are the chances out of 101% what mob it might be
const level_chances = {
	"1beginning": {
		"bug" = 0,
		"soldier" = 100,
		"spider" = 0,
	},
	"1end": {
		"bug" = 0,
		"soldier" = 70,
		"spider" = 30,
	},
	"2beginning": {
		"bug" = 0,
		"soldier" = 20,
		"spider" = 80,
	},
	"2end": {
		"bug" = 0,
		"soldier" = 70,
		"spider" = 30,
	},
	"3beginning": {
		"bug" = 0,
		"soldier" = 20,
		"spider" = 80,
	},
	"3end": {
		"bug" = 0,
		"soldier" = 70,
		"spider" = 30,
	},
}

# Called when the node enters the scene tree for the first time.
func _ready():
	create_spawn_locations()
	
func start_spawning():
	$MobTimer.start()
	
func stop_spawning():
	$MobTimer.stop()
	
func end_level(player_location: Vector2):
	stop_spawning()
	var all_portal_locations = [
		{
			"distance": 0,
			"location": $PortalSpawnLocation,
		},
		{
			"distance": 0,
			"location": $PortalSpawnLocation2,
		},
		{
			"distance": 0,
			"location": $PortalSpawnLocation3,
		},
		{
			"distance": 0,
			"location": $PortalSpawnLocation4,
		},
	]

	#find all distances
	for i in range(len(all_portal_locations)):
		var v = all_portal_locations[i].location.position - player_location
		var d = sqrt((v.x**2) + (v.y**2))
		all_portal_locations[i].distance = d

	# find the second least distance
	all_portal_locations.sort_custom(sort_by_distance)
	
	var portal = portal_scene.instantiate()
	#set to the second closest as we don't want to accidentally bump into it on creation
	portal.position = all_portal_locations[1].location.position
	spawn_portal.emit(portal)
	
func sort_by_distance(a, b):
	if a.distance < b.distance:
		return true
	return false

func create_spawn_locations():
	var start = $MobSpawnLocation.position
	var end = $MobSpawnLocation2.position
	var step = 128
	var current = start
	while current.x <= end.x:
		while current.y <= end.y:
			# here create a spawn location and at it to the list
			var location: Node2D = mob_spawn_scene.instantiate()
			location.position = current
			location.exited.connect(location_exited)
			location.entered.connect(location_entered)
			add_child(location)
			valid_mob_spawn_locations.append(location)
			current.y += step
		current.x += step
		current.y = start.y
		
# both of these seem to get called on creation so we dont have to remove them from the valid list by hand
func location_exited(n: Node2D):
	valid_mob_spawn_locations.append(n)
func location_entered(n: Node2D):
	valid_mob_spawn_locations.erase(n)
	
func set_level(l: int):
	current_level = l
	var layer_string: String = $Background.all_layers[l]
	if !$Background.set_layer(layer_string):
		print("setting layer failed")

func _on_mob_timer_timeout():
	if enemies_on:
		# Create a new instance of the Mob scene.
		var mob: Node = mob_scene.instantiate()
		# select a random spawn location from the valid list
		var n: Node2D = valid_mob_spawn_locations[randi_range(0, len(valid_mob_spawn_locations)  - 1)]
		mob.position = n.position

		var type: String = get_mob_type_from_level()
		mob.set_type(type)

		spawn_mob.emit(mob)

func get_mob_type_from_level() -> String:
	var chances = level_chances[String.num_int64(current_level)+"beginning"]
	var type_i: int = randi_range(0, 100)
	var type: String = ""
	var total: int = 0 # strange way to allow the total to be different from beginning to end of the level
	for key in chances:
		if type_i <= chances[key] + total:
			type = key
			break
		else:
			total += chances[key]
	if type == "": # default ***THIS SHOULD NEVER BE HIT*** But we are leaving it here anyway
		type = "spider"
	return type
