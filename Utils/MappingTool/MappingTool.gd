extends RefCounted
class_name MappingTool

## 方块实例 → 生成对应的物品实例
static func tile_instance_to_item(tile_ins: TileCellInstance) -> Item:
	DebugSystem.console_common_log("映射工具", "收到映射[方块 -> 物品]: 映射原方块实例: %s" % tile_ins )
	if tile_ins == null:
		return null
	# 空气不生成掉落
	if tile_ins.get_tile_drop_item() == null:
		return null
	# 根据掉落物名字(String)查询对应物品 ItemInstance
	var item_template: ItemInstance = ItemInstances.OriginalInstancesType.get(tile_ins.get_tile_drop_item())
	if item_template == null:
		DebugSystem.console_common_log("映射工具", "找不到物品模板，name: %s" % tile_ins.name)
		return null
	# 直接构造Item实例返回
	return Item.new(item_template)
