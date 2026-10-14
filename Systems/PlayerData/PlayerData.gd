extends EntityBase

## 玩家数据类
class_name PlayerData

## 玩家属性
var spawn_position: Vector2 = Vector2(0, 0)
var move_speed: float = 300
var jump_velocity: float = -400.0
var global_position: Vector2
var grid_pos: Vector2i = Vector2i(0, 0)

## 玩家初始化
func _init(new_uid: int, spawn_global_pos: Vector2 = Vector2(0, 0)) -> void:
	global_position = spawn_global_pos
	spawn_position = spawn_global_pos
	# 初始化类型
	entity_type = EntityBase.EntityType.PLAYER
	uid = new_uid
	
## 获得玩家全局位置
func get_player_global_pos() -> Vector2:
	return global_position
	
## 获得玩家网格位置
func get_player_grid_pos() -> Vector2:
	return grid_pos
	
## 外部同步数据
func sync_data(player_global_position: Vector2) -> void:
	global_position = player_global_position
	_sync_grid_pos()
	
## 同步网格坐标(内部调用，在外部传入实际位置的时候)
func _sync_grid_pos() -> void:
	grid_pos = CoordinateAttributes.cal_current_grid_pos(global_position.x, global_position.y)
