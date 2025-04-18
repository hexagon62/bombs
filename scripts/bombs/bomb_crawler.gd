class_name BombCrawler
extends Bomb


## Emitted when the object has been in the air for a bit
signal crawl_ended
## Emitted when the object touches a surface and crawls left
signal crawl_left_began
## Emitted when the object touches a surface and crawls right
signal crawl_right_began


## Represents the direction the bomb wants to move in
enum MoveDirection
{
	NONE, LEFT, RIGHT
}


## The speed the bomb should move at along the surface it's touching
@export_range(0.0, 10000.0, 1.0, "suffix:px/s") var speed := 250.0

var direction := MoveDirection.NONE

var _falling_frames := 1
var _visual_angle := 0.0

@onready var gravity: float = \
		ProjectSettings.get_setting("physics/2d/default_gravity", 0.0)
@onready var gravity_vector: Vector2 = Vector2.DOWN
@onready var visuals: Node2D = $Visuals


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if state.get_contact_count() <= 0:
		if _falling_frames == 0:
			linear_velocity *= 0.25
		if _falling_frames >= Engine.physics_ticks_per_second:
			direction = MoveDirection.NONE
			crawl_ended.emit()
		_falling_frames += 1
		linear_velocity += gravity_vector*gravity*gravity_scale*state.step
	else:
		# Find the direction to push the bomb in to keep it on the surface it's on
		gravity_vector = Vector2.ZERO
		for i in state.get_contact_count():
			gravity_vector -= state.get_contact_local_normal(i)
		gravity_vector /= float(state.get_contact_count())
		
		var move_vector := _get_move_vector(state)*speed
		if _falling_frames != 0:
			if direction == MoveDirection.LEFT:
				crawl_left_began.emit()
			elif direction == MoveDirection.RIGHT:
				crawl_right_began.emit()
		_falling_frames = 0
		linear_velocity = linear_velocity.move_toward(move_vector, speed)
		_visual_angle = lerp_angle(_visual_angle, move_vector.angle(), state.step*5.0)
		visuals.rotation = _visual_angle


func _left_move_vector() -> Vector2:
	return Vector2(-gravity_vector.y, gravity_vector.x)


func _right_move_vector() -> Vector2:
	return Vector2(gravity_vector.y, -gravity_vector.x)
	

func _decide_move_direction() -> MoveDirection:
	var left := _left_move_vector().angle_to(linear_velocity)
	var right := _right_move_vector().angle_to(linear_velocity)
	if left < right:
		return MoveDirection.LEFT
	elif right < left:
		return MoveDirection.RIGHT
	return [MoveDirection.LEFT, MoveDirection.RIGHT].pick_random()


func _get_move_vector(state: PhysicsDirectBodyState2D) -> Vector2:
	if state.get_contact_count() <= 0:
		return Vector2.ZERO
	
	if direction == MoveDirection.NONE:
		direction = _decide_move_direction()
	if direction == MoveDirection.LEFT:
		return _left_move_vector()
	elif direction == MoveDirection.RIGHT:
		return _right_move_vector()
	return Vector2.ZERO
