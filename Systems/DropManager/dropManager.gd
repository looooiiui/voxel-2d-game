extends RefCounted

## 世界的副管理器，掉落物
class_name DropManager
# 不再定义 drop_added / drop_removed 信号
# 改用回调函数，由World注入回调

## 掉落物 ID
var _uid_counter:int = 0
var drop_dict:Dictionary = {}

# 回调委托，由World传入
var on_drop_added: Callable
var on_drop_removed: Callable
var on_drop_apply_force: Callable

var PICKUP_RANGE: float = CoordinateAttributes.get_coordinate_distance() * 4
var ABSORB_SPEED: float = 120.0
var PICKUP_THRESHOLD: float = CoordinateAttributes.get_coordinate_distance() * 1.5
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
	var to_remove:Array[int] = []
	for uid in drop_dict:
		var drop:DropItemInstance = drop_dict[uid]
		# 生命周期超时，标记删除
		if world_time - drop.spawn_time >= DROP_LIFETIME:
			to_remove.append(uid)
			continue
		var dist = drop.world_pos.distance_to(player_pixel_pos)
		# 进入拾取范围，开启吸收标记
		if dist < PICKUP_RANGE and not drop.is_absorbing:
			drop.is_absorbing = true
		
		if drop.is_absorbing:
			# 计算吸收方向与本帧力，不再直接修改drop.velocity
			# DebugSystem.console_common_log("世界[掉落管理器]", "掉落物: %s 进入范围，正在发送力消息" % uid)
			var dir = (player_pixel_pos - drop.world_pos).normalized()
			var absorb_force:Vector2 = dir * ABSORB_SPEED * delta
			# 调用world，发送力指令
			on_drop_apply_force.call(uid, absorb_force)
		
		# 足够靠近，拾取成功，标记删除
		if dist < PICKUP_THRESHOLD:
			to_remove.append(uid)
	
	# 批量清理
	for uid in to_remove:
		drop_dict.erase(uid)
		if on_drop_removed != null:
			on_drop_removed.call(uid)
