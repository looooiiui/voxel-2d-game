extends Control
## 背包渲染，提供完整的背包渲染
class_name UiInventory

## 常量
const DEFAULT_SINGLE_SLOT_GAP_X: int = 10
const DEFAULT_SINGLE_SLOT_GAP_Y: int = 10
const DEFAULT_SINGLE_SLOT_SIZE_X: int = 40
const DEFAULT_SINGLE_SLOT_SIZE_Y: int = 40
## 背包自动排版节点以及各类外部节点
@export var grid_back_pack_container: GridContainer
@export var background_panel: Panel
@export var single_slot: PackedScene

## 内置变量
var BackPackSize: Vector2i = Vector2i(1, 1)
var single_slot_gap_x: int = DEFAULT_SINGLE_SLOT_GAP_X
var single_slot_gap_y: int = DEFAULT_SINGLE_SLOT_GAP_Y
var single_slot_size_x: int = DEFAULT_SINGLE_SLOT_SIZE_X
var single_slot_size_y: int = DEFAULT_SINGLE_SLOT_SIZE_Y

var slots_dict: Dictionary = {}

func _init(
	init_size: Vector2i = Vector2i(8, 3),
	slot_gap_x: int = DEFAULT_SINGLE_SLOT_GAP_X,
	slot_gap_y: int = DEFAULT_SINGLE_SLOT_GAP_Y,
) -> void:
	BackPackSize = init_size
	single_slot_gap_x = slot_gap_x
	single_slot_gap_y = slot_gap_y

func setup(
	init_size: Vector2i = Vector2i(8, 3),
	slot_gap_x: int = DEFAULT_SINGLE_SLOT_GAP_X,
	slot_gap_y: int = DEFAULT_SINGLE_SLOT_GAP_Y,
) -> void:
	BackPackSize = init_size
	single_slot_gap_x = slot_gap_x
	single_slot_gap_y = slot_gap_y
	_render_back_pack()

## 渲染背包
func _render_back_pack() -> void:
	# 检查尺寸是否在合理范围
	if BackPackSize.x <=0 or BackPackSize.y <=0:
		DebugSystem.console_warn_log("物品栏UI", "物品栏行列不能小于等于0")
		return
	back_pack_clear()
	DebugSystem.console_common_log("物品栏UI", "物品栏UI渲染")
	# 背景板尺寸计算
	var grid_inner_w = BackPackSize.x * single_slot_size_x + (BackPackSize.x - 1) * single_slot_gap_x
	var grid_inner_h = BackPackSize.y * single_slot_size_y + (BackPackSize.y - 1) * single_slot_gap_y
	var bg_total_w = grid_inner_w + single_slot_gap_x * 2
	var bg_total_h = grid_inner_h + single_slot_gap_y * 2
	background_panel.custom_minimum_size = Vector2i(bg_total_w, bg_total_h)
	# 贴图部分单独处理，不再用expand_margin乱算
	# 背景板设置
	var style_box = StyleBoxTexture.new()
	style_box.texture = CanvasTexture.new()
	# style_box.texture = preload("res://xxx.png") # 后续替换成背包底板贴图
	background_panel.add_theme_stylebox_override("panel", style_box)

	# ========= GridContainer核心配置 =========
	grid_back_pack_container.position = Vector2(single_slot_gap_x, single_slot_gap_y)
	grid_back_pack_container.columns = BackPackSize.x
	# 设置格子间隙（容器自带，代替手动算gap）注意 gridContain会自动算入宽度
	grid_back_pack_container.add_theme_constant_override("h_separation", single_slot_gap_x)
	grid_back_pack_container.add_theme_constant_override("v_separation", single_slot_gap_y)

	# 循环创建格子，【不再手动计算坐标】
	for row in range(BackPackSize.y):
		for column in range(BackPackSize.x):
			var new_slot = single_slot.instantiate()
			var new_slot_script = new_slot as UiSingleSlot
			# 单个Slot设置最小尺寸，GridContainer会尊重这个大小
			new_slot_script.setup(Vector2i(single_slot_size_x, single_slot_size_y))
			slots_dict[Vector2i(column, row)] = new_slot
			grid_back_pack_container.add_child(new_slot)

	# UiInventory.gd，_render_back_pack函数最后
	# bg_total_w、bg_total_h就是之前算好的背包底板总宽高
	custom_minimum_size = Vector2i(bg_total_w, bg_total_h)
	# DebugSystem.console_common_log("物品栏UI", "当前物品栏格子映射表: %s" % slots_dict)
	
## 增量更新单个格子（ 物品数据变更只调用这个，不重建背包）
func set_slot_item(slot_pos: Vector2i, item_name: String, item_count: int) -> void:
	if not slots_dict.has(slot_pos):
		DebugSystem.console_warn_log("物品栏UI", "不存在该坐标格子 %s" % slot_pos)
		return
	var target_slot: UiSingleSlot = slots_dict[slot_pos]
	target_slot.change_current_render_item(item_name, item_count)

## 清空全部格子数据（不销毁节点，只清空渲染内容）
func clear_all_slot_items() -> void:
	for slot in slots_dict.values():
		slot.change_current_render_item("", 0)

## 清除背包
func back_pack_clear() -> void:
	DebugSystem.console_common_log("物品栏UI", "清除物品栏所有格子节点")
	for slot in slots_dict.values():
		slot.queue_free()
	slots_dict.clear()
	
## 根据玩家数据+InventoryType，刷新当前UiInventory的全部UI格子
## 不持有PlayerData长期引用，仅读取一次数据用于全量刷新
func setup_by_player_data(player_data:PlayerData, inv_type:InventoryBase.InventoryType) -> void:
	var target_inv:InventoryBase
	match inv_type:
		InventoryBase.InventoryType.BACKPACK:
			target_inv = player_data.get_player_back_pack()
		InventoryBase.InventoryType.QUICK_BAR:
			target_inv = player_data.get_player_inventory_quick_bar()
		_:
			DebugSystem.console_warn_log("物品栏UI", "不支持的物品栏类型 %s" % str(inv_type))
			return
	
	# 使用目标物品栏尺寸重建UI容器
	setup(target_inv.inventory_size)
	
	# 遍历槽位，全量填充UI
	var size_x = target_inv.inventory_size.x
	var size_y = target_inv.inventory_size.y
	for row in range(size_y):
		for col in range(size_x):
			var grid_pos = Vector2i(col, row)
			var slot_data = target_inv.get_slot_by_grid(col, row)
			var item = slot_data.get_item()
			var item_name:String
			var item_num:int
			if item == null:
				item_name = ""
				item_num = 0
			else:
				item_name = item.get_item_instance().get_item_name()
				item_num = item.get_current_stack_num()
			set_slot_item(grid_pos, item_name, item_num)
