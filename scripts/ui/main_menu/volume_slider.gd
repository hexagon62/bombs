class_name VolumeSlider
extends HSlider


func _ready() -> void:
	drag_ended.connect(_set_volume)
	load_settings()


func _set_volume(modified := true):
	if modified:
		AudioServer.set_bus_volume_linear(0, value)
		save_settings()


## Save the player's settings
func save_settings() -> void:
	var dict := {"volume": value}
	var save_file := FileAccess.open("user://settings.save", FileAccess.WRITE)
	save_file.store_line(JSON.stringify(dict))


## Load the player's settings, if it exists
func load_settings() -> void:
	var save_file := FileAccess.open("user://settings.save", FileAccess.READ)
	if save_file:
		var raw := save_file.get_as_text()
		var json_result: Variant = JSON.parse_string(raw)
		if typeof(json_result) == TYPE_DICTIONARY:
			if "volume" in json_result and typeof(json_result["volume"]) == TYPE_FLOAT:
				value = json_result["volume"]
				_set_volume()
	else:
		value = 0.5
