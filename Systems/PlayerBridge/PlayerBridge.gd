extends Node

## 玩家实体中转站
class_name PlayerBridge

## 玩家实体场景
@export var player_entity_scene: PackedScene

## 玩家映射表: uid -> 玩家实体
var _entity_map: Dictionary = {}

## 生成玩家实体
func on_add_player(new_player_data: PlayerData) -> void:
	# 检查玩家数据是否不存在
	if new_player_data == null:
		DebugSystem.console_error_log("玩家桥", "传入的玩家数据为空值，拒绝创建")
		return
	var new_player_entity = player_entity_scene.instantiate()
	var player_entity_script = new_player_entity as PlayerEntity
	DebugSystem.console_common_log("玩家桥", "创建玩家实体: uid: %s, 实体: %s" % [new_player_data.get_uid(), new_player_entity])
	player_entity_script.setup(new_player_data)
	# 加入玩家映射表
	_entity_map[new_player_data.get_uid()] = new_player_entity
	add_child(new_player_entity)

## 清除玩家
func on_drop_removed(uid:int):
	if _entity_map.has(uid):
		var ent = _entity_map[uid]
		ent.queue_free()
		_entity_map.erase(uid)
		DebugSystem.console_common_log("玩家桥", "清除玩家 uid= %d" % uid)

## 获得玩家映射字典
func get_player_uid_entity_map() -> Dictionary:
	return _entity_map
