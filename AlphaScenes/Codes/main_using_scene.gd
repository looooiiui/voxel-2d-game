extends Node2D

# 主节点
@export var tile_map_layer: TileMapLayer
@export var player_input_control: InputController
@export var drop_bridge: DropBridge
@export var player_bridge: PlayerBridge
@export var ui_bridge: UiBridge
@export var camera:GlobalCamera
## 核心类(渲染器，世界)
var render_bridge: RenderBridge
var world: World
var player_chunk_pos:Vector2i
var render_distance: int = 1   # 1 = 3x3 区域，2 = 5x5 区域
## 玩家所在区块
var is_render_ready: bool = true
## 保存当前已经绘制在TileMap上的区块
var rendered_chunks:Dictionary = {}
## 存储上一个绑定的玩家数据实例（用于安全解绑信号）
var bound_player_data:PlayerData = null
## 存储上一个主玩家uid（仅日志/调试）
var last_control_uid: int = -1

## 启动检查
func _ready() -> void:
	# 加载资源ca
	# 先加载属性再加载实例最后图集贴图
	_tile_cell_load()
	_item_load()
	TileSetBuilder.build_tileset()
	# 加载图集
	tile_map_layer.tile_set = TileSetBuilder.built_tileset
	# 创建世界
	render_bridge = RenderBridge.new(tile_map_layer)
	_load_world()
	DebugSystem.console_common_log("核心节点", "创建世界: %s" % world)
	# 注入节点给玩家控制检测(玩家并没有创建)
	player_input_control.camera = camera
	# 测试所需核心是否加载
	_debug_start()
	render_bridge.world = world
	if is_render_ready:
		_connect_signals()
		_render_map()
		_set_world()	
		
## 瓦片加载
func _tile_cell_load() -> void:
	TileCellAttribute.reset_counter()
	TileCellAttributes.load_mapping_attributes()
	TileCellInstances.load_mapping_instance()
	
## 物品加载
func _item_load() -> void:
	ItemAttribute.reset_counter()
	ItemAttributes.load_mapping_attributes()
	ItemInstances.load_mapping_instance()

## 创建并加入玩家
func sync_player_entity(new_player_data: PlayerData) -> void:
	# 同步玩家实体与数据：PlayerEntity视图节点持有，DI本身不持有
	player_bridge.on_add_player(new_player_data)
	DebugSystem.console_common_log("核心节点", "向玩家桥发送玩家实体创建信息: %s" % [new_player_data])

## 世界加载
func _load_world() -> void:
	world = World.new(54213)

## 世界属性设置
func _set_world() -> void:
	world.set_gravity(980.665)
	world.spawn_new_player()
	
## Ui 加载(这里ui信号连接不放在 _connect_signals， 方便统一更改, 活信号)
func _set_ui() -> void:
	# 优先用缓存的实例引用解绑，不再通过uid去查找
	if bound_player_data != null:
		bound_player_data.inventory_change.disconnect(_inventory_change_transfer)
		DebugSystem.console_common_log("核心节点", "解绑旧玩家物品信号，uid=%s" % bound_player_data.get_uid())
		bound_player_data = null
	
	var temp_player_data: PlayerData = world.get_player_data_by_uid(world.get_control_player_uid())
	if temp_player_data == null:
		DebugSystem.console_warn_log("核心节点", "获取控制玩家数据失败，UI无法初始化")
		return
	
	bound_player_data = temp_player_data
	# 初始化UI全量加载背包数据
	ui_bridge.setup(temp_player_data)
	# 绑定新玩家物品变更信号
	temp_player_data.inventory_change.connect(_inventory_change_transfer)
	# 更新记录uid
	last_control_uid = temp_player_data.get_uid()
	
## 连接信号 (死信号，一般是固定管理器连接)
func _connect_signals() -> void:
	# 方块破坏
	player_input_control.block_destroy_request.connect(world.try_destroy_tile_dir)
	# 方块放置
	player_input_control.block_place_request.connect(world.try_place_tile)	
	# 信号转发(更改通知渲染)
	world.tile_cell_updated.connect(render_bridge.refresh_single_tile)
	world.gravity_updated.connect(_on_gravity_change)	
	# 连接掉落物信号
	world.drop_added.connect(drop_bridge.on_drop_added)
	world.drop_removed.connect(drop_bridge.on_drop_removed)
	world.drop_apply_force.connect(drop_bridge.on_drop_apply_force)
	drop_bridge.drop_position_updated.connect(world.receive_drop_updated_info)
	# 玩家创建信号
	world.control_player_uid_changed.connect(_on_control_player_uid_change)
	world.spawn_player_data.connect(sync_player_entity)
	
