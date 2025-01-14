extends RigidBody2D

var gravity_on = false

func _ready():
	gravity_scale = 0.0

func _process(_delta):
	if gravity_on:
		gravity_scale = 1.0

func flip_gravity_on():
	gravity_on = !gravity_on
	#making the robot fall
	add_constant_force(Vector2(0, 4500))
