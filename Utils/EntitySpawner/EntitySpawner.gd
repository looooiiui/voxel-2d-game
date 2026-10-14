extends RefCounted

## 实体生成器，用于统一生成实体并分配uid
class_name EntitySpawner

# 生成玩家实体数据
static func spawn_player(new_uid: int, start_pos:Vector2 = Vector2(0, 0)) -> PlayerData:
	var entity = PlayerData.new(new_uid, start_pos)
	return entity

# 生成掉落物实体数据
static func spawn_drop_item(new_uid: int, item:Item, pos:Vector2, world_time:float) -> DropItemData:
	var entity = DropItemData.new(new_uid, item, pos, world_time)
	return entity
