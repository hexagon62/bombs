extends Node


@export var load_level: PackedScene

@onready var level_wrapper: LevelWrapper = $LevelWrapper


func _ready() -> void:
	level_wrapper.load_level.call_deferred(load_level)
