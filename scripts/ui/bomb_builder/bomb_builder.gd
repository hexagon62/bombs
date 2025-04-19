class_name BombBuilder
extends Control


const PALETTE_LENGTH_GRANULE := 18
const SAFE_BOMB_LIMIT := 512

## Player is ready
signal player_ready
## Player is quitting
signal player_quit

var bomb_palette_panel_scene := preload("res://scenes/ui/bomb_builder/ui_bomb_palette_panel.tscn")
var bomb_step_panel_scene := preload("res://scenes/ui/bomb_builder/ui_bomb_step_panel.tscn")

var _bomb_warning := false

@onready var bomb_palette: Control = %BombPalette
@onready var bomb_steps: VBoxContainer = %BombStepsContainer
@onready var bomb_steps_scroller: ScrollContainer = %BombStepsScroller
@onready var flavor_name_label: Label = %FlavorNameLabel
@onready var name_label: Label = %NameLabel
@onready var description_label: Label = %DescriptionLabel
@onready var flavor_description_label: Label = %FlavorDescriptionLabel
@onready var bomb_count_label: Label = %BombCountLabel
@onready var doctor_sprite: CharacterSprite = %DoctorSprite
@onready var go_button: Button = %GoButton
@onready var too_many_bombs_popup: ColorRect = %TooManyBombsPopup


func _ready() -> void:
	_update_step_numbers()


func set_palette(bomb_info_arr: Array[BombInfo]) -> void:
	for child in bomb_palette.get_children():
		child.queue_free()
	
	var idx := 0
	while idx < bomb_info_arr.size():
		for i in PALETTE_LENGTH_GRANULE:
			var panel := bomb_palette_panel_scene.instantiate() as BombPalettePanel
			if panel:
				bomb_palette.add_child(panel)
				if idx < bomb_info_arr.size():
					panel.bomb_info = bomb_info_arr[idx]
					panel.pressed.connect(add_step.bind(bomb_info_arr[idx]))
					panel.mouse_entered.connect(show_info.bind(bomb_info_arr[idx]))
					panel.focus_entered.connect(show_info.bind(bomb_info_arr[idx]))
					panel.mouse_exited.connect(hide_info)
					panel.focus_exited.connect(hide_info)
				idx += 1


## Adds a step.
func add_step(bomb_info: BombInfo) -> void:
	var new_panel := bomb_step_panel_scene.instantiate() as BombStepPanel
	if new_panel:
		bomb_steps.add_child(new_panel)
		new_panel.bomb_info = bomb_info
		new_panel.close_requested.connect(remove_step.bind(new_panel))
		new_panel.move_up_requested.connect(move_step.bind(new_panel, -1))
		new_panel.move_down_requested.connect(move_step.bind(new_panel, 1))
		await get_tree().process_frame
		bomb_steps_scroller.ensure_control_visible(new_panel as Control)
	_update_step_numbers()


## Removes a step.
func remove_step(step: BombStepPanel) -> void:
	if step.get_parent() != bomb_steps:
		return
	bomb_steps.remove_child(step)
	_update_step_numbers()


## Moves a step
func move_step(step: BombStepPanel, offset: int) -> void:
	if step.get_parent() != bomb_steps:
		return
	var index := clampi(step.get_index() + offset, 0, bomb_steps.get_child_count()-1)
	bomb_steps.move_child(step, index)
	_update_step_numbers()


## Removes all steps
func clear() -> void:
	for child in bomb_steps.get_children():
		if child is BombStepPanel:
			child.queue_free()
	_update_step_numbers()


## Returns the array of steps the player wants taken by the bomb
func get_steps() -> Array[BombStep]:
	var result: Array[BombStep]
	for child in bomb_steps.get_children():
		var step_panel := child as BombStepPanel
		if step_panel and step_panel.bomb_info:
			var step := BombStep.new()
			step.scene = step_panel.bomb_info.scene
			step.fuse_time = step_panel.fuse_time
			result.append(step)
	return result


## Creates an instance of the bomb
func instantiate_bomb() -> Bomb:
	var steps := get_steps()
	if steps.is_empty():
		return null
	if not steps[0].scene:
		return null
	var instance := steps[0].scene.instantiate() as Bomb
	if not instance:
		return null
	instance.next_steps = steps.slice(1)
	instance.fuse_time = steps[0].fuse_time
	return instance


## Displays the bomb information
func show_info(bomb_info: BombInfo) -> void:
	if not bomb_info:
		hide_info()
		return
	flavor_name_label.text = 'NAME: "%s"' % bomb_info.flavor_name
	name_label.text = "TYPE: %s" % bomb_info.name
	description_label.text = bomb_info.description
	flavor_description_label.text = bomb_info.flavor_description
	doctor_sprite.current_expression = bomb_info.doctor_expression
	doctor_sprite.talking = true


## Hides the bomb info
func hide_info() -> void:
	flavor_name_label.text = ""
	name_label.text = ""
	description_label.text = ""
	flavor_description_label.text = ""
	doctor_sprite.reset_expression()
	doctor_sprite.talking = false


## Get how many bombs will be spawned overall
func get_bombs_spawned() -> int:
	var steps := bomb_steps.get_children()
	steps.reverse()
	var total := 0
	for child in steps:
		var step_panel := child as BombStepPanel
		if step_panel and step_panel.bomb_info:
			total *= step_panel.bomb_info.children_spawned
			total += 1
		
	return total


func _update_step_numbers() -> void:
	var counter := 0
	for child in bomb_steps.get_children():
		var panel := child as BombStepPanel
		if panel and not panel.is_queued_for_deletion():
			counter += 1
			panel.number = counter
			panel.up_button.disabled = counter == 1
			panel.down_button.disabled = counter == bomb_steps.get_child_count()
	var bomb_count := get_bombs_spawned()
	bomb_count_label.text = "Number of bombs that will spawn: %d" % bomb_count
	var level_wrapper := get_tree().get_first_node_in_group(&"level_wrapper") as LevelWrapper
	if level_wrapper:
		var completion := level_wrapper.get_current_level_completion_state()
		if completion:
			bomb_count_label.text += "\nBest: %d" % completion.best_bomb_count
		else:
			bomb_count_label.text += "\nBest: N/A (you haven't beat the level!)"
	if bomb_count > SAFE_BOMB_LIMIT:
		bomb_count_label.modulate = Color.RED
		_bomb_warning = true
	else:
		bomb_count_label.modulate = Color.WHITE
		_bomb_warning = false
		
	if bomb_count == 0:
		go_button.text = "PREVIEW"
	elif bomb_count <= SAFE_BOMB_LIMIT:
		go_button.text = "GO"
	else:
		go_button.text = "...go?"


func _on_go_button_pressed() -> void:
	if _bomb_warning:
		too_many_bombs_popup.visible = true
	else:
		player_ready.emit()


func _on_quit_button_pressed() -> void:
	player_quit.emit()


func _on_confirm_no_button_pressed() -> void:
	too_many_bombs_popup.visible = false


func _on_confirm_yes_button_pressed() -> void:
	too_many_bombs_popup.visible = false
	player_ready.emit()


func _on_visibility_changed() -> void:
	if not is_node_ready():
		await ready
	_update_step_numbers()
