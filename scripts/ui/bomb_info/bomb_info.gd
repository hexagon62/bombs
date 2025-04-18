class_name BombInfo
extends Resource


## The icon for the bomb
@export var icon: Texture2D
## The name of the bomb
@export var name: String
## The shortened name of the bomb, for display in the palette
@export var short_name: String
## The flavor text name of the bomb (the long one)
@export var flavor_name: String
## The description of the bomb's function
@export_multiline var description: String
## The flavor text description for the bomb
@export_multiline var flavor_description: String
## What expression this bomb should make the doctor have in the UI
@export var doctor_expression := &"neutral"
## The scene to instantiate for this bomb
@export var scene: PackedScene
## Whether or not this bomb requires a bomb after it
@export var requires_next_step := false
## How many bombs this bomb will spawn
@export_range(1, 10, 1, "or_greater") var children_spawned := 1
## The minimum fuse time for the bomb
@export_range(0.0, 20.0, 0.1, "or_greater", "suffix:s") var min_fuse_time := 0.0:
	get: return min_fuse_time
	set(value):
		min_fuse_time = value
		if min_fuse_time > max_fuse_time:
			min_fuse_time = max_fuse_time
## The maximum fuse time for the bomb
@export_range(0.0, 20.0, 0.1, "or_greater", "suffix:s") var max_fuse_time := 5.0:
	get: return max_fuse_time
	set(value):
		max_fuse_time = value
		if max_fuse_time < min_fuse_time:
			max_fuse_time = min_fuse_time
## The default fuse time for the bomb
@export_range(0.0, 20.0, 0.1, "or_greater", "suffix:s") var default_fuse_time := 1.0:
	get: return default_fuse_time
	set(value):
		default_fuse_time = clamp(value, min_fuse_time, max_fuse_time)
