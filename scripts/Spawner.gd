## 生成器脚本（Spawner.gd）
## 功能：负责在场景中定时随机生成敌人、金币、据点和宝箱
## 节点结构：Node2D (根节点，可放置在场景的任意位置)

extends Node2D

class_name Spawner

## ========== 可配置变量 ==========

## ========== 敌人生成设置 ==========

## 是否启用敌人生成
@export var enable_enemy_spawning: bool = true
## 敌人生成间隔（秒）
@export var enemy_spawn_interval: float = 3.0
## 每次生成敌人的最大数量
@export var max_enemies_per_spawn: int = 3
## 场景中敌人的最大数量（达到后停止生成）
@export var max_enemies_in_scene: int = 20
## 敌人生成的最小位置偏移（像素）
@export var enemy_spawn_min_offset: float = 100.0
## 敌人生成的最大位置偏移（像素）
@export var enemy_spawn_max_offset: float = 500.0

## ========== 金币生成设置 ==========

## 是否启用金币生成
@export var enable_coin_spawning: bool = true
## 金币生成间隔（秒）
@export var coin_spawn_interval: float = 5.0
## 每次生成金币的最大数量
@export var max_coins_per_spawn: int = 5
## 场景中金币的最大数量
@export var max_coins_in_scene: int = 30

## ========== 占领据点生成设置 ==========

## 是否启用占领据点生成
@export var enable_capture_point_spawning: bool = true
## 占领据点生成间隔（秒）
@export var capture_point_spawn_interval: float = 15.0
## 场景中占领据点的最大数量
@export var max_capture_points_in_scene: int = 3

## ========== 宝箱生成设置 ==========

## 是否启用宝箱生成
@export var enable_chest_spawning: bool = true
## 宝箱生成间隔（秒）
@export var chest_spawn_interval: float = 20.0
## 场景中宝箱的最大数量
@export var max_chests_in_scene: int = 5

## ========== 生成区域设置 ==========

## 是否使用固定生成区域（否则使用视口范围）
@export var use_fixed_spawn_area: bool = false
## 固定生成区域的左上角
@export var spawn_area_min: Vector2 = Vector2(-500, -500)
## 固定生成区域的右下角
@export var spawn_area_max: Vector2 = Vector2(500, 500)

## ========== 私有变量 ==========

## 各种生成计时器
var _enemy_spawn_timer: float = 0.0
var _coin_spawn_timer: float = 0.0
var _capture_point_spawn_timer: float = 0.0
var _chest_spawn_timer: float = 0.0
var _giant_coin_timer: float = 0.0
var _red_key_timer: float = 0.0
## 基础敌人生成间隔（用于难度调整）
var _base_enemy_spawn_interval: float = 0.0
## 巨型金币生成间隔（秒）
@export var giant_coin_interval: float = 60.0
## 红色钥匙生成间隔（秒）
@export var red_key_interval: float = 90.0

## ========== 预加载场景 ==========

## 预加载敌人场景
var enemy_scene: PackedScene = preload("res://scenes/Enemy.tscn")
## 预加载基础收集品场景
var base_collectible_scene: PackedScene = preload("res://scenes/collectibles/BaseCollectible.tscn")
## 预加载宝箱场景
var chest_scene: PackedScene = preload("res://scenes/Chest.tscn")

## ========== 收集品数据 ==========

## 普通金币数据（在 _ready 中通过 CollectibleData.new() 创建）
var coin_data: CollectibleData = null
## 巨型金币数据（在 _ready 中通过 CollectibleData.new() 创建）
var giant_coin_data: CollectibleData = null
## 红色钥匙数据（在 _ready 中通过 CollectibleData.new() 创建）
var red_key_data: CollectibleData = null
## 占领区域数据（在 _ready 中通过 CollectibleData.new() 创建）
var capture_area_data: CollectibleData = null

## ========== Godot 生命周期函数 ==========

func _ready() -> void:
	# 存储基础敌人生成间隔
	_base_enemy_spawn_interval = enemy_spawn_interval

	# 创建收集品数据实例
	_create_collectible_data()

	# 随机化初始计时器，避免所有物体同时生成
	_enemy_spawn_timer = randf() * enemy_spawn_interval
	_coin_spawn_timer = randf() * coin_spawn_interval
	_capture_point_spawn_timer = randf() * capture_point_spawn_interval
	_chest_spawn_timer = randf() * chest_spawn_interval
	_giant_coin_timer = 0.0
	_red_key_timer = 0.0

## ========== 处理逻辑 ==========

func _process(delta: float) -> void:
	# 处理敌人生成
	if enable_enemy_spawning:
		_process_enemy_spawning(delta)

	# 处理金币生成
	if enable_coin_spawning:
		_process_coin_spawning(delta)

	# 处理占领据点生成
	if enable_capture_point_spawning:
		_process_capture_point_spawning(delta)

	# 处理宝箱生成
	if enable_chest_spawning:
		_process_chest_spawning(delta)

	# 处理巨型金币生成
	_process_giant_coin_spawning(delta)

	# 处理红色钥匙生成
	_process_red_key_spawning(delta)

## ========== 敌人生成逻辑 ==========

