class_name BombSpawnParameters
extends Resource


## The speed of the bomb being spawned
@export_range(0.0, 10000.0, 1.0, "suffix:px/s") var speed := 4000.0
## The angle of the bomb's velocity
@export_range(-180, 180, 1.0, "radians_as_degrees", "degrees")
var angle := 0.0
## The angular velocity of the bomb
@export_range(-720, 720, 1.0, "radians_as_degrees", "degrees", "suffix:°/s")
var angular_velocity := 0.0
## Whether or not to add this to the previous bomb's velocity
@export var add := true
