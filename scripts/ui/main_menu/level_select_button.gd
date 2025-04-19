class_name LevelSelectButton
extends Button


@export var level: PackedScene


func _ready() -> void:
	var level_wrapper := get_tree().get_first_node_in_group(&"level_wrapper") as LevelWrapper
	if level_wrapper:
		pressed.connect(level_wrapper.load_level.bind(level))
