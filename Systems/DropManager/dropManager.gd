extends RefCounted

## 世界的副管理器，掉落物
class_name DropManager
# 不再定义 drop_added / drop_removed 信号
# 改用回调函数，由World注入回调

enum DropDestroyReason {
	NATURE = 0,
	PICKUP = 1
}
 
## 映射: uid -> DropItemData
var drop_dict:Dictionary = {}

## 回调委托，由World传入
signal on_drop_added(new_drop: DropItemData)
signal on_drop_removed(uid: int, item: Item, destory: DropDestroyReason)
signal on_drop_apply_force(uid: int, absorb_force: Vector2)
signal on_entity_add(new_drop: DropItemData)
signal on_entity_destroy(uid: int, entity_type: EntityBase.EntityType)

var PICKUP_RANGE: float = CoordinateAttributes.get_coordinate_distance() * 4
var ABSORB_SPEED: float = 1200 * 60
var PICKUP_THRESHOLD: float = CoordinateAttributes.get_coordinate_distance() * 1
var DROP_LIFETIME: float = 300

## 生成掉落物
func spawn(new_uid: int, item:Item, spawn_pos:Vector2, world_time:float, spawn_vel:Vector2=Vector2.ZERO) -> void:
	var new_drop = EntitySpawner.spawn_drop_item(new_uid, item, spawn_pos, world_time)
	new_drop.velocity = spawn_vel
	drop_dict[new_drop.get_uid()] = new_drop
	DebugSystem.console_common_log("世界[掉落物管理器]", "生成掉落物: uid: %s , 物品: %s, 对应名字: %s" % [new_drop.get_uid(), item, item.get_item_instance().get_item_name()])
	on_entity_add.emit(new_drop)
	# 回调给World
	on_drop_added.emit(new_drop)

## 单物品自持监测掉落物清除以及掉落物操作
## 主要是tick时间，是掉落物计数器
func tick(delta:float, world_time:float, player_dict:Dictionary) -> void:
	var to_remove_nature: Array[int] = []
	var to_remove_pick_up: Array[int] = []
	
	# 遍历所有玩家
	for uid in drop_dict:
		var drop:DropItemData = drop_dict[uid]
		if drop.is_pending_remove:
			continue
		
		# 生命周期超时，标记删除
		if world_time - drop.spawn_time >= DROP_LIFETIME:
			to_remove_nature.append(uid)
			drop.is_pending_remove = true
			continue

		# 【多人核心】查找距离这个掉落物最近的玩家
		var nearest_p_pos:Vector2
		var nearest_uid:int = -1
		var min_dist:float = INF
		for p_uid in player_dict:
			var p_data:PlayerData = player_dict[p_uid]
			var p_pos:Vector2 = p_data.get_player_global_pos()
			var d:float = drop.world_pos.distance_to(p_pos)
			if d < min_dist:
				min_dist = d
				nearest_p_pos = p_pos
				nearest_uid = p_uid
		
		# 没有任何玩家，跳过吸附拾取
		if nearest_uid == -1:
			continue
		
		var dist:float = min_dist
		
		# 进入拾取范围开启吸收标记；离开范围关闭
		if dist < PICKUP_RANGE and not drop.is_absorbing:
			drop.is_absorbing = true
		if dist > PICKUP_RANGE and drop.is_absorbing:
			drop.is_absorbing = false
			
		if drop.is_absorbing:
			var dir = (nearest_p_pos - drop.world_pos).normalized()
			var absorb_force:Vector2 = dir * ABSORB_SPEED * delta
			on_drop_apply_force.emit(uid, absorb_force)
		
		# 距离足够近，拾取成功
		if dist < PICKUP_THRESHOLD:
			to_remove_pick_up.append(uid)
			drop.is_pending_remove = true
			continue
	
	# 批量清理(自然超时)
	for uid in to_remove_nature:
		var drop_instance: DropItemData = drop_dict.get(uid)
		on_drop_removed.emit(uid, drop_instance.item, DropDestroyReason.NATURE)
		on_entity_destroy.emit(uid, drop_instance.entity_type)
		drop_dict.erase(uid)
	
	# 拾取清理
	for uid in to_remove_pick_up:
		var drop_instance: DropItemData = drop_dict.get(uid)
		# 【新增】物品进对应玩家背包
		var target_p_uid:int = -1
		var min_d:float = INF
		for p_uid in player_dict:
			var pd:PlayerData = player_dict[p_uid]
			var d = drop_instance.world_pos.distance_to(pd.get_player_global_pos())
			if d < min_d:
				min_d = d
				target_p_uid = p_uid
		if target_p_uid != -1:
			var target_player:PlayerData = player_dict[target_p_uid]
			DebugSystem.console_common_log("世界[掉落物管理器]", "尝试向玩家背包[uid:%s]添加物品: %s" % [target_p_uid, drop_instance.item])
			# 判断是否完全将物品添加进背包
			var add_ok:bool = target_player.try_pickup_item(drop_instance.item)
			if not add_ok:
				# 拾取
				drop_instance.is_pending_remove = false
				continue
			
		on_drop_removed.emit(uid, drop_instance.item, DropDestroyReason.PICKUP)
		on_entity_destroy.emit(uid, drop_instance.entity_type)
		drop_dict.erase(uid)

## 手动通过 uid 清除掉落物
func manual_remove_drop(uid:int, reason:DropDestroyReason):
	if not drop_dict.has(uid):
		return
	var drop = drop_dict[uid]
	drop.is_pending_remove = true
	on_drop_removed.emit(uid, drop.item, reason)
	on_entity_destroy.emit(uid, drop.entity_type)
	drop_dict.erase(uid)

## 世界信号: 更新掉落物信息
func updated_drop_info(uid: int, new_position: Vector2, in_linear_velocity: Vector2) -> void:
	var drop_instance: DropItemData = drop_dict.get(uid)
	if drop_instance == null:
		## DebugSystem.console_warn_log("世界[掉落物管理器]", "掉落物[uid]: %s 不存在" % uid)
		return
	drop_instance.world_pos = new_position
	drop_instance.velocity = in_linear_velocity
	## DebugSystem.console_common_log("世界[掉落物管理器]", "掉落物[uid]: %s 信息同步成功" % uid)
	
