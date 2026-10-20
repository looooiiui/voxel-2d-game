extends Control
## 单个物品栏格子，提供渲染单个格子
class_name UiSingleSlot

## 常量
const ITEM_ENTITY_SCALE: float = 1.3 
const DEFAULT_SLOT_SIZE: Vector2 = Vector2(40, 40)
## 背景贴图等资源
@export var background_panel: Panel
@export var itemEntity_panel: Panel
@export var item_num_label: Label

## 内置参量
var slot_size: Vector2 = DEFAULT_SLOT_SIZE
var render_item_name: String = ""
var render_num: int = 0

## 贴图缓存，避免重复加载
static var texture_cache: Dictionary = {}
## 空样式，全局复用
static var empty_style: StyleBoxTexture = StyleBoxTexture.new()

func _init() -> void:
	# 只设默认值，不做业务初始化
	slot_size = DEFAULT_SLOT_SIZE
	custom_minimum_size = slot_size

## 默认出现即渲染一次
func _ready() -> void:
	render_slot()

## 渲染一次
func render_slot() -> void:
	background_panel.size = slot_size
	itemEntity_panel.size = slot_size / ITEM_ENTITY_SCALE
	# 物品图标居中
	var center_pos = (slot_size - itemEntity_panel.size) / 2.0
	itemEntity_panel.position = center_pos
	# 右下角，预留一点边距
	item_num_label.position = Vector2(slot_size.x - item_num_label.size.x, slot_size.y - item_num_label.size.y)
	# 保证容器布局读取到正确最小尺寸
	custom_minimum_size = slot_size

## 外部更改参数
func setup(new_size: Vector2 = DEFAULT_SLOT_SIZE) -> void:
	slot_size = new_size
	custom_minimum_size = new_size
	render_slot()

## 外部接口：切换物品
func change_current_render_item(item_name: String, new_item_num):
	render_item_name = item_name
	render_num = new_item_num
	_refresh_item_texture()

## 修改当前贴图
func _refresh_item_texture() -> void:
	if render_item_name == "":
		_clear_render_item()
		return
	
	# 兜底告警，不修改上层数据
	if render_num <= 0:
		DebugSystem.console_warn_log("物品栏(Slot渲染)", "脏数据：物品名存在但数量为0，name=%s" % render_item_name)
	
	item_num_label.text = String.num_int64(render_num)
	# 优先读取缓存
	if texture_cache.has(render_item_name):
		var tex = texture_cache[render_item_name]
		UiUtil.set_panel_texture(itemEntity_panel, tex)
		return

	var texture_path = "%s%s.png" % [ResourcePath.item_texture_path, render_item_name]
	var item_texture: Texture2D = load(texture_path)
	if item_texture == null:
		DebugSystem.console_warn_log("物品栏", "找不到贴图资源：%s" % texture_path)
		_clear_render_item()
		return
	
	texture_cache[render_item_name] = item_texture
	UiUtil.set_panel_texture(itemEntity_panel, item_texture)


## 清除贴图（复用静态空样式，不重复new）
func _clear_render_item() -> void:
	itemEntity_panel.add_theme_stylebox_override("panel", empty_style)
	item_num_label.text = ""

## 设置位置（如果你继续手动摆放Slot才用；GridContainer自动布局时这个函数不用）
func set_new_position(new_position: Vector2) -> void:
	position = new_position
