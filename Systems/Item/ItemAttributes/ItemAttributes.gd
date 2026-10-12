extends RefCounted
## 存原版所有方块物品属性模板
class_name ItemAttributes
## 映射表 name -> ItemAttribute（BlockItemAttribute 这类模板）
static var OriginalAttrType: Dictionary = {}
## 加载映射表
static func load_mapping_attributes() -> bool:
	# 从指定路径打开映射表，在ResourcePath里面新增item_attributes_path
	var file_path: String = ResourcePath.item_attributes_path
	var mapping_file = FileAccess.open(file_path, FileAccess.READ)
	if mapping_file == null:
		DebugSystem.console_error_log("物品属性映射表", "映射文件打不开，路径：%s" % file_path)
		return false
	
	DebugSystem.console_common_log("物品属性映射表", "打开映射文件，路径：%s" % file_path)
	# 读取指定数据
	var text = mapping_file.get_as_text()
	mapping_file.close()
	var parse_result = JSON.parse_string(text)
	if parse_result == null:
		DebugSystem.console_error_log("物品属性映射表", "JSON解析错误，文本格式非法")
		return false
		
	# 获取格式数据并转换
	var input_dict: Dictionary = convert_item_array_to_dict(parse_result)
	DebugSystem.console_common_log("物品属性映射表", "获得转换映射: %s" % input_dict)
	OriginalAttrType = input_dict.duplicate()
	return true
	
## 【独立转换函数】输入物品属性定义数组，输出 name -> ItemAttribute 字典
static func convert_item_array_to_dict(input_array:Array) -> Dictionary:
	var result_dict: Dictionary = {}
	
	for item_def in input_array:
		if not item_def is Dictionary:
			DebugSystem.console_warn_log("物品属性表", "跳过无效物品条目，不是字典类型")
			continue
		
		## 注册表查询用的name（字符串key，和方块属性表保持一致）
		var attr_name:String = item_def.get("name", "")
		if attr_name.is_empty():
			DebugSystem.console_warn_log("物品属性表", "物品name为空，跳过")
			continue
		
		# 读取持久int id，无则传-1自动分配
		var persistent_id:int = item_def.get("id", -1)
		var max_stack:int = item_def.get("max_stack", 64)
		var raw_type:String = item_def.get("item_type", "BLOCK")
		
		var attr:ItemAttribute = null
		match raw_type:
			"BLOCK":
				attr = BlockItemAttribute.new(persistent_id, max_stack)
				attr.type = ItemAttribute.ItemType.BLOCK
			# 后续TOOL在这里扩展
			# "TOOL":
			# 	attr = ToolItemAttribute.new(persistent_id, max_stack)
			# 	attr.type = ItemAttribute.ItemType.TOOL
			_:
				DebugSystem.console_warn_log("物品属性表", "未知物品类型 %s，跳过" % raw_type)
				continue
		
		result_dict[attr_name] = attr
	return result_dict
