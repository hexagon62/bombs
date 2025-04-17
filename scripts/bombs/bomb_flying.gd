class_name BombFlying
extends Bomb


## The speed of the bomb being spawned, which overwrites any speed previously given to it.
@export_range(0.0, 10000.0, 1.0, "suffix:px/s") var speed := 250.0

var _desired_velocity := Vector2.ZERO

@onready var visuals: Node2D = $Visuals


func _physics_process(delta: float) -> void:
	if ticks_alive == 0:
		if linear_velocity.is_zero_approx():
			_desired_velocity = Vector2.from_angle(randf_range(0.0, TAU))*speed
		else:
			_desired_velocity = linear_velocity.normalized()*speed
	visuals.look_at(global_position + linear_velocity)
	super._physics_process(delta)


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if ticks_alive >= 1:
		linear_velocity = _desired_velocity
