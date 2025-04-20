@tool
class_name Piece
extends RigidBody2D


## The health the object will spawn with
@export_range(1.0, 10000.0, 1.0, "or_greater", "suffix:HP")
var max_health := 100.0
## The texture to display when the object is undisturbed
@export var undisturbed_texture: Texture2D:
	get: return undisturbed_texture
	set(value):
		undisturbed_texture = value
		_update_appearance()
## The texture to display when the object is healthy
@export var healthy_texture: Texture2D:
	get: return healthy_texture
	set(value):
		healthy_texture = value
		_update_appearance()
## The texture to display when the object is damaged
@export var damaged_texture: Texture2D:
	get: return damaged_texture
	set(value):
		damaged_texture = value
		_update_appearance()
## The debris scene
@export var debris_scene: PackedScene
## How brittle the object is. Changes how much damage is taken from impacts.
@export_range(0.0, 1.0, 0.001)
var brittleness := 0.0

## The health the object has
var health := 0.001:
	get: return health
	set(value):
		health = value
		_update_appearance()
## Whether or not the object has been pushed or damaged
var undisturbed := true:
	get: return undisturbed
	set(value):
		undisturbed = value
		_update_appearance()
# If the object has been ignited
var ignited := false:
	get: return ignited
	set(value):
		ignited = value
		_update_appearance()

# The initial position of the object
var _initial_position := Vector2.ZERO
# The initial rotation of the object
var _initial_rotation := 0.0
# The amount of time the piece has been in contact with an ingited object
var _ignited_contact := 0.0
# This impulse will be applied to the debris when spawned
var debris_impulse := Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite
@onready var fire_particles: GPUParticles2D = $FireParticles


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	contact_monitor = true
	max_contacts_reported = 256
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	health = max_health
	_initial_position = global_position
	can_sleep = true
	modulate = Color(
			randf_range(0.85, 1.0),
			randf_range(0.85, 1.0),
			randf_range(0.85, 1.0))


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	# Get impact damage and track ticks touching an ignited piece
	var damages: Dictionary[Object, float]
	var touching_ignited := false
	for i in state.get_contact_count():
		var collider := state.get_contact_collider_object(i)
		if collider is Debris:
			continue
		if collider is Piece and collider.ignited:
			touching_ignited = true
		var impulse := sqrt(state.get_contact_impulse(i).length())
		var threshold := 20.0
		if impulse >= threshold:
			var damage := (impulse - threshold)*4.0*brittleness/mass
			if collider not in damages or damage > damages[collider]:
				damages[collider] = damage
	
	var max_damage := 0.0
	for damage in damages.values():
		if damage > max_damage:
			max_damage = damage
	health -= max_damage
	
	if (
		health < max_health or
		_initial_position.distance_squared_to(global_position) > 144.0 or
		absf(rotation - _initial_rotation) > TAU/32.0
	):
		undisturbed = false
	
	if not ignited:
		if touching_ignited:
			_ignited_contact += state.step
		else:
			_ignited_contact = 0.0
		if _ignited_contact > 1.0:
			ignited = true


func _physics_process(delta: float) -> void:
	if health <= 0.0:
		die()
	if ignited:
		health -= 10.0*delta
	debris_impulse = Vector2.ZERO


func _update_appearance() -> void:
	if not sprite:
		return
	if health <= max_health*0.75:
		if damaged_texture:
			sprite.texture = damaged_texture
		elif healthy_texture:
			sprite.texture = healthy_texture
		elif undisturbed_texture:
			sprite.texture = undisturbed_texture
	elif undisturbed:
		if undisturbed_texture:
			sprite.texture = undisturbed_texture
		elif healthy_texture:
			sprite.texture = healthy_texture
		elif damaged_texture:
			sprite.texture = damaged_texture
	else:
		if healthy_texture:
			sprite.texture = healthy_texture
		elif undisturbed_texture:
			sprite.texture = undisturbed_texture
		elif damaged_texture:
			sprite.texture = damaged_texture
	
	fire_particles.emitting = ignited
	if ignited:
		fire_particles.amount_ratio = remap(health, 0.0, max_health, 1.0, 0.0)


func fully_heal() -> void:
	health = min(max_health, health)
	ignited = false


func die() -> void:
	if not Engine.is_editor_hint():
		for i in randi_range(4, 8):
			spawn_debris()
		queue_free()


## Spawns the debris for this breakable
func spawn_debris() -> void:
	if not debris_scene:
		return
	
	var instance := debris_scene.instantiate()
	if not instance:
		return
	
	get_tree().get_first_node_in_group(&"level").add_child(instance)
	
	if instance is Node2D:
		instance.global_position = global_position
		instance.reset_physics_interpolation()
		instance.modulate = modulate
	
	if instance is RigidBody2D:
		var randomize_linear := Vector2.from_angle(randf_range(0.0, TAU))*64.0
		var randomize_angular := randf_range(-PI, PI)
		instance.set_linear_velocity(linear_velocity + randomize_linear)
		instance.set_angular_velocity(randomize_angular)
	
	if instance is Debris:
		instance.apply_central_impulse(debris_impulse)
