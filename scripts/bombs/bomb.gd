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
var explosion_radius := 192.0
## The total impulse of the explosion, evenly split among all rays cast outward
@export_range(0.0, 1000000000.0, 1.0, "or_less", "or_greater", "suffix:J")
var explosion_impulse := 10000.0
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
static var spawn_count := 0


func _ready() -> void:
	spawn_count += 1
	fuse_time *= randf_range(0.95, 1.0/0.95)
	#print(spawn_count)


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
	# Set up the physics query
	var space_rid := PhysicsServer2D.body_get_space(get_rid())
	var direct_state := PhysicsServer2D.space_get_direct_state(space_rid)
	var ray_query_parameters := PhysicsRayQueryParameters2D.new()
	ray_query_parameters.collision_mask = CollisionLayer.ALL_INFLUENCED_BY_EXPLOSIONS
	#ray_query_parameters.hit_from_inside = true
	
	var visualizer := get_tree().get_first_node_in_group(&"debug_bomb_raycast_visualizer") as DebugBombRaycastVisualizer
	if visualizer:
		if not visualizer.visible:
			visualizer = null
		else:
			visualizer.clear()
	
	# Project the ray in various directions, calculate damage to pieces
	var damaged_pieces: Dictionary[Piece, float] = {}
	for i in raycast_count:
		var angle := float(i+0.5)*TAU/float(raycast_count)
		var dir := Vector2.from_angle(angle)
		var exclude: Array[RID] = [self.get_rid()]
		ray_query_parameters.from = global_position
		ray_query_parameters.to = global_position + dir*radius
		
		var damage_remaining := damage
		var count := 0
		while true:
			ray_query_parameters.exclude = exclude
			var intersection := direct_state.intersect_ray(ray_query_parameters)
			if intersection.is_empty():
				break
			
			var point := intersection.position as Vector2
			
			# Push rigid bodies
			var body := intersection.collider as RigidBody2D
			if not body:
				break
			var diff := body.global_position - point
			body.apply_impulse(dir*impulse/raycast_count, diff)
			
			if visualizer:
				visualizer.raycasts.append({
					"from": ray_query_parameters.from, 
					"to": point,
					"color": Color.WHITE,
					"hit": true
				})
				visualizer.hits[body.get_instance_id()] = body.global_position
			
			# Use the highest damage value for each piece
			# We might've damaged it by penetrating another piece,
			# but more direct damage should take priority
			var piece := intersection.collider as Piece
			if not piece:
				break
			piece.debris_impulse = dir*impulse*DEBRIS_IMPULSE_FACTOR
			if piece not in damaged_pieces:
				damaged_pieces[piece] = 0.0
			var damage_dealt := minf(damage_remaining, piece.health)
			if damage_dealt > damaged_pieces[piece]:
				damaged_pieces[piece] = damage_dealt
			if visualizer:
				if damage_remaining > 0.0:
					visualizer.raycasts[visualizer.raycasts.size()-1].color = Color.RED
				else:
					visualizer.raycasts[visualizer.raycasts.size()-1].color = Color.YELLOW
			damage_remaining -= damage_dealt
			
			# Do not run further iterations if the bomb doesn't penetrate
			if not penetrates:
				break
			
			# Prepare next raycast
			exclude.append(intersection.rid)
			ray_query_parameters.from = point
			
			count += 1
			if count >= 512:
				print("SHOULD NOT HAPPEN")
				break
	
	if visualizer:
		visualizer.queue_redraw()
		visualizer.visible = true
		get_tree().get_first_node_in_group(&"level_wrapper").player_pause = true
		get_tree().paused = true
	
	# Apply the damage
	for piece in damaged_pieces:
		var damage_ratio := damaged_pieces[piece]/piece.health
		if damage_ratio >= ignite_damage_ratio:
			piece.ignited = true
		piece.health -= damaged_pieces[piece]
	
	# Push debris
	var shape_parameters := PhysicsShapeQueryParameters2D.new()
	shape_parameters.transform = global_transform
	shape_parameters.shape = CircleShape2D.new()
	shape_parameters.shape.radius = radius
	shape_parameters.collision_mask = CollisionLayer.DEBRIS
	
	var found_debris := direct_state.intersect_shape(shape_parameters, 512)
	for intersection in found_debris:
		var debris := intersection.collider as Debris
		if debris:
			var dir := (debris.global_position - global_position).normalized()
			debris.apply_central_impulse(dir*impulse*DEBRIS_IMPULSE_FACTOR)


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
