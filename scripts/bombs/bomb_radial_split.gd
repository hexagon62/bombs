class_name BombRadialSplit
extends Bomb
## When it explodes, it sends out more bombs radially.


## How many times to instantiate the next scene
@export_range(1, 100, 1, "or_greater") var copies := 2
## How much speed the instances should have.
## Only works if the scene root is a RigidBody2D.
@export_range(0.0, 10000.0, 1.0, "suffix:px/s") var speed := 0.0
## What direction the instances should move in.
## Only works if the next scene is a RigidBody2D.
@export_range(0.0, 360.0, 1.0, "radians_as_degrees", "degrees") var angle := 0.0
## The spread of the movement direction. Will be evenly distributed.
## Only works if the next scene is a RigidBody2D.
@export_range(0.0, 360.0, 1.0, "radians_as_degrees", "degrees") var spread := 0.0


func _explode() -> void:
	_apply_explosion_effects()
	
	for i in copies:
		var instance_angle := lerpf(angle - spread/2.0, angle + spread/2.0, float(i+0.5)/float(copies))
		var next_linear_velocity = Vector2.from_angle(instance_angle)*speed
		spawn_next(next_linear_velocity)
