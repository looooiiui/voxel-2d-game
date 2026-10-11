extends Node

# 返回对应网格距离
func get_coordinate_distance() -> int:
	return CoordinateAttributes.get_global_distance()
	
# 计算当前网格位置
func cal_current_grid_pos(pos_x: float, pos_y: float) -> Vector2i:
	var current_distance: int = get_coordinate_distance()
	var cal_grid_x = floori(pos_x / current_distance)
	var cal_grid_y = floori(pos_y / current_distance)
	# 生成完整坐标
	return Vector2i(cal_grid_x, cal_grid_y)
	
# 将网格坐标转化为实际坐标
func switch_grid_position(grid_x: int, grid_y: int) -> Vector2:
	var current_distance: int = get_coordinate_distance()
	var position_x = grid_x * current_distance
	var position_y = grid_y * current_distance
	# 完整实际坐标
	return Vector2(position_x, position_y)
	
