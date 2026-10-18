# Save this script as "canvas_painter.gd" and attach it to your Canvas node
extends Node2D

var lines_to_draw: Array = []

class StrokeLine:
	var from: Vector2
	var to: Vector2
	var thickness: float
	var color: Color
	func _init(f: Vector2, t: Vector2, th: float, c: Color):
		from = f; to = t; thickness = th; color = c

func add_stroke(from_pos: Vector2, to_pos: Vector2, thickness: float, color: Color):
	lines_to_draw.append(StrokeLine.new(from_pos, to_pos, thickness, color))
	queue_redraw()

func _draw() -> void:
	# Draw all pending mouse path segments sent from the camera script
	for line in lines_to_draw:
		draw_line(line.from, line.to, line.color, line.thickness, true)
	lines_to_draw.clear() # Clear the queue after baking it into the viewport buffer
