@tool
class_name CharacterSprite
extends Sprite2D
## Switches between various expressions, while supporting talking/blinking state


@export var expressions: Dictionary[StringName, CharacterExpression]:
	get: return expressions
	set(value):
		expressions = value
## The current expression to use
@export var current_expression: StringName:
	get: return current_expression
	set(value):
		current_expression = value
## Whether or not the character is blinking
@export var blinking := false:
	get: return blinking
	set(value):
		blinking = value
## Whether or not the character is talking
@export var talking := false:
	get: return talking
	set(value):
		talking = value


var _blinking := false
var _talking := false
var _time := 0.0


func _process(delta: float) -> void:
	_time += delta*randf_range(0.9, 1.1)
	if blinking:
		_blinking = fmod(_time, 4.0) >= 3.75
	if talking:
		_talking = fmod(_time, 0.25) < 0.125
	_update_appearance()


func _update_appearance() -> void:
	if current_expression in expressions:
		texture = expressions[current_expression].get_texture(_blinking, _talking)
	else:
		texture = null
