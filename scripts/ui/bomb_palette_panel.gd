@tool
class_name BombPalettePanel
extends Button


@export var bomb_info: BombInfo:
	get: return bomb_info
	set(value):
		if not is_node_ready():
			await ready
		bomb_info = value
		if value:
			label.text = bomb_info.short_name
			icon_rect.texture = bomb_info.icon
			disabled = false
		else:
			label.text = ""
			icon_rect.texture = null
			disabled = true

@onready var label: Label = %Label
@onready var icon_rect: TextureRect = %IconRect
