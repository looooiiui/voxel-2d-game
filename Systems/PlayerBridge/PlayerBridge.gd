extends Node

## 玩家实体中转站
class_name PlayerBridge

## 玩家实体场景
@export var player_entity_scene: PackedScene

## 玩家映射表: uid -> 玩家实体
var entity_map: Dictionary = {}

## 生成玩家实体
func on_add_player(new_player_data: PlayerData) -> void:
	var new_player_entity = player_entity_scene.instantiate()
	var player_entity_script = new_player_entity as PlayerEntity
	DebugSystem.console_common_log("玩家桥", "创建玩家实体: uid: %s, 实体: %s" % [new_player_data.get_uid(), new_player_entity])
	player_entity_script.setup(new_player_data)
	# 加入玩家映射表
	entity_map[new_player_data.get_uid()] = new_player_entity
	add_child(new_player_entity)

## 清除玩家
func on_drop_removed(uid:int):
	if entity_map.has(uid):
		var ent = entity_map[uid]
		ent.queue_free()
		entity_map.erase(uid)
		DebugSystem.console_common_log("玩家桥", "清除玩家 uid= %d" % uid)
