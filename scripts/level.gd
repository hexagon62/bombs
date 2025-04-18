class_name Level
extends Node2D


## The bombs available for this level
@export var bombs_available: Array[BombInfo]

# Total health of pieces in the level
var _total_piece_health := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	var pieces := get_tree().get_nodes_in_group(&"piece")
	for node in pieces:
		var piece := node as Piece
		if piece:
			_total_piece_health += piece.max_health


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
	
	if get_tree().get_first_node_in_group(&"bomb"):
		return false
	
	var pieces := get_tree().get_nodes_in_group(&"piece")
	for node in pieces:
		var piece := node as Piece
		if piece and (piece.ignited or piece.linear_velocity.length_squared() > 256.0):
			return false
	
	return true
