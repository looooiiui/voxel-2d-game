extends RefCounted

## 实体存储器，仅供查询，存储所有实体
class_name EntityStorage

var _players : Dictionary = {}
var _drops   : Dictionary = {}
var next_uid:int = 1 # 这个属于当前存档世界的uid，跟着存档保存/加载

signal entity_spawned(uid:int, entity:EntityBase)
signal entity_despawned(uid:int, entity:EntityBase)

## 添加实体（外部调用）
func add_entity(entity:EntityBase) -> void:
	DebugSystem.console_common_log("世界[实体管理查询器]", "添加实体[uid]: %s, 类型: %s" % [entity.get_uid(), entity.entity_type])
	match entity.entity_type:
		EntityBase.EntityType.PLAYER:
			_players[entity.get_uid()] = entity
			DebugSystem.console_common_log("世界[实体管理查询器]", "当前玩家实体表: %s" % _players)
		EntityBase.EntityType.DROP_ITEM:
			_drops[entity.get_uid()] = entity
			DebugSystem.console_common_log("世界[实体管理查询器]", "当前物品实体表: %s" % _drops)
	entity_spawned.emit(entity.get_uid(), entity)
	
## 分配并获取下一个可用UID（新建实体调用）
func allocate_uid() -> int:
	var ret = next_uid
	next_uid += 1
	return ret

## 获得所有玩家实体(返回实体表)
func get_all_players() -> Dictionary:
	return _players

## 查询接口
## 获得玩家实体
func get_player(uid:int) -> PlayerData:
	return _players.get(uid)

## 获得掉落物实体
func get_drop(uid:int) -> DropItemData:
	return _drops.get(uid)
	
## 内部直接查找玩家存在
func has_player(uid:int) -> bool:
	return get_all_players().has(uid)

## 移除实体（外部业务管理器调用，只读存储，被动执行删除）
func remove_entity(uid:int, type:EntityBase.EntityType) -> bool:
	var ent:EntityBase = null
	DebugSystem.console_common_log("世界[实体管理查询器]", "移除实体[uid]: %s, 类型: %s" % [uid, type])
	match type:
		EntityBase.EntityType.PLAYER:
			ent = _players.get(uid)
			if ent == null:
				return false
			_players.erase(uid)
		EntityBase.EntityType.DROP_ITEM:
			ent = _drops.get(uid)
			if ent == null:
				return false
			_drops.erase(uid)
	
	if ent.is_destroyed:
		return false
	ent.is_destroyed = true
	entity_despawned.emit(uid, ent)
	return true
