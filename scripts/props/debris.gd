class_name Debris
extends RigidBody2D
## A rigid body meant to only collide with the world, and has randomized sprites.


@export var textures: Array[Texture2D]

var _ticks_alive := 0
var _fade_tween: Tween
var _prev_pos := Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	if textures.is_empty():
		sprite.texture = null
	else:
		sprite.texture = textures.pick_random()
	
	_fade_tween = get_tree().create_tween()
	_fade_tween.tween_interval(randf_range(8.0, 16.0))
	_fade_tween.tween_property(self, ^"collision_layer", CollisionLayer.NONE, 0.0)
	_fade_tween.tween_property(self, ^"modulate", Color(Color.WHITE, 0.0), 1.0)
	_fade_tween.tween_callback(queue_free)
	
	can_sleep = true
	collision_layer = CollisionLayer.DEBRIS
	collision_mask = CollisionLayer.NONE
	_prev_pos = global_position


func _exit_tree() -> void:
	if _fade_tween:
		_fade_tween.stop()


func _physics_process(_delta: float) -> void:
	_ticks_alive += 1
	
	# Crushed/teleported in weird way
	# I don't have a better fix yet
	if (
		_ticks_alive > 1 and
		(global_position - _prev_pos).length_squared() > linear_velocity.length_squared()
	):
		collision_mask = CollisionLayer.WORLD | CollisionLayer.DEBRIS
		global_position = _prev_pos
		reset_physics_interpolation()
	
	if _ticks_alive == 10:
		collision_mask = CollisionLayer.WORLD | CollisionLayer.PIECE | CollisionLayer.DEBRIS
	
	_prev_pos = global_position
