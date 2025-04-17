class_name SignalJoiner
extends Node
## Waits for [Signal]s attached to it to emit before emitting its own signal.


## Emitted when all registered nodes emit their finished signal
signal all_emitted

## Names of the signals to wait on.
## The signals will pass these into [method on_signal_emitted].
@export var signals: Array[StringName]

# Stores which signals we're still waiting on
var _join_state: Dictionary[StringName, bool]
# Stores whether or not [signal all_emitted] has been emitted yet.
var _emitted := false


func _ready() -> void:
	for s in signals:
		_join_state[s] = false


## Connect your signal to this. Make the signal pass in its assigned name.
func on_signal_emitted(signal_name: StringName) -> void:
	# Don't do anything in the editor
	if Engine.is_editor_hint():
		return
	
	# If we've already emitted the all_emitted signal, we're done
	if _emitted:
		return
	
	# We're no longer waiting on this signal
	_join_state[signal_name] = true
	
	# Check if we're still waiting on anything
	for v in _join_state.values():
		if not v:
			return
	
	# We're not, we're done. Emit the all_emitted signal.
	all_emitted.emit()
	_emitted = true


## Returns [code]true[/code] if [signal all_emitted] has been emitted.
func is_done() -> bool:
	return _emitted
