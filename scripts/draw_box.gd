class_name DrawBox
extends Control
## Callable で中身を描く小さなコントロール（Art の描画関数を UI に置くため）。

var painter: Callable


func _init(p: Callable = Callable(), min_size := Vector2(64, 64)) -> void:
	painter = p
	custom_minimum_size = min_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	resized.connect(queue_redraw)


func _draw() -> void:
	if painter.is_valid():
		painter.call(self)
