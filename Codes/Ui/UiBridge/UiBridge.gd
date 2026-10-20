extends CanvasLayer

## Ui桥，负责渲染对应玩家Ui
## 同时负责所有子 ui 的信号传输，统一从 Ui 桥发出数据更新请求与收到渲染请求
## 所有 ui 仅负责渲染和反馈玩家操作，实际渲染由数据决定
class_name UiBridge

## 各个 Ui 组件
@export var ui_inventory: PackedScene
@export var ui_control: Control
@export var ui_vbox_container: VBoxContainer
## 存储对应实例化节点的核心代码
var back_pack_script: UiInventory
var inventory_quick_bar_script: UiInventory

## ui 实例存储
var ui_back_pack_instance
var ui_inventory_quick_bar_instance

## 对应 ui 所处位置
var ui_position: Vector2 = Vector2(10, 10)

## 初始化(场景内初始化)
func _ready() -> void:
	ui_vbox_container.position = ui_position
	# 背包和快捷栏之间的垂直间隔
	ui_vbox_container.add_theme_constant_override("separation", 10)
	_back_pack_initialize()
	_inventory_quick_bar_initialize()
	
## 背包初始化
func _back_pack_initialize() -> void:
	ui_back_pack_instance = ui_inventory.instantiate()
	back_pack_script = ui_back_pack_instance as UiInventory
	back_pack_script.setup(Vector2i(8, 3))
	DebugSystem.console_common_log("Ui桥", "创建背包Ui: %s" % ui_back_pack_instance)
	ui_back_pack_instance.visible = true
	ui_vbox_container.add_child(ui_back_pack_instance)
	
## 快捷栏初始化
func _inventory_quick_bar_initialize() -> void:
	ui_inventory_quick_bar_instance = ui_inventory.instantiate()
	inventory_quick_bar_script = ui_inventory_quick_bar_instance as UiInventory
	inventory_quick_bar_script.setup(Vector2i(8, 1))
	DebugSystem.console_common_log("Ui桥", "创建快捷栏Ui: %s" % ui_inventory_quick_bar_instance)
	ui_inventory_quick_bar_instance.visible = true
	ui_vbox_container.add_child(ui_inventory_quick_bar_instance)	

## 清理所有ui
func destroy_all_inventory_ui():
	if ui_back_pack_instance != null:
		ui_back_pack_instance.queue_free()
		ui_back_pack_instance = null
		back_pack_script = null
	
	if ui_inventory_quick_bar_instance != null:
		ui_inventory_quick_bar_instance.queue_free()
		ui_inventory_quick_bar_instance = null
		inventory_quick_bar_script = null

## 更新主背包单个格子
func update_backpack_slot(pos:Vector2i, item_name:String, count:int) -> void:
	if back_pack_script == null:
		DebugSystem.console_warn_log("Ui桥", "背包实例为空，无法更新")
		return
	back_pack_script.set_slot_item(pos, item_name, count)

## 更新快捷栏单个格子
func update_hotbar_slot(pos:Vector2i, item_name:String, count:int) -> void:
	if inventory_quick_bar_script == null:
		DebugSystem.console_warn_log("Ui桥", "快捷栏实例为空，无法更新")
		return
	inventory_quick_bar_script.set_slot_item(pos, item_name, count)
