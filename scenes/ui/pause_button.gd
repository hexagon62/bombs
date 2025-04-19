class_name PauseButton
extends Button


## The icon for when the game is paused
@export var paused_icon: Texture2D
## The icon for when the game is not paused
@export var unpaused_icon: Texture2D
## Controls which texture to show
@export var paused := false:
	get: return paused
	set(value):
		paused = value
		if paused:
			icon = paused_icon
		else:
			icon = unpaused_icon
