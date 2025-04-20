@tool
class_name ProgressBarWithThreshold
extends Panel


## The ratio to display
@export_range(0.0, 1.0, 0.001) var progress_ratio := 0.0:
	get: return progress_ratio
	set(value):
		progress_ratio = clampf(value, 0.0, 1.0)
		_update_label()
		_update_appearance()
## The threshold ratio to display
@export_range(0.0, 1.0, 0.001) var threshold_ratio := 0.0:
	get: return threshold_ratio
	set(value):
		threshold_ratio = clampf(value, 0.0, 1.0)
		_update_label()
		_update_appearance()
## The color for the progress bar when below the threshold
@export var below_threshold_modulate := Color.WHITE:
	get: return below_threshold_modulate
	set(value):
		below_threshold_modulate = value
		_update_appearance()
## The color for the progress bar when above the threshold
@export var above_threshold_modulate := Color.WHITE:
	get: return above_threshold_modulate
	set(value):
		above_threshold_modulate = value
		_update_appearance()
## The color for the threshold bar
@export var threshold_modulate := Color.WHITE:
	get: return threshold_modulate
	set(value):
		threshold_modulate = value
		_update_appearance()

@onready var progress_bar: Panel = $ProgressBar
@onready var threshold_bar: Panel = $ThresholdBar
@onready var label: Label = $Label


func _update_appearance() -> void:
	if not is_node_ready():
		await ready
	progress_bar.position = Vector2(size.x*(progress_ratio - 1.0), 0.0)
	threshold_bar.position = Vector2(size.x*(threshold_ratio - 1.0), 0.0)
	threshold_bar.modulate = threshold_modulate
	if progress_ratio < threshold_ratio:
		progress_bar.modulate = below_threshold_modulate
	else:
		progress_bar.modulate = above_threshold_modulate


func _update_label() -> void:
	if not is_node_ready():
		await ready
	label.text = "%d%%" % (progress_ratio*100.0)
