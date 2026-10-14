extends RefCounted

## 实体基类
class_name EntityBase

# 全局唯一uid，由EntityStorage分配
var uid: int
var is_destroyed: bool = false
# 实体类型标识，用来桥接层判断要生成哪种视图节点
enum EntityType {
	PLAYER,
	DROP_ITEM,
	MONSTER
}
var entity_type: EntityType

func _init(p_uid:int):
	uid = p_uid
