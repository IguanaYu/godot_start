## 休息区关卡脚本（RestAreaLevel.gd）
## 功能：管理休息区场景，包含商店和出口NPC
## 节点结构：Node2D (根节点)
##   ├── PlayerSpawn (玩家出生点)
##   ├── NPCsContainer (NPC容器)
##   ├── Background (背景)
##   └── LevelUI (CanvasLayer - 商店和背包UI)

extends "res://scripts/levels/BaseLevel.gd"

## ========== 可配置变量 ==========

## 背景颜色
@export var background_color: Color = Color(0.15, 0.1, 0.2, 1.0)
## 可选地图配置列表
@export var available_maps: Array[MapConfig] = []
## 防止重复触发返回主关卡
var _is_returning: bool = false

## ========== 节点引用 ==========

## NPC容器
@onready var npcs_container: Node2D = $NPCsContainer
## 背景节点
@onready var background: ColorRect = $Background
## 商店NPC
@onready var shop_npc: Node = $NPCsContainer/ShopNPC
## 地图选择NPC
@onready var map_select_npc: Node = $NPCsContainer/MapSelectNPC
## 出口NPC
@onready var level_exit_npc: Node = $NPCsContainer/LevelExitNPC
## 商店UI面板
@onready var shop_panel: Panel = $LevelUI/ShopPanel
## 地图选择UI面板
@onready var map_select_panel: Panel = $LevelUI/MapSelectPanel
## 剧情进度面板
@onready var story_progress_panel: Control = $LevelUI/StoryProgressPanel
## 剧情查看NPC（动态创建）
var story_viewer_npc: Node = null

## ========== 标准接口实现 ==========

## 获取玩家出生点
func get_player_spawn_point() -> Marker2D:
	return $PlayerSpawn

## 初始化关卡（由 GameRoot 调用）
func initialize_level(game_root: Node2D) -> void:
	# 设置玩家引用
	player = game_root.player

	# 设置背景颜色
	if background != null:
		background.color = background_color

	# 设置NPC
	_setup_npcs()

	# 隐藏UI面板
	if shop_panel != null:
		shop_panel.visible = false
	if map_select_panel != null:
		map_select_panel.visible = false

	# 创建剧情查看 NPC
	_setup_story_viewer()

	print("RestAreaLevel: 关卡初始化完成")

## ========== 设置NPC ==========

func _setup_npcs() -> void:
	# NPC已经通过场景放置，这里可以做一些初始化设置
	if shop_npc != null:
		shop_npc.shop_panel = shop_panel

	# 设置地图选择NPC
	if map_select_npc != null:
		# 加载默认地图配置
		if available_maps.is_empty():
			var forest_map = load("res://resources/spawn/configs/forest_map.tres") as MapConfig
			var river_map = load("res://resources/spawn/configs/river_map.tres") as MapConfig
			if forest_map != null:
				available_maps.append(forest_map)
			if river_map != null:
				available_maps.append(river_map)
		map_select_npc.available_maps = available_maps
		map_select_npc.set_panel(map_select_panel)
		if map_select_npc.has_signal("map_selected"):
			map_select_npc.map_selected.connect(_on_map_selected)

	if level_exit_npc != null:
		if level_exit_npc.has_signal("returned_to_main"):
			level_exit_npc.returned_to_main.connect(_on_returned_to_main)

## ========== 返回到主关卡 ==========

func _on_returned_to_main() -> void:
	if _is_returning:
		return
	_is_returning = true

	print("RestAreaLevel: 玩家与出口NPC交互，准备返回主关卡")

	# 应用永久性增益
	GameManager.apply_permanent_bonuses()

	# 推进天数
	GameManager.advance_day()

	# 设置地图配置（默认使用第一个可用地图）
	_select_default_map()

	# 通过 GameRoot 切换回主关卡
	var game_root = get_tree().current_scene
	if game_root and game_root.has_method("switch_to_main_level"):
		game_root.switch_to_main_level()
	else:
		push_error("RestAreaLevel: 无法获取 GameRoot 实例")

