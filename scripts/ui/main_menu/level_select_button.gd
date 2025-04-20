class_name LevelSelectButton
extends Button


## The level
@export var level: PackedScene
## The name of the level
@export var level_name: String
## The internal name of the level, for showing stars
## hacky; should be synced with actual level, but isn't for now, too bad!
@export var internal_level_name: StringName
## A preview of the level associated with the button
@export var preview: Texture2D


func _ready() -> void:
	var level_wrapper := get_tree().get_first_node_in_group(&"level_wrapper") as LevelWrapper
	if level_wrapper:
		pressed.connect(level_wrapper.load_level.bind(level))


func _get_best() -> int:
	var level_wrapper := get_tree().get_first_node_in_group(&"level_wrapper") as LevelWrapper
	if level_wrapper:
		var completion_info := level_wrapper.get_level_completion_state(internal_level_name)
		if completion_info:
			return completion_info.best_bomb_count
	return -1


func _on_mouse_entered() -> void:
	var level_info_panel := get_tree().get_first_node_in_group(&"level_info_panel") as LevelInfoPanel
	if level_info_panel:
		var best := _get_best()
		level_info_panel.contents_visible = true
		level_info_panel.level_name = level_name
		level_info_panel.preview_texture = preview
		level_info_panel.best = best
		level_info_panel.star = best >= 0


func _on_mouse_exited() -> void:
	var level_info_panel := get_tree().get_first_node_in_group(&"level_info_panel") as LevelInfoPanel
	if level_info_panel:
		level_info_panel.contents_visible = false