func _process_enemy_spawning(delta: float) -> void:
	_enemy_spawn_timer -= delta

	if _enemy_spawn_timer <= 0:
		# 检查场景中的敌人数量
		var current_enemy_count: int = GameManager.get_active_enemy_count()

		if current_enemy_count < max_enemies_in_scene:
			# 生成敌人
			var spawn_count: int = randi_range(1, max_enemies_per_spawn)
			for i: int in spawn_count:
				if current_enemy_count + i >= max_enemies_in_scene:
					break
				_spawn_enemy()

		# 重置计时器
		_enemy_spawn_timer = enemy_spawn_interval

func _spawn_enemy() -> void:
	var spawn_position: Vector2 = _get_random_spawn_position(enemy_spawn_min_offset, enemy_spawn_max_offset)
	var enemy: Enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_position
	get_parent().add_child(enemy)

## ========== 金币生成逻辑 ==========

func _process_coin_spawning(delta: float) -> void:
	_coin_spawn_timer -= delta

	if _coin_spawn_timer <= 0:
		# 检查场景中的金币数量
		var current_coin_count: int = get_tree().get_nodes_in_group("coins").size()

		if current_coin_count < max_coins_in_scene:
			# 生成金币
			var spawn_count: int = randi_range(1, max_coins_per_spawn)
			for i: int in spawn_count:
				if current_coin_count + i >= max_coins_in_scene:
					break
				_spawn_coin()

		# 重置计时器
		_coin_spawn_timer = coin_spawn_interval

func _spawn_coin() -> void:
	var spawn_position: Vector2 = _get_random_spawn_position(50.0, 300.0)
	var collectible: BaseCollectible = base_collectible_scene.instantiate()
	collectible.collectible_data = coin_data
	collectible.global_position = spawn_position
	collectible.add_to_group("coins")
	get_parent().add_child(collectible)
	print("Spawner: 金币已生成于位置: ", spawn_position)

## ========== 占领据点生成逻辑 ==========

func _process_capture_point_spawning(delta: float) -> void:
	_capture_point_spawn_timer -= delta

	if _capture_point_spawn_timer <= 0:
		# 检查场景中的占领据点数量
		var current_capture_point_count: int = GameManager.get_active_capture_point_count()

		if current_capture_point_count < max_capture_points_in_scene:
			_spawn_capture_point()

		# 重置计时器
		_capture_point_spawn_timer = capture_point_spawn_interval

func _spawn_capture_point() -> void:
	var spawn_position: Vector2 = _get_random_spawn_position(100.0, 400.0)
	var collectible: BaseCollectible = base_collectible_scene.instantiate()
	collectible.collectible_data = capture_area_data
	collectible.global_position = spawn_position
	get_parent().add_child(collectible)

## ========== 宝箱生成逻辑 ==========

func _process_chest_spawning(delta: float) -> void:
	_chest_spawn_timer -= delta

	if _chest_spawn_timer <= 0:
		# 检查场景中的宝箱数量
		var current_chest_count: int = get_tree().get_nodes_in_group("chests").size()

		if current_chest_count < max_chests_in_scene:
			_spawn_chest()

		# 重置计时器
		_chest_spawn_timer = chest_spawn_interval

func _spawn_chest() -> void:
	var spawn_position: Vector2 = _get_random_spawn_position(80.0, 350.0)
	var chest: Chest = chest_scene.instantiate()
	chest.global_position = spawn_position
	chest.add_to_group("chests")  # 添加到组以便计数
	get_parent().add_child(chest)

## ========== 辅助函数 ==========

## 获取随机生成位置
func _get_random_spawn_position(min_offset: float, max_offset: float) -> Vector2:
	var player_position: Vector2 = Vector2.ZERO

	# 如果有玩家，在玩家周围生成
	if GameManager.player != null and is_instance_valid(GameManager.player):
		player_position = GameManager.player.global_position

	# 生成随机角度和距离
	var random_angle: float = randf() * TAU
	var random_distance: float = randf_range(min_offset, max_offset)

	# 计算生成位置
	var spawn_position: Vector2 = player_position + Vector2.from_angle(random_angle) * random_distance

	# 如果使用固定生成区域，限制在区域内
	if use_fixed_spawn_area:
		spawn_position.x = clamp(spawn_position.x, spawn_area_min.x, spawn_area_max.x)
		spawn_position.y = clamp(spawn_position.y, spawn_area_min.y, spawn_area_max.y)

	return spawn_position

## ========== 辅助函数 ==========

