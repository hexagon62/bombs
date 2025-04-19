class_name LevelWrapper
extends Node


## Emitted when a level is loaded
signal loaded
## Emitted when a level is reloaded
signal reloaded


## The currently loaded level
var level: Level
## Whether or not the player specifically paused the game
var player_pause := false
## Whether or not the game is paused by the UI
var ui_pause := false

# The scene of the current level loaded
var _current_scene: PackedScene

@onready var destruction_label: Label = $DestructionLabel
@onready var bomb_builder: BombBuilder = $BombBuilder


func _input(event: InputEvent) -> void:
	if not ui_pause:
		if event.is_action_pressed(&"pause"):
			player_pause = not player_pause
		if event.is_action_pressed(&"reload"):
			reload_level()


func _physics_process(_delta: float) -> void:
	if level:
		destruction_label.text = "Destruction: %.0f%%" % (level.get_destruction_ratio()*100.0)
	else:
		destruction_label.text = ""
	ui_pause = bomb_builder.visible
	get_tree().paused = player_pause or ui_pause


## Unloads the current level and loads another one
## If [param scene] is [code]null[/code], the current level is just unloaded.
## Returns true if a level was successfully loaded.
func load_level(scene: PackedScene) -> bool:
	if level:
		level.free()
		level = null
	if not scene:
		return false
	var instance := scene.instantiate() as Level
	if instance:
		add_child(instance)
		level = instance
		_current_scene = scene
		bomb_builder.set_palette(level.bombs_available)
		bomb_builder.visible = true
		ui_pause = true
		loaded.emit()
		return true
	return false


## Reloads the current level
func reload_level() -> bool:
	if load_level(_current_scene):
		reloaded.emit()
		return true
	return false


## Spawns the player's bomb
func spawn_bomb() -> void:
	if not level:
		return
	for node in get_tree().get_nodes_in_group(&"bomb_spawn"):
		var node2d := node as Node2D
		if node2d:
			var point := node2d.global_position
			var bomb := bomb_builder.instantiate_bomb()
			if bomb:
				bomb.global_position = point
				level.add_child(bomb)


func _on_player_ready() -> void:
	spawn_bomb()
	bomb_builder.visible = false
	player_pause = false
