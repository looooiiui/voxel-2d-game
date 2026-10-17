extends RefCounted
class_name RenderBridge

# 绑定场景中网格地图
var tile_map_layer: TileMapLayer
# 世界实例
var world: World = null

func _init(tile_map: TileMapLayer) -> void:
	tile_map_layer = tile_map

## 渲染单个区块：输入区块坐标Vector2i
func render_chunk(chunk_pos:Vector2i):
	# DebugSystem.console_common_log("渲染器", "渲染区块输入坐标(新渲染): %s" % chunk_pos)
	# 遍历区块内全部local坐标 x:0~31，y:0~255
	for local_x in range(Chunk.CHUNK_SIZE_X):
		for local_y in range(Chunk.CHUNK_SIZE_Y):
			var local_pos = Vector2i(local_x, local_y)
			# 转换成全局方块坐标
			var global_tile_x = chunk_pos.x * Chunk.CHUNK_SIZE_X + local_x
			var global_tile_pos = Vector2i(global_tile_x, local_y + chunk_pos.y * Chunk.CHUNK_SIZE_Y)
			# 读取方块数据(缺失方块直接删除)
			var cell: TileCell = world.get_tile(global_tile_pos)
			if cell == null:
				DebugSystem.console_warn_log("渲染桥", "区块方块获取失败，坐标: %s" % global_tile_pos)
				tile_map_layer.erase_cell(global_tile_pos)
				continue
			
			# 根据tile_type_id拿到瓦片编号
			var tile_array = TileSetBuilder.get_tile_draw_info(cell.get_cell_instance().name)
			var tileset_index: int = tile_array[TileSetBuilder.name_mapping.INDEX]
			var atlas_pos: Vector2i = tile_array[TileSetBuilder.name_mapping.POS]
			if tileset_index == -1:
				tile_map_layer.erase_cell(global_tile_pos)
			else:
				# 写入TileMapLayer
				tile_map_layer.set_cell(global_tile_pos, tileset_index, atlas_pos)
				##if (global_tile_pos.x < 0):
				##	DebugSystem.console_common_log("渲染查看", "%s 写入类型: %d 区块坐标: %s" % [global_tile_pos, cell.get_cell_attribute().tile_type_id, chunk_pos.x])

## 刷新单个瓦片(挖掘等)
func refresh_single_tile(world_tile:Vector2i):
	DebugSystem.console_common_log("渲染桥", "刷新单个方块，位置: %s" % world_tile)
	var cell = world.get_tile(world_tile)
	# 判空[一般只有意外情况]
	if cell == null:
		DebugSystem.console_warn_log("渲染桥", "单个方块获取失败")
		tile_map_layer.erase_cell(world_tile)
		return
		
	# 根据tile_type_id拿到瓦片编号
	var tile_array = TileSetBuilder.get_tile_draw_info(cell.get_cell_instance().name)
	var tileset_index: int = tile_array[TileSetBuilder.name_mapping.INDEX]
	var atlas_pos: Vector2i = tile_array[TileSetBuilder.name_mapping.POS]
	if tileset_index == -1:
		tile_map_layer.erase_cell(world_tile)
	else:
		tile_map_layer.set_cell(world_tile, tileset_index, atlas_pos)

## 清除区块渲染（区块卸载时调用）
func clear_chunk_render(chunk_pos:Vector2i):
	for local_x in range(Chunk.CHUNK_SIZE_X):
		for local_y in range(Chunk.CHUNK_SIZE_Y):
			var global_tile_x = chunk_pos.x * Chunk.CHUNK_SIZE_X + local_x
			var global_tile_pos = Vector2i(global_tile_x, local_y + chunk_pos.y * Chunk.CHUNK_SIZE_Y)
			tile_map_layer.erase_cell(global_tile_pos)
