extends Line2D
@export var camera: Camera2D
## 选择是否绘画
@export var use_draw: bool = true

var lerp_speed: float = 8
var preview_pos: Vector2i = Vector2i.ZERO

func _physics_process(delta: float) -> void:
	if use_draw:
		_draw_line(delta)

## 画鼠标网格
func _draw_line(delta: float) -> void:
	var vmouse = camera.get_global_mouse_position()
	# 获得网格对应实际整数位置
	var mouse_grid = CoordinateAttributes.cal_current_grid_pos(vmouse.x, vmouse.y)
	var switch_pos = CoordinateAttributes.switch_grid_position(mouse_grid.x, mouse_grid.y)
	preview_pos.x = switch_pos.x
	preview_pos.y = switch_pos.y
	# global_position = lerp(global_position, Vector2(preview_pos.x, preview_pos.y), lerp_speed * delta)
	global_position = Vector2(preview_pos.x, preview_pos.y)
	# 方块四个角（世界空间）
	var origin = Vector2(0, 0)
	var grip_distance = CoordinateAttributes.get_coordinate_distance()
	var p1 = origin
	var p2 = origin + Vector2(grip_distance,0)
	var p3 = origin + Vector2(grip_distance,grip_distance)
	var p4 = origin + Vector2(0,grip_distance)
	# 绘制方框
	points = [p1, p2, p3, p4]
