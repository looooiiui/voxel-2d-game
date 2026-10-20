extends Camera2D

## 全局相机
class_name GlobalCamera

@export var followCase: Node
@export var lerp_level: float = 1.5

func _ready() -> void:
	## 相机跟随
	position_smoothing_enabled = true
	position_smoothing_speed = lerp_level
	if followCase == null and not is_instance_valid(followCase):
		DebugSystem.console_common_log("相机", "初始化跟随对象为空")
	else:
		DebugSystem.console_common_log("相机", "当前跟随对象: %s" % followCase)

func _physics_process(delta: float) -> void:
	_follow_case()

## 跟随目标
func _follow_case() -> void:
	## 检查对象
	if followCase != null and is_instance_valid(followCase):
		global_position = followCase.global_position
		## 整数对齐相机防抖动
		global_position = global_position.round()
	else:
		DebugSystem.console_error_log("相机", "设置跟随对象不合法或为空")

## 更改跟随对象
func set_follow_case(case: Node) -> void:
	if case != null:
		followCase = case
