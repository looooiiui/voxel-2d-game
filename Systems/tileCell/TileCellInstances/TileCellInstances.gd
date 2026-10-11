extends RefCounted

## 存 TileCellIns的映射表
class_name TileCellInstances

## 映射 name -> TileCellInstance[ attributeId -> attribute ]
static var OriginalInstancesType: Dictionary = {}

## 加载映射表
static func load_mapping_instance() -> bool:
	# 从指定路径打开映射表
	var file_path: String = ResourcePath.tile_ceil_instances_path
	var mapping_file = FileAccess.open(file_path, FileAccess.READ)
	if mapping_file == null:
		DebugSystem.console_error_log("瓦片实例映射表", "映射文件打不开，路径：%s" % file_path)
		return false
	
	DebugSystem.console_common_log("瓦片实例映射表", "打开映射文件，路径：%s" % file_path)
	# 读取指定数据
	var text = mapping_file.get_as_text()
	mapping_file.close()
	var parse_result = JSON.parse_string(text)
	if parse_result == null:
		DebugSystem.console_error_log("瓦片映射表", "JSON解析错误，文本格式非法")
		return false
		
	# 获取格式数据并转换
	var input_dict: Dictionary = convert_block_array_to_dict(parse_result)
	DebugSystem.console_common_log("瓦片映射表", "获得转换映射: %s" % input_dict)
	OriginalInstancesType = input_dict.duplicate()
	return true
	
## 【独立转换函数】转换对应名字属性，载入实例方块，输出 name -> tileCellInstance 字典
static func convert_block_array_to_dict(input_array:Array) -> Dictionary:
	var result_dict: Dictionary = {}
	
	for block_def in input_array:
		if not block_def is Dictionary:
			DebugSystem.console_warn_log("方块实例表", "跳过无效方块条目，不是字典类型")
			continue
		
		## 查找属性注册名字
		var block_name:String = block_def.get("name", "")
		if block_name.is_empty():
			DebugSystem.console_warn_log("方块实例表", "方块name为空，跳过")
			continue
		
		if not TileCellAttributes.OriginalBlockType.has(block_def["attribute"]):
			DebugSystem.console_warn_log("方块实例表", "属性表中不存在属性: %s" % block_def["attribute"])
			continue
		
		var attr = TileCellInstance.new(
			block_name,
			TileCellAttributes.OriginalBlockType[block_def["attribute"]]
		)
		
		result_dict[block_name] = attr
	return result_dict
