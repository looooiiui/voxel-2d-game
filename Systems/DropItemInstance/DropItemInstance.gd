extends RefCounted

## 掉落物【数据实例】，只保存状态，无tick逻辑，业务交给DropManager
class_name DropItemInstance
# 唯一编号，实例构造时分配
var uid: int
var item: Item
var world_pos: Vector2
var velocity: Vector2 = Vector2.ZERO
var spawn_time: float # 生成时记录全局时间戳，过期判断交给管理器
var is_absorbing: bool = false

func _init(new_uid:int, new_item:Item, start_pos:Vector2, current_world_time:float):
	uid = new_uid
	item = new_item
	world_pos = start_pos
	spawn_time = current_world_time
