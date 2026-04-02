## 撤离点脚本（EvacuationPoint.gd）
## 功能：处理撤离点的占领逻辑，占领完成后切换到休息场景
## 节点结构：Area2D (根节点)
##   ├── AreaSprite (范围指示器 - 大的半透明紫色圆形)
##   ├── Sprite2D (撤离点贴图标识)
##   ├── CollisionShape2D (碰撞体 - 圆形)
##   └── ProgressBar (进度条)

@tool
extends Area2D

class_name EvacuationPoint

## ========== 信号定义 ==========

## 占领进度变化时发出（参数：当前进度 0-100）
signal capture_progress_changed(progress: int)
## 撤离点占领完成时发出
signal evacuation_point_captured()

## ========== 可配置变量 ==========

## 玩家在撤离点内时每秒增加的进度
@export var capture_rate: float = 25.0
## 玩家离开撤离点时每秒减少的进度
@export var decay_rate: float = 15.0
## 占领成功奖励的金币数量
@export var capture_bonus_coins: int = 10

## ========== 范围指示器设置 ==========

## 范围指示器的大小（缩放倍数）
@export var area_sprite_scale: float = 2.0
## 范围指示器的图像分辨率（越高越清晰，但性能开销大）
@export var area_sprite_size: int = 128
## 范围指示器的圆形半径（相对于图像尺寸）
@export_range(0.1, 1.0) var area_sprite_radius_ratio: float = 0.47

## ========== 私有变量 ==========

## 当前占领进度（0-100）
var _capture_progress: float = 0.0
## 玩家是否在撤离点内
var _player_inside: bool = false
## 是否已被占领完成
var _is_completed: bool = false

## ========== 节点引用 ==========

## 范围指示器精灵节点引用
@onready var area_sprite: Sprite2D = $AreaSprite

## 编辑器中监控参数变化
var _last_scale: float = 0
var _last_size: int = 0
var _last_radius_ratio: float = 0
## 精灵节点引用（贴图标识）
@onready var sprite: Sprite2D = $Sprite2D
## 碰撞形状引用
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
## 进度条引用
@onready var progress_bar: ProgressBar = $ProgressBar

## ========== Godot 生命周期函数 ==========

func _ready() -> void:
	# 连接信号
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# 启用碰撞检测（仅检测玩家）
	collision_layer = 0
	collision_mask = 1 << 0  # 第0层是玩家层

	# 创建纯色圆形纹理
	create_solid_circle_texture()

	# 初始化撤离点外观
	_initialize_appearance()

	# 编辑器模式：监控参数变化
	if Engine.is_editor_hint():
		_last_scale = area_sprite_scale
		_last_size = area_sprite_size
		_last_radius_ratio = area_sprite_radius_ratio

## 编辑器中每帧检查参数变化
func _process(delta: float) -> void:
	# 编辑器模式：参数变化时重新生成纹理
	if Engine.is_editor_hint():
		if area_sprite_scale != _last_scale or area_sprite_size != _last_size or area_sprite_radius_ratio != _last_radius_ratio:
			create_solid_circle_texture()
			_last_scale = area_sprite_scale
			_last_size = area_sprite_size
			_last_radius_ratio = area_sprite_radius_ratio
		return

	# 游戏模式：正常逻辑
	if _is_completed:
		return

	# 处理占领进度
	if _player_inside:
		# 玩家在撤离点内，增加进度
		_capture_progress += capture_rate * delta
	else:
		# 玩家离开撤离点，减少进度
		_capture_progress -= decay_rate * delta

	# 限制进度范围
	_capture_progress = clamp(_capture_progress, 0.0, 100.0)

	# 更新视觉显示
	_update_visuals()

	# 发出进度变化信号
	capture_progress_changed.emit(int(_capture_progress))

	# 检查是否占领完成
	if _capture_progress >= 100.0:
		_complete_capture()

## 创建纯色圆形纹理
func create_solid_circle_texture() -> void:
	if area_sprite == null:
		return

	# 创建指定大小的图像
	var image = Image.create(area_sprite_size, area_sprite_size, false, Image.FORMAT_RGBA8)

	# 填充透明背景
	image.fill(Color(0, 0, 0, 0))

	# 绘制圆形（从中心向外填充）
	var center = Vector2(area_sprite_size / 2.0, area_sprite_size / 2.0)
	var radius = float(area_sprite_size) * area_sprite_radius_ratio

	for y in range(area_sprite_size):
		for x in range(area_sprite_size):
			var pos = Vector2(x, y)
			var distance = pos.distance_to(center)
			if distance <= radius:
				# 设置纯色白色（alpha会在modulate中控制）
				image.set_pixel(x, y, Color.WHITE)

	# 创建纹理
	var texture = ImageTexture.create_from_image(image)

	# 设置缩放和纹理
	area_sprite.texture = texture
	area_sprite.scale = Vector2(area_sprite_scale, area_sprite_scale)

	# 在编辑器中也显示纹理
	if Engine.is_editor_hint():
		area_sprite.modulate = Color(0.5, 0, 0.5, 0.5)

## 初始化撤离点外观
func _initialize_appearance() -> void:
	# 设置撤离点颜色为紫色（区别于CapturePoint的蓝色）
	if area_sprite != null:
		area_sprite.modulate = Color(0.5, 0, 0.5, 0.3)
	if sprite != null:
		sprite.modulate = Color.PURPLE

## ========== 占领逻辑 ==========

## 完成占领
func _complete_capture() -> void:
	if _is_completed:
		return

	_is_completed = true

	# 发放占领奖励
	_grant_capture_bonus()

	# 更新视觉
	if area_sprite != null:
		area_sprite.modulate = Color.GOLD
	if sprite != null:
		sprite.modulate = Color.GOLD

	# 显示完成提示
	GameManager.reward_obtained.emit("撤离点占领成功！即将撤离...")

	# 延迟后切换场景（RestArea已有Player实例）
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/RestArea.tscn")

## 发放占领完成奖励
func _grant_capture_bonus() -> void:
	# 增加金币
	GameManager.add_coins(capture_bonus_coins)

## 更新视觉效果
func _update_visuals() -> void:
	# 更新进度条
	if progress_bar != null:
		progress_bar.value = _capture_progress

	# 更新精灵颜色（根据进度从紫色渐变到金色）
	var progress_ratio: float = _capture_progress / 100.0
	var base_color: Color = Color(0.5, 0, 0.5, 0.3)
	var target_color: Color = Color(1, 0.84, 0, 0.3)

	if area_sprite != null:
		area_sprite.modulate = base_color.lerp(target_color, progress_ratio)

	# 贴图标识从紫色渐变到金色（不透明）
	base_color = Color.PURPLE
	target_color = Color.GOLD
	if sprite != null:
		sprite.modulate = base_color.lerp(target_color, progress_ratio)

## ========== 信号回调 ==========

## 检测到碰撞体进入
func _on_body_entered(body: Node2D) -> void:
	# 检查碰撞体是否是玩家
	if body is Player:
		_player_inside = true

## 检测到碰撞体离开
func _on_body_exited(body: Node2D) -> void:
	# 检查碰撞体是否是玩家
	if body is Player:
		_player_inside = false

## ========== 公共方法 ==========

## 获取当前占领进度（0-100）
func get_capture_progress() -> int:
	return int(_capture_progress)

## 获取是否已完成占领
func is_completed() -> bool:
	return _is_completed

## 获取玩家是否在撤离点内
func is_player_inside() -> bool:
	return _player_inside
