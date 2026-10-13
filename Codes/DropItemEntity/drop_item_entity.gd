extends RigidBody2D

class_name DropItemEntity

@export var collisionShape: CollisionShape2D
@export var drop_sprite: Sprite2D

var uid: int
var item_name: String
var bridge: DropBridge
var drop_reduce_scale: int = 4

## 外部初始化碰撞体积，贴图等
func setup(new_uid: int, new_item_name: String, new_bridge: DropBridge) -> void:
	uid = new_uid
	item_name = new_item_name
	bridge = new_bridge
	_search_and_take_texture()

	# 碰撞初始化
	var rect_shape = RectangleShape2D.new()
	var grid_distance: int = CoordinateAttributes.get_coordinate_distance()
	rect_shape.size = Vector2(grid_distance / drop_reduce_scale, grid_distance / drop_reduce_scale)
	collisionShape.shape = rect_shape

## 寻找掉落物贴图
func _search_and_take_texture() -> void:
	var texture_path: String = ResourcePath.drop_item_texture_path
	texture_path = "%s%s.png" % [texture_path, item_name]
	var tex: Texture2D = load(texture_path)
	if tex == null:
		DebugSystem.console_warn_log("实例(uid = %s)" % uid, "找不到贴图资源：%s" % texture_path)
		return
	
	drop_sprite.texture = tex
	var grid_distance: int = CoordinateAttributes.get_coordinate_distance()
	# 目标：希望Sprite最终显示尺寸 = target_size
	var target_size := Vector2(grid_distance / 4, grid_distance / 4)
	var tex_original_size = tex.get_size()
	var scale_factor = target_size.x / tex_original_size.x
	# DebugSystem.console_common_log("实例(uid = %s)" % uid, "当前贴图缩放比例: %s" % scale_factor)
	drop_sprite.scale = Vector2(scale_factor, scale_factor)
