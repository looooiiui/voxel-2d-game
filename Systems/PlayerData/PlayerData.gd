extends EntityBase

## 玩家数据类
class_name PlayerData

## 玩家属性
var spawn_position: Vector2 = Vector2(0, 0)
var move_speed: float = 300
var jump_velocity: float = -400.0
var global_position: Vector2
var grid_pos: Vector2i = Vector2i(0, 0)
## 玩家背包，玩家自持
var back_pack: BackPack
## 玩家快捷栏
var inventory_quick_bar: InventoryQuickBar

## 玩家初始化
func _init(new_uid: int, spawn_global_pos: Vector2 = Vector2(0, 0)) -> void:
	global_position = spawn_global_pos
	spawn_position = spawn_global_pos
	# 初始化类型
	entity_type = EntityBase.EntityType.PLAYER
	back_pack = BackPack.new()
	inventory_quick_bar = InventoryQuickBar.new()
	uid = new_uid
	DebugSystem.console_common_log("玩家", "uid: %s 创建新的背包: %s" % [new_uid, back_pack])

## 获得玩家背包
func get_player_back_pack() -> BackPack:
	return back_pack
## 获得玩家快捷栏
func get_player_inventory_quick_bar() -> InventoryQuickBar:
	return inventory_quick_bar
	
## 获得玩家全局位置
func get_player_global_pos() -> Vector2:
	return global_position
	
## 获得玩家网格位置
func get_player_grid_pos() -> Vector2i:
	return grid_pos
	
## 外部同步数据
func sync_data(player_global_position: Vector2) -> void:
	global_position = player_global_position
	_sync_grid_pos()
	
## 同步网格坐标(内部调用，在外部传入实际位置的时候)
func _sync_grid_pos() -> void:
	grid_pos = CoordinateAttributes.cal_current_grid_pos(global_position.x, global_position.y)

func try_pickup_item(item:Item) -> bool:
	# 未来可以在这里加玩家状态拦截
	# if cannot_pickup: return false
	var result = get_player_inventory_quick_bar().try_add_item(item)
	if !result:
		result = get_player_back_pack().try_add_item(item)
	return result
