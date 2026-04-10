## 收集品基类脚本
## 功能：统一处理所有收集品的碰撞、方向指引、生命周期
extends Area2D
class_name BaseCollectible

## ========== 配置 ==========

## 收集品数据配置
@export var collectible_data: CollectibleData = null

## ========== 节点引用 ==========

## 精灵节点引用
@onready var sprite: Sprite2D = $Sprite2D
## 碰撞形状引用
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
## 生命周期计时器引用
@onready var lifetime_timer: Timer = $LifetimeTimer
## 区域精灵引用（可选）
@onready var area_sprite: ColorRect = $AreaSprite if has_node("AreaSprite") else null
## 进度条引用（可选）
@onready var progress_bar: ProgressBar = $ProgressBar if has_node("ProgressBar") else null

## ========== 私有变量 ==========

## 初始Y位置
var _initial_y: float = 0.0
## 浮动动画计时器
var _float_timer: float = 0.0
## 玩家是否在范围内
var _player_in_range: bool = false
## 占领进度
var _capture_progress: float = 0.0

## ========== 信号 ==========

## 区域占领完成时发出
signal capture_area_completed()
## 触发激活时发出
signal trigger_activated()

## ========== Godot 生命周期函数 ==========

func _ready() -> void:
	_apply_collectible_data()
	_setup_collision()
	_setup_visuals()
	_register_direction_indicator()
	_connect_signals()

## ========== 处理逻辑 ==========

func _physics_process(delta: float) -> void:
	if collectible_data == null:
		return

	# 旋转动画
	if collectible_data.enable_rotation:
		rotation_degrees += collectible_data.rotation_speed * delta

	# 浮动动画
	if collectible_data.enable_float:
		_float_timer += delta
		var offset: float = sin(_float_timer * collectible_data.float_frequency * TAU) * collectible_data.float_amplitude
		global_position.y = _initial_y + offset

	# 区域占领逻辑
	if collectible_data.collectible_type == CollectibleData.CollectibleType.AREA_STAY:
		_process_area_capture(delta)

## ========== 配置应用 ==========

func _apply_collectible_data() -> void:
	"""应用collectible_data中的所有配置"""
	if collectible_data == null:
		return

	# 应用外观
	if sprite != null:
		if collectible_data.sprite_texture != null:
			sprite.texture = collectible_data.sprite_texture
		else:
			# 如果没有贴图，创建一个简单的彩色矩形作为可见占位符
			var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
			image.fill(Color(1, 1, 1, 1))  # 填充白色
			var texture = ImageTexture.create_from_image(image)
			sprite.texture = texture
		sprite.modulate = collectible_data.modulate_color
		sprite.scale = collectible_data.scale

		# 调试：确保物品可见
		sprite.visible = true

	# 设置Z轴
	z_index = collectible_data.z_index

	# 设置碰撞体
	if collision_shape != null:
		if collectible_data.collision_shape_type == "circle":
			collision_shape.shape = CircleShape2D.new()
			(collision_shape.shape as CircleShape2D).radius = collectible_data.collision_shape_size.x / 2.0
		else:
			collision_shape.shape = RectangleShape2D.new()
			(collision_shape.shape as RectangleShape2D).size = collectible_data.collision_shape_size

	# 设置生命周期
	if collectible_data.lifetime > 0:
		lifetime_timer.wait_time = collectible_data.lifetime
		lifetime_timer.start()

	# 记录初始位置
	_initial_y = global_position.y

func _setup_collision() -> void:
	"""设置碰撞层"""
	collision_layer = 2  # 收集品层
	collision_mask = 1  # 检测玩家层（第0层）

func _setup_visuals() -> void:
	"""设置视觉效果"""
	if collectible_data == null:
		return

	# 区域类型的特殊视觉
	if collectible_data.collectible_type == CollectibleData.CollectibleType.AREA_STAY:
		if area_sprite != null:
			area_sprite.color = collectible_data.modulate_color
			area_sprite.color.a = 0.3
			area_sprite.size = collectible_data.collision_shape_size
			area_sprite.position = -collectible_data.collision_shape_size / 2.0

func _connect_signals() -> void:
	"""连接信号"""
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	lifetime_timer.timeout.connect(_on_lifetime_timeout)

## ========== 方向指引管理 ==========

func _register_direction_indicator() -> void:
	"""注册到方向指引系统"""
	if collectible_data == null or not collectible_data.show_direction_arrow:
		return

	# 延迟注册，确保UIManager已就绪
	call_deferred("_do_register_indicator")

func _do_register_indicator() -> void:
	"""执行方向指引注册"""
	var ui_manager = get_tree().get_first_node_in_group("ui_manager")
	if ui_manager != null and ui_manager.has_method("show_collectible_indicator"):
		ui_manager.show_collectible_indicator(
			self,
			collectible_data.arrow_color,
			collectible_data.arrow_show_distance,
			collectible_data.arrow_hide_distance,
			collectible_data.arrow_priority
		)

func _unregister_direction_indicator() -> void:
	"""移除方向指引"""
	var ui_manager = get_tree().get_first_node_in_group("ui_manager")
	if ui_manager != null and ui_manager.has_method("hide_collectible_indicator"):
		ui_manager.hide_collectible_indicator(self)

## ========== 区域占领逻辑 ==========

func _process_area_capture(delta: float) -> void:
	"""处理区域占领逻辑"""
	if not _player_in_range:
		return

	_capture_progress += delta

	# 更新进度条
	if progress_bar != null:
		progress_bar.value = (_capture_progress / collectible_data.capture_time) * 100.0

	# 检查是否完成
	if _capture_progress >= collectible_data.capture_time:
		_on_capture_completed()

## ========== 交互处理 ==========

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_in_range = true
		_handle_interaction(body)

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_in_range = false
		_capture_progress = 0.0
		if progress_bar != null:
			progress_bar.value = 0.0

func _handle_interaction(player: Player) -> void:
	"""处理交互逻辑"""
	if collectible_data == null:
		return

	match collectible_data.collectible_type:
		CollectibleData.CollectibleType.COLLECTIBLE:
			_on_collected()
		CollectibleData.CollectibleType.TRIGGER:
			_on_trigger()
		# AREA_STAY 在 _process_area_capture 中处理

## ========== 收集/触发逻辑 ==========

func _on_collected() -> void:
	"""收集完成"""
	# 给予金币
	if collectible_data.coin_value > 0:
		GameManager.add_coins(collectible_data.coin_value)

	# 恢复生命
	if collectible_data.health_value > 0:
		GameManager.heal_player(collectible_data.health_value)

	# 显示提示
	if not collectible_data.reward_text.is_empty():
		GameManager.reward_obtained.emit(collectible_data.reward_text)

	# 自定义效果
	_handle_custom_effect()

	# 移除方向指引
	_unregister_direction_indicator()

	# 队列释放
	queue_free()

func _on_capture_completed() -> void:
	"""区域占领完成"""
	# 给予奖励
	if collectible_data.capture_bonus_coins > 0:
		GameManager.add_coins(collectible_data.capture_bonus_coins)

	# 移除方向指引
	_unregister_direction_indicator()

	# 发出信号
	capture_area_completed.emit()

	# 队列释放
	queue_free()

func _on_trigger() -> void:
	"""触发型交互（如撤离点）"""
	trigger_activated.emit()

func _handle_custom_effect() -> void:
	"""处理自定义效果"""
	if collectible_data.custom_effect == "red_key":
		GameManager.on_red_key_collected()

## ========== 信号回调 ==========

func _on_lifetime_timeout() -> void:
	queue_free()
