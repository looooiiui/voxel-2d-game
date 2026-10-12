extends RefCounted
## 存 ItemInstance 的映射表
class_name ItemInstances
## 映射 name -> ItemInstance（BlockItemInstance / ToolItemInstance）
static var OriginalInstancesType: Dictionary = {}
## 加载映射表
static func load_mapping_instance() -> bool:
	# 从指定路径打开映射表
	var file_path: String = ResourcePath.item_instances_path
	var mapping_file = FileAccess.open(file_path, FileAccess.READ)
	if mapping_file == null:
		DebugSystem.console_error_log("物品实例映射表", "映射文件打不开，路径：%s" % file_path)
		return false
	
	DebugSystem.console_common_log("物品实例映射表", "打开映射文件，路径：%s" % file_path)
	# 读取指定数据
	var text = mapping_file.get_as_text()
	mapping_file.close()
	var parse_result = JSON.parse_string(text)
	if parse_result == null:
		DebugSystem.console_error_log("物品实例映射表", "JSON解析错误，文本格式非法")
		return false
		
	# 获取格式数据并转换
	var input_dict: Dictionary = convert_item_array_to_dict(parse_result)
	DebugSystem.console_common_log("物品实例映射表", "获得转换映射: %s" % input_dict)
	OriginalInstancesType = input_dict.duplicate()
	return true
	
## 【独立转换函数】转换对应名字属性，载入物品实例，输出 name -> ItemInstance 字典
static func convert_item_array_to_dict(input_array:Array) -> Dictionary:
	var result_dict: Dictionary = {}
	
	for item_def in input_array:
		if not item_def is Dictionary:
			DebugSystem.console_warn_log("物品实例表", "跳过无效物品条目，不是字典类型")
			continue
		
		## 查找物品实例注册名字
		var item_name:String = item_def.get("name", "")
		if item_name.is_empty():
			DebugSystem.console_warn_log("物品实例表", "物品name为空，跳过")
			continue
		
		# 检查属性模板是否在物品属性注册表存在
		var attr_ref_name:String = item_def.get("attribute", "")
		if not ItemAttributes.OriginalAttrType.has(attr_ref_name):
			DebugSystem.console_warn_log("物品实例表", "属性表中不存在属性: %s" % attr_ref_name)
			continue
		
		var attr_template = ItemAttributes.OriginalAttrType[attr_ref_name]
		var item_ins:ItemInstance = null

		match attr_template.type:
			ItemAttribute.ItemType.BLOCK:
				var block_ins = BlockItemInstance.new(item_name, attr_template)
				# 方块物品实例专属：放置对应的方块实例name
				block_ins.place_tile_name = item_def.get("place_tile_name", "")
				item_ins = block_ins
			# 后续TOOL在这里扩展
			# ItemAttribute.ItemType.TOOL:
			# 	var tool_ins = ToolItemInstance.new(item_name, attr_template)
			# 	item_ins = tool_ins
			_:
				DebugSystem.console_warn_log("物品实例表", "不支持的物品类型，name:%s" % item_name)
				continue
		
		result_dict[item_name] = item_ins
	return result_dict
