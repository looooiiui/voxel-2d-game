extends RefCounted
## tileSet 图集生成
class_name TileSetBuilder
## 产物最终输出
static var built_tileset: TileSet
## 映射表，提供给渲染桥
## 映射表结构: { "name": [source_id, atlas_pos] }
static var name_to_source_id: Dictionary[String, Array] = {}

## 映射数组内数据
enum name_mapping{
	INDEX = 0,
	POS = 1
}

## 生成图集以及映射表
static func build_tileset() -> void:
	# 新建空TileSet
	built_tileset = TileSet.new()
	built_tileset.tile_size = Vector2i(
		CoordinateAttributes.get_coordinate_distance(),
		CoordinateAttributes.get_coordinate_distance()
	)

	# add_physics_layer，自动生成物理层
	built_tileset.add_physics_layer()
	built_tileset.set_physics_layer_collision_layer(0, 1)
	built_tileset.set_physics_layer_collision_mask(0, 1)
	
	name_to_source_id.clear()
	
	# 获取实例方块中所有的实例
	var tile_cell_instances: Dictionary = TileCellInstances.OriginalInstancesType
	DebugSystem.console_common_log("图集生成器", "获得属性集: %s" % tile_cell_instances)
	# 循环加入图集
	for name in tile_cell_instances:
		# 跳过空气
		if name == "air":
			continue
		get_texture_atlas_source(ResourcePath.tile_cell_texture_path, name)
	DebugSystem.console_common_log("图集生成器", "生成图集映射: %s 图集: %s" % [name_to_source_id, built_tileset])

## 添加对应图集
static func get_texture_atlas_source(texture_path: String, name: String) -> void:
	texture_path = "%s%s.png" % [texture_path, name]
	var tex: Texture2D = load(texture_path)
	if tex == null:
		DebugSystem.console_warn_log("图集生成器", "找不到贴图资源：%s" % texture_path)
		return
	# 创建图集源
	var atlas_source = TileSetAtlasSource.new()
	atlas_source.texture = tex
	# 单图，图集图块大小 为网格距离 x 网格距离
	var grid_distance: int = CoordinateAttributes.get_coordinate_distance()
	atlas_source.texture_region_size = Vector2i(
		grid_distance,
		grid_distance
	)
	var atlas_pos = Vector2i(0,0)
	# 注册这个图集内的瓦片
	atlas_source.create_tile(atlas_pos)
	
	# 添加source进tileset，拿到source_id
	var source_id = built_tileset.add_source(atlas_source)
	
	# 添加碰撞箱，通过检测物体属性(is_solid)
	var instance = TileCellInstances.OriginalInstancesType.get(name)
	if instance != null:
		var is_coll: bool = instance.get_cell_attribute().is_solid
		# 3. 给图集里面(0,0)这个方块加上碰撞
		var tile_data: TileData = atlas_source.get_tile_data(atlas_pos ,0)
		# 添加碰撞箱
		if tile_data != null:
			tile_data.add_collision_polygon(0)
			var grid_half: int = grid_distance / 2
			var rect_poly = PackedVector2Array(
				[
				Vector2(-grid_half, -grid_half),
				Vector2(grid_half, -grid_half),
				Vector2(grid_half, grid_half),
				Vector2(-grid_half, grid_half)
				]
			)
			tile_data.set_collision_polygon_points(0,0, rect_poly)
		
	# 存入名字映射
	name_to_source_id[name] = [source_id, atlas_pos]
	DebugSystem.console_common_log("图集注册表", "注册方块 %s source_id=%d" % [name, source_id])
	
## 根据方块名字查询source_id、atlas坐标，渲染用【改为static】
static func get_tile_draw_info(name: String) -> Array:
	if name_to_source_id.has(name):
		return name_to_source_id[name]
	else:
		# 空气，返回-1代表不绘制
		return [-1, Vector2i(-1,-1)]
