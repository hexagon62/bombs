@tool
class_name CharacterExpression
extends Resource
## Stores sprites for a character's expression


@export var normal_texture: Texture2D
@export var blinking_texture: Texture2D
@export var talking_texture: Texture2D
@export var talking_and_blinking_texture: Texture2D


func get_texture(blinking: bool, talking: bool) -> Texture2D:
	if blinking:
		if talking:
			return talking_and_blinking_texture
		else:
			return blinking_texture
	elif talking:
		return talking_texture
	return normal_texture
