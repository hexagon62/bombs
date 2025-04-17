class_name BombSuck
extends Bomb
## A bomb that sucks objects into it


## The amount of sucking force to apply while the bomb is alive
@export_range(0.0, 10000000.0, 1.0, "or_less", "or_greater", "suffix:N")
var suck_force := 2000.0
## How far the sucking reaches
@export_range(0.0, 3000.0, 1.0, "or_greater", "suffix:px")
var suck_radius := 384.0


func _physics_process(delta: float) -> void:
	_suck()
	super._physics_process(delta)


func _suck() -> void:
	# Set up the physics query
	var space_rid := PhysicsServer2D.body_get_space(get_rid())
	var direct_state := PhysicsServer2D.space_get_direct_state(space_rid)
	var shape_parameters := PhysicsShapeQueryParameters2D.new()
	shape_parameters.transform = global_transform
	shape_parameters.shape = CircleShape2D.new()
	shape_parameters.shape.radius = suck_radius
	shape_parameters.collision_mask = CollisionLayer.ALL_INFLUENCED_BY_EXPLOSIONS
	
	var intersections := direct_state.intersect_shape(shape_parameters, 512)
	for intersection in intersections:
		var body := intersection.collider as RigidBody2D
		if body:
			var dir := (body.global_position - global_position).normalized()
			body.apply_central_force(-dir*suck_force)
