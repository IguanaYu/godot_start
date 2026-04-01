## 玩家脚本（Player.gd）
## 功能：处理玩家移动、受伤、无敌状态、吃金币回血、移速BUFF等逻辑
## 节点结构：CharacterBody2D (根节点)
##   ├── Sprite2D (玩家精灵)
##   ├── CollisionShape2D (碰撞体)
##   └── Area2D (伤害检测区域)
##       ├── CollisionShape2D (检测碰撞体)
##       └── Timer (无敌帧计时器)

extends CharacterBody2D

class_name Player

## ========== 信号定义 ==========

## 玩家受到伤害时发出
signal player_took_damage(damage: int)
## 玩家死亡时发出
signal player_died()

## ========== 可配置变量 ==========

## 基础移动速度（像素/秒）
@export var base_speed: float = 200.0
## 加速度
@export var acceleration: float = 1000.0
## 摩擦力
@export var friction: float = 1500.0
## 无敌时间（秒）
@export var invincibility_duration: float = 1.5
## 无敌状态闪烁间隔（秒）
@export var blink_interval: float = 0.1

## ========== 私有变量 ==========

## 当前移动速度
var _current_speed: float = base_speed
## 是否处于无敌状态
var _is_invincible: bool = false
## 无敌状态计时器
var _invincibility_timer: float = 0.0
## 闪烁计时器
var _blink_timer: float = 0.0
## 原始精灵透明度
var _original_modulate: Color = Color.WHITE
## 是否处于无敌星状态（无敌且秒杀敌人）
var _is_star_invincible: bool = false
## BUFF 计时器字典
var _buff_timers: Dictionary = {}
## 移速BUFF倍数
var _speed_multiplier: float = 1.0

## ========== 交互系统 ==========

## 附近的可交互对象列表
var _nearby_interactables: Array = []

## ========== 节点引用 ==========

## 精灵节点引用
@onready var sprite: Sprite2D = $Sprite2D
## 动画精灵节点引用
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
## 碰撞形状引用
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
## 伤害检测区域引用
@onready var hurt_area: Area2D = $HurtArea
## 伤害检测碰撞形状引用
@onready var hurt_collision_shape: CollisionShape2D = $HurtArea/CollisionShape2D
## 交互检测区域引用
@onready var interaction_area: Area2D = $InteractionArea

## ========== Godot 生命周期函数 ==========

func _ready() -> void:
	# 应用角色数据
	_apply_character_data()

	# 重新初始化当前速度（确保使用场景中的覆盖值）
	_current_speed = base_speed

	# 设置 GameManager 的玩家引用
	GameManager.player = self

	# 获取无敌帧计时器引用（在运行时获取）
	var timer_node: Timer = $HurtArea/InvincibilityTimer
	if timer_node != null:
		timer_node.timeout.connect(_on_invincibility_timer_timeout)

	# 连接伤害检测信号
	if hurt_area != null:
		hurt_area.body_entered.connect(_on_hurt_area_body_entered)

	# 连接交互检测信号
	if interaction_area != null:
		interaction_area.body_entered.connect(_on_interactable_entered)
		interaction_area.body_exited.connect(_on_interactable_exited)

	# 初始化精灵颜色
	if sprite != null:
		_original_modulate = sprite.modulate

	# 初始化动画（播放idle动画）
	if animated_sprite != null:
		animated_sprite.play("idle")

## ========== 物理处理（每帧调用） ==========

func _physics_process(delta: float) -> void:
	# 处理无敌状态闪烁
	if _is_invincible or _is_star_invincible:
		_blink_timer -= delta
		if _blink_timer <= 0:
			_blink_timer = blink_interval
			_toggle_sprite_visibility()

	# 处理 BUFF 计时器
	_process_buff_timers(delta)

	# 处理移动
	_handle_movement(delta)

	# 移动并处理碰撞
	move_and_slide()

## ========== 移动处理 ==========

