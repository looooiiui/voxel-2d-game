extends RefCounted

class_name CoordinateAttributes

const _DEFAULT_DISTANCE: int = 32
## 这个是全局像素坐标系统，用来确定整个游戏的像素位置的
static var _distance: int = _DEFAULT_DISTANCE

## 获取全局像素距离
static func get_global_distance() -> int:
	return _distance

## 修改全局格子大小，带合法性校验
static func set_distance(new_val: int) -> void:
	if new_val <= 0:
		push_warning("CoordinateAttributes: distance不能小于等于0！保持旧值 %s" % _distance)
		return
	_distance = new_val

## 返回对应网格距离
static func get_coordinate_distance() -> int:
	return CoordinateAttributes.get_global_distance()
	
## 计算当前网格位置
static func cal_current_grid_pos(pos_x: float, pos_y: float) -> Vector2i:
	var current_distance: int = get_coordinate_distance()
	var cal_grid_x = floori(pos_x / current_distance)
	var cal_grid_y = floori(pos_y / current_distance)
	# 生成完整坐标
	return Vector2i(cal_grid_x, cal_grid_y)
	
## 将网格坐标转化为实际坐标
static func switch_grid_position(grid_x: int, grid_y: int) -> Vector2:
	var current_distance: int = get_coordinate_distance()
	var position_x = grid_x * current_distance
	var position_y = grid_y * current_distance
	# 完整实际坐标
	return Vector2(position_x, position_y)
