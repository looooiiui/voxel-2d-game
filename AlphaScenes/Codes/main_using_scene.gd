extends Node2D

# 主节点
@export var player: CharacterBody2D
@export var tile_map_layer: TileMapLayer
@export var player_input_control: InputController
@export var camera: Camera2D
## 核心类(渲染器，世界)
var render_bridge: RenderBridge
var world: World
var player_chunk_pos:Vector2i
var render_distance: int = 1   # 1 = 3x3 区域，2 = 5x5 区域
# 玩家所在区块
var ready_rander: bool = true

# 主节点变量
var chunk_prune_timer:float = 0.0
const PRUNE_INTERVAL:float = 2 # 2秒扫描一次区块，可调整

# 保存当前已经绘制在TileMap上的区块
var rendered_chunks:Dictionary = {}

## 启动检查
func _ready() -> void:
	# 加载资源
	# 先加载属性再加载实例最后图集贴图
	TileCellAttributes.load_mapping_attributes()
	TileCellInstances.load_mapping_instance()
	TileSetBuilder.build_tileset()
	# 加载图集
	tile_map_layer.tile_set = TileSetBuilder.built_tileset
	# 创建世界
	render_bridge = RenderBridge.new(tile_map_layer)
	world = World.new(54213)
	DebugSystem.console_common_log("核心节点", "创建世界: %s" % world)

	# 注入节点给玩家控制
	player_input_control.camera = camera
	
	# 测试所需核心是否加载
	_debug_start()
	render_bridge.world = world
	if ready_rander:
		_connect_sign()
		_render_around_player()

## 连接信号
func _connect_sign() -> void:
	# 方块破坏
	player_input_control.block_destroy_request.connect(world.try_destroy_tile_dir)
	# 方块放置
	player_input_control.block_place_request.connect(world.try_place_tile)	
	
	# 信号转发(更改通知渲染)
	world.tile_cell_updated.connect(render_bridge.refresh_single_tile)	
	
func _physics_process(delta: float) -> void:
	if !ready_rander:
		return
	_rander_map()
	
	# 定期清理世界数据
	chunk_prune_timer += delta
	if chunk_prune_timer >= PRUNE_INTERVAL:
		world.prune_out_of_range_chunks()
		chunk_prune_timer = 0.0
		
## 获取玩家坐标
func get_player_global_tile_pos() -> Vector2i:
	return player.get_player_grid_pos()
	
func _rander_map() -> void:
	# 1. 拿到玩家所在全局方块坐标
	var player_global_tile:Vector2i = get_player_global_tile_pos()
	var cx:int = int( floor( float(player_global_tile.x) / Chunk.CHUNK_SIZE_X ) )
	var cy:int = int( floor( float(player_global_tile.y) / Chunk.CHUNK_SIZE_Y ) )
	var new_chunk_pos = Vector2i(cx, cy)

	if new_chunk_pos != player_chunk_pos:
		player_chunk_pos = new_chunk_pos
		_render_around_player()
		# 玩家跨区块，立刻执行一次区块清理
		world.prune_out_of_range_chunks()

## 渲染玩家周围的方块(范围渲染)
func _render_around_player():
	var target_chunks:Dictionary = {}
	# 1. 先算出这一帧需要的所有目标区块
	for dx in range(-render_distance, render_distance + 1):
		for dy in range(-render_distance, render_distance + 1):
			var chunk_pos = Vector2i(
				player_chunk_pos.x + dx,
				player_chunk_pos.y + dy
			)
			target_chunks[chunk_pos] = true
	
	# 2. 清除【旧有，但不在新列表】的区块
	for old_chunk in rendered_chunks:
		if !target_chunks.has(old_chunk):
			render_bridge.clear_chunk_render(old_chunk)
			rendered_chunks.erase(old_chunk)
	
	# 3. 绘制【新列表里面还没渲染的区块】
	for new_chunk in target_chunks:
		if !rendered_chunks.has(new_chunk):
			render_bridge.render_chunk(new_chunk)
			rendered_chunks[new_chunk] = true
	
	## 维护区块输出
	## DebugSystem.console_common_log("测试世界", "当前维护区块: %s" % rendered_chunks)

## 检查各项参数
func _debug_start() -> void:
	# 检查渲染桥
	if render_bridge != null:
		DebugSystem.console_common_log("核心节点", "渲染搭桥存在")
	else:
		DebugSystem.console_error_log("核心节点", "渲染搭桥不存在")
		ready_rander = false
	if world != null:
		DebugSystem.console_common_log("核心节点", "世界本体存在")
	else:
		DebugSystem.console_error_log("核心节点", "世界本体不存在")
		ready_rander = false
	if player != null:
		DebugSystem.console_common_log("核心节点", "玩家存在")
	else:
		DebugSystem.console_error_log("核心节点", "玩家不存在")
		ready_rander = false
	## 显示渲染状态
	DebugSystem.console_common_log("核心节点", "渲染状态: %s" % ready_rander)
		
		
