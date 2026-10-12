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

	# 碰撞初始化
	var rect_shape = RectangleShape2D.new()
	var grid_distance: int = CoordinateAttributes.get_coordinate_distance()
	rect_shape.size = Vector2(grid_distance / drop_reduce_scale, grid_distance / drop_reduce_scale)
	drop_sprite.scale.x = grid_distance / drop_reduce_scale
	drop_sprite.scale.y = grid_distance / drop_reduce_scale
	collisionShape.shape = rect_shape
