class_name DebugBombRaycastVisualizer
extends Node2D


var raycasts: Array[Dictionary]
var hits: Dictionary[int, Vector2]


func _draw() -> void:
	for raycast in raycasts:
		var from := raycast.from as Vector2
		var to := raycast.to as Vector2
		var color := raycast.color as Color
		var hit := raycast.hit as bool
		draw_line(from, to, Color(color, 0.25))
		if hit:
			draw_circle(to, 4.0, Color(color, 0.5))
	for hit in hits.values():
		draw_circle(hit, 6.0, Color.MAGENTA)


func _process(delta: float) -> void:
	if not get_tree().paused:
		clear()


func clear() -> void:
	raycasts.clear()
	hits.clear()
	queue_redraw()
