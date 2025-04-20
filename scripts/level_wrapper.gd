class_name LevelWrapper
extends Node


## Emitted when a level is loaded
signal loaded
## Emitted when a level is reloaded
signal reloaded
## Emitted the loaded level is cleared
signal unloaded
## Emitted when the level is won
signal level_won
## Emitted when the level is lost
signal level_lost


## The currently loaded level
var level: Level
## Whether or not the player specifically paused the game
var player_pause := false:
	get: return player_pause
	set(value):
		player_pause = value
		pause_button.paused = player_pause
## Whether or not the game is paused by the UI
var ui_pause := false

# The scene of the current level loaded
var _current_scene: PackedScene
# The completion state of each level
var _level_completion_states: Dictionary[StringName, CompletionState]
# If the level was just finished
var _just_finished := false

@onready var show_when_unpaused: Control = $ShowWhenUnpaused
@onready var destruction_progress_bar: ProgressBarWithThreshold = %DestructionProgressBar
@onready var bomb_builder: BombBuilder = $BombBuilder
@onready var pause_button: PauseButton = %PauseButton
@onready var victory_label: Label = %VictoryLabel
@onready var loss_label: Label = %LossLabel
@onready var game_end_animation: AnimationPlayer = %GameEndAnimation


func _ready() -> void:
	load_progression()


func _input(event: InputEvent) -> void:
	if event.is_action_released(&"back"):
		if bomb_builder.visible:
			unload_level() # back to main menu
		else:
			reload_level() # back to bomb builder
	if not ui_pause:
		if event.is_action_pressed(&"pause"):
			player_pause = not player_pause
		if event.is_action_pressed(&"reload"):
			reload_level()


func _physics_process(_delta: float) -> void:
	if level:
		var ratio := level.get_destruction_ratio()
		show_when_unpaused.visible = not ui_pause
		destruction_progress_bar.progress_ratio = ratio
		destruction_progress_bar.threshold_ratio = level.win_ratio
		if _just_finished:
			pass
		elif ratio >= level.win_ratio:
			_just_finished = true
			game_end_animation.play(&"victory_animation")
			_update_completion_state()
			level_won.emit()
		elif level.done():
			game_end_animation.play(&"loss_animation")
			_just_finished = true
			level_lost.emit()
	else:
		show_when_unpaused.visible = false
	ui_pause = bomb_builder.visible
	get_tree().paused = player_pause or ui_pause



## Returns the completion state of a level
## If it doesn't exist, [code]null[/code] is returned.
func get_level_completion_state(level_name: StringName) -> CompletionState:
	if level_name not in _level_completion_states:
		return null
	return _level_completion_states[level_name]
	


## Returns the completion state of the current level
## If it doesn't exist, [code]null[/code] is returned.
func get_current_level_completion_state() -> CompletionState:
	if not level:
		return null
	return get_level_completion_state(level.level_name)


## Unloads the current level and loads another one
## If [param scene] is [code]null[/code], the current level is just unloaded.
## If [param keep_bombs] is [code]true[/code], the previously built bomb is kept.
## Returns true if a level was successfully loaded.
func load_level(scene: PackedScene, keep_bombs := false) -> bool:
	_just_finished = false
	game_end_animation.play(&"RESET")
	bomb_builder.visible = false
	if not keep_bombs:
		bomb_builder.clear()
	if level:
		level.free()
		level = null
	if not scene:
		unloaded.emit()
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
	if load_level(_current_scene, true):
		reloaded.emit()
		return true
	return false


## Unloads the level. Same as [code]load_level(null)[/code].
func unload_level(keep_bombs := false) -> bool:
	return load_level(null, keep_bombs)


## Spawns the player's bomb
func spawn_bomb() -> void:
	if not level:
		return
	var bomb := bomb_builder.instantiate_bomb()
	if bomb:
		level.spawn_bomb(bomb_builder)


## Save the player's progression
func save_progression() -> void:
	var dict: Dictionary
	
	for k in _level_completion_states:
		dict[k] = {
			"completed": _level_completion_states[k].completed,
			"best_bomb_count": _level_completion_states[k].best_bomb_count,
		}
	
	var save_file := FileAccess.open("user://savegame.save", FileAccess.WRITE)
	save_file.store_line(JSON.stringify(dict))


## Clear the player's progression
func clear_progression() -> void:
	_level_completion_states.clear()
	save_progression()


## Load the player's progression, if it exists
func load_progression() -> void:
	var save_file := FileAccess.open("user://savegame.save", FileAccess.READ)
	var potential_corruption := false
	if save_file:
		var raw := save_file.get_as_text()
		var json_result: Variant = JSON.parse_string(raw)
		print(json_result)
		if typeof(json_result) == TYPE_DICTIONARY:
			for k in json_result:
				var key := StringName(k)
				var val: Variant = json_result[k]
				if typeof(val) == TYPE_DICTIONARY:
					if "completed" not in val or typeof(val["completed"]) != TYPE_BOOL:
						potential_corruption = true
						continue
					if "best_bomb_count" not in val or typeof(val["best_bomb_count"]) != TYPE_FLOAT:
						potential_corruption = true
						continue
					_level_completion_states[key] = CompletionState.new(
								val["completed"], floori(val["best_bomb_count"])
							)
				else:
					potential_corruption = true
		else:
			potential_corruption = true
	if potential_corruption:
		print("Save is potentially corrupted! Clearing progression!")
		clear_progression()



func _on_player_ready() -> void:
	spawn_bomb()
	bomb_builder.visible = false
	player_pause = false


func _update_completion_state() -> void:
	if level.level_name not in _level_completion_states:
		_level_completion_states[level.level_name] = CompletionState.new()
	_level_completion_states[level.level_name].completed = true
	_level_completion_states[level.level_name].best_bomb_count = bomb_builder.get_bombs_spawned()
	save_progression()


func _on_quit_button_pressed() -> void:
	unload_level()


func _on_reset_button_pressed() -> void:
	reload_level()


func _on_pause_button_pressed() -> void:
	player_pause = not player_pause


class CompletionState:
	var completed: bool
	var best_bomb_count: int
	
	func _init(c := false, b := -1) -> void:
		self.completed = c
		self.best_bomb_count = b
