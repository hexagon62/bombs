class_name Spawner
extends Node2D
## Instantiates scenes in the current level


## The scene to instantiate
@export var scene: PackedScene
## How many times to instantiate it
@export_range(1, 100, 1, "or_greater") var copies := 1
@export_group("Physics")
## The physics body that acts as a reference frame.
## If not supplied, any velocity settings will be absolute,
## so there will be no consideration of preserving momentum.
@export var reference: RigidBody2D
## How much speed the instances should have.
## Only works if the scene root is a RigidBody2D.
@export_range(0.0, 10000.0, 1.0, "suffix:px/s") var speed := 0.0
## What direction the instances should move in.
## Only works if the scene root is a RigidBody2D.
@export_range(0.0, 360.0, 1.0, "radians_as_degrees", "degrees") var angle := 0.0
## The spread of the movement direction. Will be evenly distributed.
## Only works if the scene root is a RigidBody2D.
@export_range(0.0, 360.0, 1.0, "radians_as_degrees", "degrees") var spread := 0.0


func spawn() -> void:
	if scene:
		for i in copies:
			var instance := scene.instantiate()
			
			var level := get_tree().get_first_node_in_group(&"level")
			if level:
				level.add_child(instance)
			else:
				add_child(instance)
				
			if instance is Node2D:
				instance.global_transform = global_transform
				instance.reset_physics_interpolation()
			
			if instance is RigidBody2D:
				var instance_angle := lerpf(angle - spread/2.0, angle + spread/2.0, (i+0.5)/float(copies))
				instance.linear_velocity = Vector2.from_angle(instance_angle)*speed
				if reference:
					instance.linear_velocity += reference.linear_velocity
					instance.angular_velocity += reference.angular_velocity
