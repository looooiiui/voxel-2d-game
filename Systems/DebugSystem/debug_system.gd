extends RefCounted
class_name DebugSystem
## 调试开关
static var output_common: bool = true
static var output_error: bool = true
static var output_warn: bool = true
static var output_debug: bool = true

## 普通日志
static func console_common_log(type: String, info: String) -> void:
	if not output_common:
		return
	var output_info: String = "[%s] %s" % [type, info]
	print(output_info)

## 警告日志
static func console_warn_log(type: String, info: String) -> void:
	if not output_warn:
		return
	var output_info: String = "[WARN] [%s] %s" % [type, info]
	push_warning(output_info)
	print(output_info)

## 错误日志
static func console_error_log(type: String, info: String) -> void:
	if not output_error:
		return
	var output_info: String = "[ERROR] [%s] %s" % [type, info]
	push_error(output_info)
	print(output_info)
	
## 调试日志
static func console_debug_log(type: String, info: String) -> void:
	if not output_debug:
		return
	var output_info: String = "[DEBUG] [%s] %s" % [type, info]
	print(output_info)
