extends RefCounted

## 世界的副管理器，掉落物
class_name DropManager
# 不再定义 drop_added / drop_removed 信号
# 改用回调函数，由World注入回调

enum DropDestroyReason {
	NATURE = 0,
	PICKUP = 1
}
 
## 掉落物 ID
var _uid_counter:int = 0
## 映射: uid -> DropInstance
var drop_dict:Dictionary = {}

# 回调委托，由World传入
var on_drop_added: Callable
var on_drop_removed: Callable
var on_drop_apply_force: Callable

var PICKUP_RANGE: float = CoordinateAttributes.get_coordinate_distance() * 4
var ABSORB_SPEED: float = 1200 * 60
var PICKUP_THRESHOLD: float = CoordinateAttributes.get_coordinate_distance() * 1
var DROP_LIFETIME: float = 300

## 生成掉落物
func spawn(item:Item, spawn_pos:Vector2, world_time:float, spawn_vel:Vector2=Vector2.ZERO) -> void:
	var new_uid = _uid_counter
	_uid_counter += 1
	var new_drop = DropItemInstance.new(new_uid, item, spawn_pos, world_time)
	new_drop.velocity = spawn_vel
	drop_dict[new_uid] = new_drop
	DebugSystem.console_common_log("世界[掉落物管理器]", "生成掉落物: uid: %s , 物品: %s, 对应名字: %s" % [new_uid, item, item.get_item_instance().get_item_name()])
	# 回调给World
	if on_drop_added != null:
		on_drop_added.call(new_drop)

## 单物品自持监测掉落物清除以及掉落物操作
## 主要是tick时间，是掉落物计数器
func tick(delta:float, world_time:float, player_pixel_pos:Vector2) -> void:
	var to_remove_nature: Array[int] = []
	var to_remove_pick_up: Array[int] = []
	for uid in drop_dict:
		var drop:DropItemInstance = drop_dict[uid]
		# 已经进入删除组的越过判断
		if drop.is_pending_remove:
			continue
		# 生命周期超时，标记删除
		if world_time - drop.spawn_time >= DROP_LIFETIME:
			to_remove_nature.append(uid)
			drop.is_pending_remove = true
			continue # 直接跳过，不再做距离、拾取判定
		var dist = drop.world_pos.distance_to(player_pixel_pos)
		# 进入拾取范围，开启吸收标记
		if dist < PICKUP_RANGE and not drop.is_absorbing:
			drop.is_absorbing = true
		
		if drop.is_absorbing:
			var dir = (player_pixel_pos - drop.world_pos).normalized()
			var absorb_force:Vector2 = dir * ABSORB_SPEED * delta
			on_drop_apply_force.call(uid, absorb_force)
		
		# 足够靠近，拾取成功，标记删除
		if dist < PICKUP_THRESHOLD:
			to_remove_pick_up.append(uid)
			drop.is_pending_remove = true
			continue
	
	# 批量清理(自然状态超时清理)
	for uid in to_remove_nature:
		# 先传出对应Item
		if on_drop_removed.is_valid():
			var drop_instance: DropItemInstance = drop_dict.get(uid)
			on_drop_removed.call(uid, drop_instance.item, DropDestroyReason.NATURE)
		drop_dict.erase(uid)
	
	# 拾取状态清理	
	for uid in to_remove_pick_up:
		# 先传出对应Item
		if on_drop_removed != null:
			var drop_instance: DropItemInstance = drop_dict.get(uid)
			on_drop_removed.call(uid, drop_instance.item, DropDestroyReason.PICKUP)
		drop_dict.erase(uid)
			
## 世界信号: 更新掉落物信息
func updated_drop_info(uid: int, new_position: Vector2, in_linear_velocity: Vector2) -> void:
	var drop_instance: DropItemInstance = drop_dict.get(uid)
	if drop_instance == null:
		## DebugSystem.console_warn_log("世界[掉落物管理器]", "掉落物[uid]: %s 不存在" % uid)
		return
	drop_instance.world_pos = new_position
	drop_instance.velocity = in_linear_velocity
	## DebugSystem.console_common_log("世界[掉落物管理器]", "掉落物[uid]: %s 信息同步成功" % uid)
	
