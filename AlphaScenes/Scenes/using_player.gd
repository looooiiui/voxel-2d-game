extends Node2D

@export var information_label: Label
@export var display_sprite: Sprite2D
@export var move_speed: float = 300

var label_offset: Vector2 	= Vector2(-16, -64)
var grid_pos: Vector2i		= Vector2i(0, 0)

func _ready() -> void:
	information_label.top_level = true
	
func _physics_process(delta: float) -> void:
	_sync_grid_pos()
	_move_position(delta)
	_information_label_display()
	
## 移动测试,用来表示坐标的
func _move_position(delta: float) -> void:
	var input = Input.get_vector("left", "right", "up", "down")
	var input_nor = input.normalized()
	global_position.x += input_nor.x * move_speed * delta
	global_position.y += input_nor.y * move_speed * delta

## 显示调试信息
func _information_label_display() -> void:
	information_label.global_position = lerp(information_label.global_position, global_position + label_offset, 0.1)
	information_label.text = "(%d, %d)" % [grid_pos.x, grid_pos.y]
	
## 同步网格坐标
func _sync_grid_pos() -> void:
	grid_pos = CoordinateAttributes.cal_current_grid_pos(global_position.x, global_position.y)
	
	
	
