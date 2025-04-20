class_name ResetProgressButton
extends Button


func _ready() -> void:
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	var level_wrapper := get_tree().get_first_node_in_group(&"level_wrapper") as LevelWrapper
	if level_wrapper:
		level_wrapper.clear_progression()
