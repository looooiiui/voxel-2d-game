extends CharacterBody2D

class_name player

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var grid_pos: Vector2i = Vector2i(0, 0)

func _physics_process(delta: float) -> void:
	_sync_grid_pos()
	_player_move(delta)
	move_and_slide()
	
## 同步网格坐标
func _sync_grid_pos() -> void:
	grid_pos = CoordinateAttributes.cal_current_grid_pos(global_position.x, global_position.y)

## 移动逻辑
func _player_move(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
## 获得玩家坐标
func get_player_grid_pos() -> Vector2i:
	return grid_pos
	
## 获得玩家浮点坐标
func get_player_global_pos() -> Vector2:
	return global_position
