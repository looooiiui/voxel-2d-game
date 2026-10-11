extends Node
class_name InputController

# 信号：请求销毁方块，携带目标全局方块坐标
signal block_destroy_request(global_tile_pos:Vector2i)
# 信号：请求放置方块，携带目标全局方块坐标
signal block_place_request(global_tile_pos:Vector2i)

var camera: Camera2D
var world: World
# 开关，弹窗的时候关闭方块点击
@export var enable_block_interact: bool = true

func _input(event: InputEvent) -> void:
	if not enable_block_interact:
		return
	# 左键按下
	if event.is_action_pressed("mouse_left"):
		_handle_left_click()
	if event.is_action_pressed("mouse_right"): # 右键用来放置
		DebugSystem.console_common_log("输入控制系统", "按下右键(放置)")
		_handle_place_click()

func _handle_left_click() -> void:
	# 相机：屏幕坐标 → 世界浮点数像素坐标
	var world_mouse_pos: Vector2 = camera.get_global_mouse_position()
	# 换算全局方块网格坐标，一格32像素
	var global_tile = CoordinateAttributes.cal_current_grid_pos(world_mouse_pos.x, world_mouse_pos.y)
	# 仅仅发送请求，由World去做校验+修改数据
	DebugSystem.console_common_log("输入控制系统", "按下左键,执行直接销毁请求，坐标: %s" % global_tile)
	emit_signal("block_destroy_request", global_tile)
	
	
# 新增：放置
func _handle_place_click() -> void:
	var world_mouse_pos: Vector2 = camera.get_global_mouse_position()
	var global_tile = Vector2i(
		floor(world_mouse_pos.x / 32.0),
		floor(world_mouse_pos.y / 32.0)
	)
	DebugSystem.console_common_log("输入控制系统", "发送放置请求 %s" % global_tile)
	emit_signal("block_place_request", global_tile)
	
