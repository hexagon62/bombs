class_name BombWithCustomSpawns
extends Bomb


## How this bomb will spawn the next bombs.
## Each entry corresponds to one bomb spawned,
## so multiple entries means more bombs.
@export var spawns: Array[BombSpawnParameters]


func _explode() -> void:
	_apply_explosion_effects()
	for spawn in spawns:
		var velocity := Vector2.from_angle(spawn.angle)*spawn.speed
		spawn_next(velocity, spawn.angular_velocity, spawn.add)