## 物理帧循环
func _physics_process(delta: float) -> void:
	# 向世界提供主循环
	world.tick_world(delta)
	
## 渲染帧循环
func _process(delta: float) -> void:
	if !is_render_ready:
		return
	_render_map()
	
## 多人完整区块渲染
func _render_map() -> void:
	# 从世界实体存储器拿到全部玩家数据
	var player_dict = world.get_player_entity_dict()
	var target_chunks:Dictionary = {}
	
	# 遍历所有玩家，各自生成周围区块，自动合并去重
	for uid in player_dict:
		var p_data:PlayerData = player_dict[uid]
		var tile_pos:Vector2i = p_data.get_player_grid_pos()
		var cx:int = int( floor( float(tile_pos.x) / Chunk.CHUNK_SIZE_X ) )
		var cy:int = int( floor( float(tile_pos.y) / Chunk.CHUNK_SIZE_Y ) )
		var chunk_center = Vector2i(cx, cy)
		
		# 当前玩家render_distance范围区块
		for dx in range(-render_distance, render_distance + 1):
			for dy in range(-render_distance, render_distance + 1):
				var c_pos = Vector2i(chunk_center.x + dx, chunk_center.y + dy)
				target_chunks[c_pos] = true # 字典key自动去重
	
	# 和上一帧渲染区块对比，加载/卸载，原有逻辑原样保留
	var need_refresh:bool = false
	# 判断集合是否变化
	if target_chunks.size() != rendered_chunks.size():
		need_refresh = true
	else:
		for old_c in rendered_chunks:
			if !target_chunks.has(old_c):
				need_refresh = true
				break
	
	if need_refresh:
		_render_around_player(target_chunks)

# 重载，接收合并后的目标区块字典
func _render_around_player(target_chunks:Dictionary):
	# 清除旧区块
	for old_chunk in rendered_chunks:
		if !target_chunks.has(old_chunk):
			render_bridge.clear_chunk_render(old_chunk)
			rendered_chunks.erase(old_chunk)
	# 新增区块
	for new_chunk in target_chunks:
		if !rendered_chunks.has(new_chunk):
			render_bridge.render_chunk(new_chunk)
			rendered_chunks[new_chunk] = true
	
	# 维护区块输出
	# DebugSystem.console_common_log("测试世界", "当前维护区块: %s" % rendered_chunks)

## 检查各项参数
func _debug_start() -> void:
	# 检查渲染桥
	if render_bridge != null:
		DebugSystem.console_common_log("核心节点", "渲染搭桥存在")
	else:
		DebugSystem.console_error_log("核心节点", "渲染搭桥不存在")
		is_render_ready = false
	if world != null:
		DebugSystem.console_common_log("核心节点", "世界本体存在")
	else:
		DebugSystem.console_error_log("核心节点", "世界本体不存在")
		is_render_ready = false
	## 显示渲染状态
	DebugSystem.console_common_log("核心节点", "渲染状态: %s" % is_render_ready)
		
## ========================= 核心 DI 容器全局信号 ======================
## 重力数据变更 → 调用引擎物理服务器
func _on_gravity_change(new_g:float):
	var world_2d = get_world_2d()
	if world_2d == null:
		DebugSystem.console_warn_log("核心节点: 重力", "无法获取2D世界空间")
		return
	var space_rid = world_2d.space
	PhysicsServer2D.area_set_param(space_rid, PhysicsServer2D.AREA_PARAM_GRAVITY, new_g)
	PhysicsServer2D.area_set_param(space_rid, PhysicsServer2D.AREA_PARAM_GRAVITY_VECTOR, Vector2(0, 1))
	DebugSystem.console_common_log("核心节点: 重力", "设置重力: %s" % new_g)

## 当前控制玩家发生变化
func _on_control_player_uid_change(new_uid: int) -> void:
	DebugSystem.console_common_log("核心节点", "当前控制玩家 uid 更改为: %s" % new_uid)
	var target_entity = player_bridge.get_player_uid_entity_map().get(new_uid)
	if target_entity != null:
		camera.set_follow_case(target_entity)
	# 这里注意新的值由 ui 设置赋予给当前存储的主玩家数据
	_set_ui()

## 物品栏(背包更改信号中转)
func _inventory_change_transfer(
	change_pos: Vector2i, 
	new_item_name: String, 
	new_item_num: int,
	inv_type: InventoryBase.InventoryType
) -> void:
	DebugSystem.console_common_log("核心节点", "执行物品栏数据与对应UI转发")
	## 物品栏传给ui渲染对应信息
	ui_bridge.update_inventory_slot(change_pos, new_item_name, new_item_num, inv_type)
	
	
	
	
