class_name BombBuilder
extends Control


const PALETTE_LENGTH_GRANULE := 18

## Player pressed go button
signal go_pressed

var bomb_palette_panel_scene := preload("res://scenes/ui/bomb_builder/ui_bomb_palette_panel.tscn")
var bomb_step_panel_scene := preload("res://scenes/ui/bomb_builder/ui_bomb_step_panel.tscn")

@onready var bomb_palette: Control = %BombPalette
@onready var bomb_steps: VBoxContainer = %BombStepsContainer
@onready var bomb_steps_scroller: ScrollContainer = %BombStepsScroller
@onready var flavor_name_label: Label = %FlavorNameLabel
@onready var name_label: Label = %NameLabel
@onready var description_label: Label = %DescriptionLabel
@onready var flavor_description_label: Label = %FlavorDescriptionLabel
@onready var bomb_count_label: Label = %BombCountLabel


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


## Displays the bomb information
func show_info(bomb_info: BombInfo) -> void:
	if not bomb_info:
		hide_info()
		return
	flavor_name_label.text = 'NAME: "%s"' % bomb_info.flavor_name
	name_label.text = "TYPE: %s" % bomb_info.name
	description_label.text = bomb_info.description
	flavor_description_label.text = bomb_info.flavor_description


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


## Hides the bomb info
func hide_info() -> void:
	flavor_name_label.text = ""
	name_label.text = ""
	description_label.text = ""
	flavor_description_label.text = ""


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
	bomb_count_label.text = "Number of bombs that will spawn: %d" % get_bombs_spawned()


func _on_go_button_pressed() -> void:
	go_pressed.emit()
