class_name Bomb
extends RigidBody2D
## Look out JC, a bomb!


## How many raycasts to do when exploding by default
const EXPLOSION_RAYCAST_COUNT := 400
## How much of the impulse to apply to debris
const DEBRIS_IMPULSE_FACTOR := 0.25

## Emitted when the bomb explodes
signal exploded

## How far the explosion reaches
@export_range(0.0, 3000.0, 1.0, "or_greater", "suffix:px")
var explosion_radius := 256.0
## The total impulse of the explosion, evenly split among all rays cast outward
@export_range(0.0, 1000000.0, 1.0, "or_less", "or_greater", "suffix:J")
var explosion_impulse := 500.0
## The damage of the explosion
@export_range(0.0, 100.0, 1.0, "or_greater", "suffix:HP")
var explosion_damage := 100.0
## Whether or not the bomb can penetrate buildings
@export var penetrates := true
## Ratio of damage dealt to the building needed to light it on fire
@export_range(0.0, 1.0, 0.001)
var ignite_damage_ratio := 0.8
## What scene to spawn for the explosion
@export var explosion_scene: PackedScene
## What scenes to spawn in next (meant to be changeable by player)
@export var next_steps: Array[BombStep]


var ticks_alive := 0
var time_alive := 0.0
var fuse_time := INF
var raycaster: RayCast2D


func _ready() -> void:
	fuse_time *= randf_range(0.95, 1.0/0.95)
	raycaster = RayCast2D.new()
	raycaster.collision_mask = CollisionLayer.EXPLOSION_RAYCAST
	raycaster.top_level = true
	raycaster.enabled = false
	add_child(raycaster)


func _physics_process(delta: float) -> void:
	ticks_alive += 1
	time_alive += delta
	
	if time_alive >= fuse_time:
		explode()


## A function that is meant to be overridden to define the detonation behavior.
## Gets called by [method explode].
func _explode() -> void:
	_apply_explosion_effects()
	spawn_next()


# Does an explosion with parameters set in the inspector.
func _apply_explosion_effects() -> void:
	_create_explosion(explosion_radius, explosion_impulse, explosion_damage, EXPLOSION_RAYCAST_COUNT)


# Applies effects of an explosion, pushing physics bodies and damaging pieces.
func _create_explosion(radius: float, impulse: float, damage: float, raycast_count := EXPLOSION_RAYCAST_COUNT) -> void:
	var space_rid := PhysicsServer2D.body_get_space(get_rid())
	var direct_state := PhysicsServer2D.space_get_direct_state(space_rid)
	
	#var visualizer := get_tree().get_first_node_in_group(&"debug_bomb_raycast_visualizer") as DebugBombRaycastVisualizer
	#if visualizer:
		#if not visualizer.visible:
			#visualizer = null
		#else:
			#visualizer.clear()
		
	# Get all pieces in range and check if they're in line of sight
	var explosion_query := PhysicsShapeQueryParameters2D.new()
	var damaged_pieces: Dictionary[Piece, float] = {}
	var hits := 0
	explosion_query.transform = global_transform
	explosion_query.shape = CircleShape2D.new()
	explosion_query.shape.radius = radius
	explosion_query.collision_mask = CollisionLayer.PIECE
	raycaster.global_position = global_position
	var explosion_intersections := direct_state.intersect_shape(explosion_query, 512)
	for intersection in explosion_intersections:
		var piece := intersection.collider as Piece
		if piece:
			var damage_factor := 1.0
			raycaster.target_position = piece.global_position - global_position
			raycaster.force_raycast_update()
			#visualizer.raycasts.push_back({
				#"from": global_position,
				#"to": piece.global_position,
				#"color": Color.WHITE,
				#"hit": false
			#})
			var collider := raycaster.get_collider()
			if collider:
				#visualizer.raycasts[visualizer.raycasts.size()-1].to = raycaster.get_collision_point()
				#visualizer.raycasts[visualizer.raycasts.size()-1].hit = true
				if collider == piece:
					pass
				elif collider is Piece:
					#visualizer.raycasts[visualizer.raycasts.size()-1].color = Color.YELLOW
					damage_factor = 0.5
				else:
					#visualizer.raycasts[visualizer.raycasts.size()-1].color = Color.RED
					damage_factor = 0.0
			if piece not in damaged_pieces:
				damaged_pieces[piece] = 0.0
			var dealt_damage := damage_factor*damage
			if dealt_damage > damaged_pieces[piece]:
				damaged_pieces[piece] = dealt_damage
			var impulse_vector := impulse*raycaster.target_position.normalized()*damage_factor
			piece.debris_impulse = impulse_vector
			piece.apply_central_impulse(impulse_vector)
	
	#visualizer.queue_redraw()
	
	# Apply the damage
	for piece in damaged_pieces:
		var damage_ratio := damaged_pieces[piece]/piece.health
		if damage_ratio >= ignite_damage_ratio:
			piece.ignited = true
		piece.health -= damaged_pieces[piece]
	
	# Push debris & bombs
	var push_query := PhysicsShapeQueryParameters2D.new()
	push_query.transform = global_transform
	push_query.shape = CircleShape2D.new()
	push_query.shape.radius = radius
	push_query.collision_mask = CollisionLayer.DEBRIS | CollisionLayer.BOMB
	
	var other_pushables := direct_state.intersect_shape(push_query, 512)
	for intersection in other_pushables:
		var body := intersection.collider as RigidBody2D
		if body:
			var dir := (body.global_position - global_position).normalized()
			body.apply_central_impulse(dir*impulse*DEBRIS_IMPULSE_FACTOR)


## Spawns an instance of the next bomb.
## [param next_linear_velocity] will be the next bomb's linear velocity.
## [param next_angular_velocity] will be the next bomb's angular velocity.
## If [param add] is [code]true[/code], these are added with this bomb's velocities.
func spawn_next(next_linear_velocity := Vector2.ZERO, next_angular_velocity := 0.0, add := true) -> void:
	if next_steps.is_empty():
		return
	
	# Instantiate the scene
	if not next_steps[0].scene:
		return
	var instance := next_steps[0].scene.instantiate()
	if not instance:
		return
	
	get_tree().get_first_node_in_group(&"level").add_child.call_deferred(instance)
	
	if instance is Node2D:
		instance.transform = global_transform
		instance.reset_physics_interpolation()
	
	if instance is RigidBody2D:
		var total_linear := next_linear_velocity
		var total_angular := next_angular_velocity
		if add:
			total_linear += linear_velocity
			total_angular += angular_velocity
		instance.set_linear_velocity.call_deferred(total_linear)
		instance.set_angular_velocity.call_deferred(total_angular)
	
	if instance is Bomb:
		instance.next_steps = next_steps.slice(1)
		instance.fuse_time = next_steps[0].fuse_time


## Makes the bomb detonate. Calls [method _explode].
func explode() -> void:
	_explode()
	
	if explosion_scene:
		var instance := explosion_scene.instantiate()
		get_tree().get_first_node_in_group(&"level").add_child(instance)
		if instance is Node2D:
			instance.global_position = global_position
			instance.reset_physics_interpolation()
	
	exploded.emit()
	queue_free()
