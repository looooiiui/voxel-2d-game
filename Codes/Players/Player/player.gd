extends CharacterBody2D

## 玩家节点持有的代码
class_name PlayerEntity

var player_data: PlayerData

## 设置玩家数据
func setup(new_player_data: PlayerData):
	player_data = new_player_data

## 主循环，同步玩家数据等
func _physics_process(delta: float) -> void:
	if player_data == null:
		return 
	_sync_data()
	_player_move(delta)
	move_and_slide()
	
## 同步网格坐标
func _sync_data() -> void:
	player_data.sync_data(global_position)

## 移动逻辑
func _player_move(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump"):
		velocity.y = player_data.jump_velocity

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * player_data.move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, player_data.move_speed)
		