## 处理玩家移动输入
func _handle_movement(delta: float) -> void:
	# 获取输入方向
	var input_dir: Vector2 = Vector2.ZERO

	if Input.is_action_pressed("move_up"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_down"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1

	# 归一化对角线移动速度
	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()

	# 控制动画和精灵翻转
	if animated_sprite != null:
		if input_dir != Vector2.ZERO:
			# 移动时播放run动画
			if animated_sprite.get_animation() != "run":
				animated_sprite.play("run")
			# 根据移动方向翻转精灵
			animated_sprite.flip_h = input_dir.x < 0
		else:
			# 停止时切换到idle动画
			if animated_sprite.get_animation() != "idle":
				animated_sprite.play("idle")

	# 应用当前速度
	var target_velocity: Vector2 = input_dir * _current_speed * _speed_multiplier

	# 平滑加速和减速
	if input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	# # 调试：打印当前速度和加速度配置
	# if input_dir != Vector2.ZERO:
	# 	print("当前速度: ", velocity.length(), " | 目标: ", target_velocity.length(), " | 加速度: ", acceleration, " | 摩擦力: ", friction)

## ========== 伤害处理 ==========

## 处理受到伤害
func take_damage(damage: int = 1) -> void:
	# 无敌状态下不受伤
	if _is_invincible or _is_star_invincible:
		return

	# 调用 GameManager 扣血
	GameManager.damage_player(damage)
	player_took_damage.emit(damage)

	# 启动无敌状态
	_start_invincibility()

## 启动无敌状态
func _start_invincibility() -> void:
	_is_invincible = true

	# 启动无敌计时器
	var timer_node: Timer = $HurtArea/InvincibilityTimer
	if timer_node != null:
		timer_node.wait_time = invincibility_duration
		timer_node.start()

	# 设置闪烁计时器
	_blink_timer = 0.0

## 结束无敌状态
func _end_invincibility() -> void:
	_is_invincible = false
	if sprite != null:
		sprite.visible = true
		sprite.modulate = _original_modulate

## 切换精灵可见性（闪烁效果）
func _toggle_sprite_visibility() -> void:
	if sprite != null:
		sprite.visible = not sprite.visible

## ========== 无敌星状态 ==========

## 启动无敌星状态（无敌且秒杀敌人）
func start_star_invincibility(duration: float = 10.0) -> void:
	_is_star_invincible = true
	_is_invincible = false  # 无敌星状态下不需要普通无敌

	# 改变精灵颜色为金黄色
	if sprite != null:
		sprite.modulate = Color.GOLD

	# 设置计时器
	if not _buff_timers.has("star_invincibility"):
		_buff_timers["star_invincibility"] = duration

## 结束无敌星状态
func _end_star_invincibility() -> void:
	_is_star_invincible = false
	if sprite != null:
		sprite.modulate = _original_modulate
		sprite.visible = true
	_buff_timers.erase("star_invincibility")

## ========== BUFF 系统 ==========

## 应用 BUFF 效果
func apply_buff(buff_type: String) -> void:
	match buff_type:
		"speed_boost":
			_apply_speed_boost(10.0)  # 10秒持续时间
		"star_invincibility":
			start_star_invincibility(10.0)  # 10秒持续时间
		_:
			push_warning("Unknown buff type: %s" % buff_type)

## 应用移速提升BUFF
func _apply_speed_boost(duration: float = 10.0) -> void:
	_speed_multiplier = 1.3  # 提升30%

	if not _buff_timers.has("speed_boost"):
		_buff_timers["speed_boost"] = duration

	# 改变精灵颜色为绿色提示
	if not _is_star_invincible and sprite != null:
		sprite.modulate = Color.GREEN_YELLOW

## 处理 BUFF 计时器
func _process_buff_timers(delta: float) -> void:
	var buffs_to_remove: Array[String] = []

	for buff_name: String in _buff_timers.keys():
		_buff_timers[buff_name] -= delta

		if _buff_timers[buff_name] <= 0:
			# 移除过期 BUFF
			match buff_name:
				"speed_boost":
					_speed_multiplier = 1.0
					if not _is_star_invincible and not _is_invincible and sprite != null:
						sprite.modulate = _original_modulate
				"star_invincibility":
					_end_star_invincibility()

			buffs_to_remove.append(buff_name)

	# 移除过期的 BUFF
	for buff_name: String in buffs_to_remove:
		_buff_timers.erase(buff_name)

## ========== 信号回调 ==========

## 伤害检测区域检测到碰撞体
func _on_hurt_area_body_entered(body: Node2D) -> void:
	# 检查碰撞体是否是敌人
	if body is Enemy:
		var enemy: Enemy = body as Enemy

		if _is_star_invincible:
			# 无敌星状态下直接秒杀敌人
			enemy.destroy()
		else:
			# 普通状态下玩家受伤
			take_damage(1)

## 无敌时间计时器超时
func _on_invincibility_timer_timeout() -> void:
	_end_invincibility()

## ========== 公共方法 ==========

## 恢复玩家生命值（由 GameManager 调用）
func heal(amount: int) -> void:
	GameManager.heal_player(amount)

## 获取当前是否无敌
func is_invincible() -> bool:
	return _is_invincible or _is_star_invincible

## 获取当前是否是无敌星状态
func is_star_invincible() -> bool:
	return _is_star_invincible

## ========== 公共方法 ==========

## 应用角色数据到Player
func _apply_character_data() -> void:
	if not GameManager.has_method("get") or GameManager.get("selected_character_data") == null:
		return

	var char_data = GameManager.selected_character_data

	# 应用速度
	base_speed = char_data.speed
	_current_speed = base_speed

	# 应用动画帧资源
	if animated_sprite != null and char_data.sprite_frames != null:
		animated_sprite.sprite_frames = char_data.sprite_frames
		# 重新播放idle动画
		if animated_sprite.sprite_frames.has_animation("idle"):
			animated_sprite.play("idle")

## ========== 清理 ==========

func _exit_tree() -> void:
	# 清理 GameManager 引用
	if GameManager.player == self:
		GameManager.player = null

## ========== 交互系统 ==========

## 输入处理
func _input(event: InputEvent) -> void:
	# 处理交互键（E键）
	if event.is_action_pressed("interact"):
		_try_interact()

## 尝试交互
func _try_interact() -> void:
	if _nearby_interactables.is_empty():
		return

	# 找到最近的交互对象
	var closest = null
	var closest_dist = INF

	for obj in _nearby_interactables:
		if is_instance_valid(obj):
			var dist = global_position.distance_to(obj.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = obj

	# 调用最近对象的交互方法
	if closest != null and is_instance_valid(closest):
		if closest.has_method("interact"):
			closest.interact()

## 可交互对象进入范围
func _on_interactable_entered(body: Node2D) -> void:
	if body.is_in_group("interactables"):
		_nearby_interactables.append(body)

## 可交互对象离开范围
func _on_interactable_exited(body: Node2D) -> void:
	_nearby_interactables.erase(body)
