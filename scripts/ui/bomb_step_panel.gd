@tool
class_name BombStepPanel
extends Control


## The panel was requested to be closed
signal close_requested
## The panel was requested to move up
signal move_up_requested
## The panel was requested to move down
signal move_down_requested

## The number of the step
@export var number := -1:
	get: return number
	set(value):
		number = value
		_update_appearance()
## The bomb to be used
@export var bomb_info: BombInfo:
	get: return bomb_info
	set(value):
		bomb_info = value
		if bomb_info:
			fuse_time_slider.min_value = bomb_info.min_fuse_time
			fuse_time_slider.max_value = bomb_info.max_fuse_time
			fuse_time_slider.value = bomb_info.default_fuse_time
			var ticks := bomb_info.max_fuse_time - bomb_info.min_fuse_time
			if ticks > 10.0:
				ticks /= 5.0
			fuse_time_slider.tick_count = floori(ticks)
			_on_fuse_time_changed(bomb_info.default_fuse_time)
		_update_appearance()
## The time in seconds until the bomb will explode
@export var fuse_time := 1.0:
	get: return fuse_time_slider.value
	set(value):
		fuse_time_slider.value = value

@onready var icon: TextureRect = %Icon
@onready var step_name_label: Label = %StepNameLabel
@onready var fuse_time_slider: HSlider = %FuseTimeSlider
@onready var fuse_time_label: Label = %FuseTimeLabel
@onready var up_button: Button = %UpButton
@onready var down_button: Button = %DownButton
@onready var close_button: Button = %CloseButton


func _update_appearance() -> void:
	if bomb_info:
		icon.texture = bomb_info.icon
		step_name_label.text = "STEP #%d: %s" % [number, bomb_info.name]
	else:
		icon.texture = null
		step_name_label.text = "STEP #%d: NONE" % number


func _on_fuse_time_changed(value: float) -> void:
	fuse_time_label.text = "%.2fs" % value


func _on_close_button_pressed() -> void:
	close_requested.emit()


func _on_move_up_button_pressed() -> void:
	move_up_requested.emit()


func _on_move_down_button_pressed() -> void:
	move_down_requested.emit()
