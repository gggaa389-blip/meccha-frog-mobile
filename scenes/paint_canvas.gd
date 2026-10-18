extends Node2D

var brush_points: Array[Vector2] = []
var brush_radius: float = 15.0

func paint_at(uv_position: Vector2, radius: float) -> void:
	var viewport_size = get_viewport().size
	var target_pixel = uv_position * Vector2(viewport_size)
	
	brush_points.append(target_pixel)
	brush_radius = radius
	queue_redraw()

func stop_painting() -> void:
	# Clear out current queue points when mouse releases
	if not brush_points.is_empty():
		brush_points.clear()

func _draw() -> void:
	# Iterate and stamp the circles permanently into the viewport's persistent clear-never buffer
	for point in brush_points:
		draw_circle(point, brush_radius, Color(1, 0, 0, 1))
	# Clear the array after drawing so we don't lag accumulating thousands of old points
	brush_points.clear()