## 创建收集品数据实例
func _create_collectible_data() -> void:
	print("Spawner: 开始创建收集品数据")

	# 创建普通金币数据
	coin_data = CollectibleData.new()
	coin_data.display_name = "金币"
	coin_data.description = "收集金币获得分数"
	coin_data.collectible_type = CollectibleData.CollectibleType.COLLECTIBLE
	coin_data.modulate_color = Color(1, 0.8, 0, 1)
	coin_data.scale = Vector2(1, 1)
	coin_data.collision_shape_size = Vector2(32, 32)
	coin_data.coin_value = 1
	coin_data.lifetime = 15.0
	coin_data.enable_rotation = true
	coin_data.rotation_speed = 180.0
	coin_data.enable_float = true
	coin_data.float_amplitude = 10.0
	coin_data.float_frequency = 2.0

	print("Spawner: 普通金币数据创建完成")

	# 创建巨型金币数据
	giant_coin_data = CollectibleData.new()
	giant_coin_data.display_name = "巨型金币"
	giant_coin_data.description = "高价值金币！值得收集！"
	giant_coin_data.collectible_type = CollectibleData.CollectibleType.COLLECTIBLE
	giant_coin_data.modulate_color = Color.GOLD
	giant_coin_data.scale = Vector2(2, 2)
	giant_coin_data.collision_shape_size = Vector2(64, 64)
	giant_coin_data.coin_value = 10
	giant_coin_data.lifetime = 30.0
	giant_coin_data.reward_text = "获得巨型金币！+10金币"
	giant_coin_data.show_direction_arrow = true
	giant_coin_data.arrow_color = Color.GOLD
	giant_coin_data.arrow_show_distance = 300.0
	giant_coin_data.arrow_hide_distance = 200.0
	giant_coin_data.arrow_priority = 5
	giant_coin_data.enable_rotation = true
	giant_coin_data.rotation_speed = 90.0
	giant_coin_data.enable_float = true
	giant_coin_data.float_amplitude = 10.0
	giant_coin_data.float_frequency = 2.0

	# 创建红色钥匙数据
	red_key_data = CollectibleData.new()
	red_key_data.display_name = "红色钥匙"
	red_key_data.description = "收集3把钥匙获得巨额奖励！"
	red_key_data.collectible_type = CollectibleData.CollectibleType.COLLECTIBLE
	red_key_data.modulate_color = Color.RED
	red_key_data.scale = Vector2(1.5, 1.5)
	red_key_data.collision_shape_size = Vector2(48, 48)
	red_key_data.lifetime = 60.0
	red_key_data.reward_text = "获得红色钥匙！"
	red_key_data.custom_effect = "red_key"
	red_key_data.show_direction_arrow = true
	red_key_data.arrow_color = Color.RED
	red_key_data.arrow_show_distance = 400.0
	red_key_data.arrow_hide_distance = 250.0
	red_key_data.arrow_priority = 10
	red_key_data.enable_float = true
	red_key_data.float_amplitude = 15.0
	red_key_data.float_frequency = 2.0

	# 创建占领区域数据
	capture_area_data = CollectibleData.new()
	capture_area_data.display_name = "占领点"
	capture_area_data.description = "站在区域内进行占领"
	capture_area_data.collectible_type = CollectibleData.CollectibleType.AREA_STAY
	capture_area_data.modulate_color = Color.BLUE
	capture_area_data.scale = Vector2(2.5, 2.5)
	capture_area_data.collision_shape_size = Vector2(150, 150)
	capture_area_data.capture_time = 5.0
	capture_area_data.capture_bonus_coins = 3
	capture_area_data.show_direction_arrow = false

## ========== 公共方法 ==========

## 立即生成指定数量的敌人
func spawn_enemy_immediate(count: int) -> void:
	for i: int in count:
		_spawn_enemy()

## 立即生成指定数量的金币
func spawn_coin_immediate(count: int) -> void:
	for i: int in count:
		_spawn_coin()

## 立即生成一个占领据点
func spawn_capture_point_immediate() -> void:
	_spawn_capture_point()

## 立即生成一个宝箱
func spawn_chest_immediate() -> void:
	_spawn_chest()

## 暂停所有生成
func pause_spawning() -> void:
	set_process(false)

## 恢复所有生成
func resume_spawning() -> void:
	set_process(true)

## 增加游戏难度（敌人刷新频率翻倍）
func increase_difficulty(multiplier: float = 2.0) -> void:
	enemy_spawn_interval = _base_enemy_spawn_interval / multiplier

## ========== 巨型金币生成逻辑 ==========

func _process_giant_coin_spawning(delta: float) -> void:
	_giant_coin_timer += delta

	if _giant_coin_timer >= giant_coin_interval:
		spawn_giant_coin()
		_giant_coin_timer = 0.0

## 生成巨型金币
func spawn_giant_coin() -> void:
	var spawn_position: Vector2 = _get_random_spawn_position(150.0, 500.0)
	var collectible: BaseCollectible = base_collectible_scene.instantiate()
	collectible.collectible_data = giant_coin_data
	collectible.global_position = spawn_position
	get_parent().add_child(collectible)

## ========== 红色钥匙生成逻辑 ==========

func _process_red_key_spawning(delta: float) -> void:
	_red_key_timer += delta

	if _red_key_timer >= red_key_interval:
		spawn_red_keys(3)
		_red_key_timer = 0.0

## 生成红色钥匙
func spawn_red_keys(count: int = 3) -> void:
	for i in count:
		var spawn_position: Vector2 = _get_random_spawn_position(200.0, 600.0)
		var collectible: BaseCollectible = base_collectible_scene.instantiate()
		collectible.collectible_data = red_key_data
		collectible.global_position = spawn_position
		get_parent().add_child(collectible)
