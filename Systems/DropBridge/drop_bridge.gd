extends Node

## 掉落物中转桥
class_name DropBridge

signal drop_position_updated(uid: int, new_position: Vector2, linear_velocity: Vector2)

@export var drop_entity_scene: PackedScene

# 掉落物映射表: uid -> 实体 
var entity_map: Dictionary = {}

func _physics_process(delta: float) -> void:
	_sync_drop_item_position()

## 根据世界掉落物管理器发来的消息创建掉落物
func on_drop_added(drop_data:DropItemData):
	# 新建实体，把drop_data、bridge自身引用传进去
	var new_entity = drop_entity_scene.instantiate()
	var drop_entity_script: DropItemEntity = new_entity as DropItemEntity
	if drop_entity_script == null:
		DebugSystem.console_warn_log("掉落桥", "掉落物场景: uid: %s 没有挂载脚本" % drop_data.uid)
	# 【注入数据】调用初始化函数，把 uid、bridge、drop实例传给场景脚本
	drop_entity_script.setup(drop_data.uid, drop_data.item.get_item_instance().get_item_name(), self)
	
	# 设置初始位置
	new_entity.global_position = drop_data.world_pos
	var spwan_velocity: Vector2 = drop_data.velocity
	new_entity.set_axis_velocity(spwan_velocity)
	add_child(new_entity)
	entity_map[drop_data.uid] = new_entity
	DebugSystem.console_common_log("掉落桥", "生成掉落实体 uid= %d, 坐标: %s" % [drop_data.uid, drop_data.world_pos])
	

## 清除掉落物
func on_drop_removed(uid:int, item: Item, remove_reason: DropManager.DropDestroyReason):
	if entity_map.has(uid):
		var ent = entity_map[uid]
		ent.queue_free()
		entity_map.erase(uid)
		DebugSystem.console_common_log("掉落桥", "销毁掉落实体 uid= %d, 销毁原因: %s" % [uid, remove_reason])

## 给掉落物施加推力
func on_drop_apply_force(uid:int, force:Vector2):
	if entity_map.has(uid):
		var ent:DropItemEntity = entity_map[uid]
		var current_entity_pos: Vector2 =  ent.global_position
		ent.apply_force(force, Vector2(0, 0))
	
## 向外同步掉落物位置	
func _sync_drop_item_position() -> void:
	for uid in entity_map:
		var entity = entity_map[uid]
		if not entity.is_inside_tree():
			DebugSystem.console_warn_log("掉落桥", "uid=%d 节点已经不在场景树" % uid)
			entity_map.erase(uid)
			continue
		emit_signal("drop_position_updated", uid, entity.global_position, entity.linear_velocity)
