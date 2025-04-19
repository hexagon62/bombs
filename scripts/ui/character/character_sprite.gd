@tool
class_name CharacterSprite
extends Sprite2D
## Switches between various expressions, while supporting talking/blinking state


## The expressions available to this character
@export var expressions: Dictionary[StringName, CharacterExpression]
## The default expression to usee
@export var default_expression: StringName
## The current expression to use
@export var current_expression: StringName
## Whether or not the character is blinking
@export var blinking := false
## Whether or not the character is talking
@export var talking := false
## Whether or not to preview in the editor
@export var editor_preview := false


var _blinking := false
var _talking := false
var _time := 0.0


func _process(delta: float) -> void:
	if Engine.is_editor_hint() and not editor_preview:
		return
	
	_time += delta*randf_range(0.9, 1.1)
	if blinking:
		_blinking = fmod(_time, 4.0) >= 3.75
	else:
		_blinking = false
	if talking:
		_talking = fmod(_time, 0.25) < 0.125
	else:
		_talking = false
	_update_appearance()


func _update_appearance() -> void:
	if current_expression in expressions:
		texture = expressions[current_expression].get_texture(_blinking, _talking)
	elif default_expression in expressions:
		texture = expressions[default_expression].get_texture(_blinking, _talking)
	else:
		texture = null


func reset_expression() -> void:
	current_expression = default_expression
