class_name Level
extends Node2D


## The bombs available for this level
@export var bombs_available: Array[BombInfo]
## The ratio of destruction needed to win the level
@export_range(0.0, 1.0, 0.001) var win_ratio := 0.8
## The internal name of the level
@export var level_name: StringName

# Total health of pieces in the level
var _total_piece_health := 0.0
# If the level is started
var _started := false
# How many ticks have been without bombs
var _bombless_ticks := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	var pieces := get_tree().get_nodes_in_group(&"piece")
	for node in pieces:
		var piece := node as Piece
		if piece:
			_total_piece_health += piece.max_health


func _physics_process(_delta: float) -> void:
	if get_tree().get_first_node_in_group(&"bomb"):
		_bombless_ticks = 0
	else:
		_bombless_ticks += 1


## How much of the level is destroyed,
## i.e. how much damage the pieces have taken out of their total max HP
func get_destruction_ratio() -> float:
	if not is_node_ready():
		return 0.0
	if _total_piece_health <= 0.0:
		return 1.0
	var pieces := get_tree().get_nodes_in_group(&"piece")
	var remaining_health := 0.0
	for node in pieces:
		var piece := node as Piece
		if piece and not piece.ignited:
			remaining_health += piece.max_health
	return 1.0 - remaining_health/_total_piece_health


## Whether or not the level is over (not if the player won/lost).
## This means no bombs, no ignited pieces, no moving pieces
func done() -> bool:
	if not is_node_ready():
		return false
	
	if not _started:
		return false
	
	if _bombless_ticks < Engine.physics_ticks_per_second:
		return false
	
	var pieces := get_tree().get_nodes_in_group(&"piece")
	for node in pieces:
		var piece := node as Piece
		if piece and (piece.ignited or piece.linear_velocity.length_squared() > 256.0):
			return false
	
	return true


## Spawns the bombs, starting the level
func spawn_bomb(bomb_builder: BombBuilder) -> void:
	if not bomb_builder:
		return
	for node in get_tree().get_nodes_in_group(&"bomb_spawn"):
		var node2d := node as Node2D
		if node2d:
			var bomb := bomb_builder.instantiate_bomb()
			if bomb:
				var point := node2d.global_position
				bomb.global_position = point
				add_child(bomb)
	_started = true