## 玩家通过地图选择NPC选择了一张地图
func _on_map_selected(map_config: MapConfig) -> void:
	if _is_returning:
		return
	_is_returning = true

	print("RestAreaLevel: 玩家选择了地图: %s" % map_config.map_name)

	# 应用永久性增益
	GameManager.apply_permanent_bonuses()

	# 推进天数
	GameManager.advance_day()

	# 设置玩家选择的地图
	GameManager.current_map_config = map_config

	# 通过 GameRoot 切换到选择的主关卡
	var game_root = get_tree().current_scene
	if game_root and game_root.has_method("switch_to_main_level"):
		game_root.switch_to_main_level()
	else:
		push_error("RestAreaLevel: 无法获取 GameRoot 实例")

## 选择默认地图（第一个已解锁的地图）
func _select_default_map() -> void:
	# 如果已有配置，保持不变
	if GameManager.current_map_config != null:
		return

	# 尝试加载默认地图配置列表
	if available_maps.is_empty():
		var forest_map = load("res://resources/spawn/configs/forest_map.tres") as MapConfig
		if forest_map != null:
			available_maps.append(forest_map)

	# 选择第一个已解锁的地图
	for map_config in available_maps:
		if GameManager.current_day_number >= map_config.min_unlock_day:
			GameManager.current_map_config = map_config
			print("[RestArea] 选择地图: %s" % map_config.map_name)
			return

	# fallback：使用第一个地图
	if not available_maps.is_empty():
		GameManager.current_map_config = available_maps[0]

## ========== UI 事件处理 ==========

## ========== 输入处理 ==========

func _input(event: InputEvent) -> void:
	# 按ESC键关闭所有UI
	if event.is_action_pressed("ui_cancel"):
		if story_progress_panel != null and story_progress_panel.visible:
			story_progress_panel.hide_panel()
		elif map_select_panel != null and map_select_panel.visible:
			map_select_panel.visible = false
		elif shop_panel != null and shop_panel.visible:
			shop_panel.visible = false

	# 处理玩家与出口NPC的交互（按E键）
	if event.is_action_pressed("interact"):
		_try_interact_with_exit_npc()

## ========== 处理与出口NPC的交互 ==========

## 尝试与出口NPC交互
func _try_interact_with_exit_npc() -> void:
	if level_exit_npc == null or player == null:
		return

	# 检查玩家与出口NPC的距离
	var distance = player.global_position.distance_to(level_exit_npc.global_position)
	if distance <= 80.0:  # 交互范围
		_on_returned_to_main()

## ========== 剧情查看 NPC ==========

func _setup_story_viewer() -> void:
	if story_progress_panel == null:
		return
	# 动态创建 NPC
	var npc_script = load("res://scripts/ui/StoryViewerNPC.gd")
	var npc := Area2D.new()
	npc.set_script(npc_script)
	npc.position = Vector2(150, 300)
	npc.collision_layer = 4
	npc.collision_mask = 0
	npc.name = "StoryViewerNPC"

	# Sprite2D
	var sprite := Sprite2D.new()
	sprite.modulate = Color(0.8, 0.6, 0.9, 1)
	var tex = load("res://kenney_desert-shooter-pack_1.0/kenney_desert-shooter-pack_1.0/PNG/Enemies/Tiles/tile_0009.png")
	if tex:
		sprite.texture = tex
	npc.add_child(sprite)

	# CollisionShape2D (body)
	var body_shape := CircleShape2D.new()
	body_shape.radius = 30.0
	var body_col := CollisionShape2D.new()
	body_col.shape = body_shape
	npc.add_child(body_col)

	# InteractionArea
	var inter_area := Area2D.new()
	var inter_shape := CircleShape2D.new()
	inter_shape.radius = 80.0
	var inter_col := CollisionShape2D.new()
	inter_col.shape = inter_shape
	inter_area.add_child(inter_col)
	npc.add_child(inter_area)

	npc.set("prompt_text", "查看剧情进度")
	npc.set_panel(story_progress_panel)

	npcs_container.add_child(npc)
	story_viewer_npc = npc
	story_progress_panel.closed.connect(_on_story_panel_closed)


func _on_story_panel_closed() -> void:
	pass


## ========== 清理 ==========

func _exit_tree() -> void:
	# 断开信号连接
	if level_exit_npc != null and level_exit_npc.has_signal("returned_to_main"):
		if level_exit_npc.returned_to_main.is_connected(_on_returned_to_main):
			level_exit_npc.returned_to_main.disconnect(_on_returned_to_main)
