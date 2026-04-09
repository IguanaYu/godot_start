## 角色选择场景脚本
extends Control

## ========== 私有变量 ==========

## 可选角色数据列表
var _character_data_list: Array = []
## 当前选中的角色数据
var _selected_character: Resource = null

## ========== 节点引用 ==========

## 角色卡片容器
@onready var character_container: HBoxContainer = $VBoxContainer/CharacterContainer
## 开始游戏按钮
@onready var start_button: Button = $ButtonContainer/StartGameButton
## 返回按钮
@onready var back_button: Button = $ButtonContainer/BackButton
## 选中标签
@onready var selected_label: Label = $VBoxContainer/SelectedCharacterPanel/SelectedVBox/SelectedLabel
## 预览精灵
@onready var preview_sprite: TextureRect = $VBoxContainer/SelectedCharacterPanel/SelectedVBox/PreviewSprite
## 属性标签
@onready var stats_label: Label = $VBoxContainer/SelectedCharacterPanel/SelectedVBox/StatsLabel
## 描述标签
@onready var description_label: Label = $VBoxContainer/SelectedCharacterPanel/SelectedVBox/DescriptionLabel

## ========== Godot生命周期 ==========

func _ready() -> void:
	# 加载角色数据
	_load_character_data()

	# 创建角色卡片UI
	_create_character_cards()

	# 连接按钮信号
	start_button.pressed.connect(_on_start_button_pressed)
	back_button.pressed.connect(_on_back_button_pressed)

## ========== 数据加载 ==========

## 加载所有角色数据资源
func _load_character_data() -> void:
	var character_paths = [
		"res://resources/characters/warrior.tres",
		"res://resources/characters/tank.tres",
		"res://resources/characters/speedster.tres"
	]

	for path in character_paths:
		var char_data = load(path)
		if char_data != null and char_data.is_valid():
			_character_data_list.append(char_data)
		else:
			push_warning("Failed to load character data: %s" % path)

## ========== UI创建 ==========

## 创建角色卡片UI
func _create_character_cards() -> void:
	for i in range(_character_data_list.size()):
		var char_data = _character_data_list[i]
		var card: Panel = _create_character_card(char_data, i)
		character_container.add_child(card)

## 创建单个角色卡片
func _create_character_card(char_data, index: int) -> Panel:
	var card: Panel = Panel.new()
	card.custom_minimum_size = Vector2(200, 350)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE)
	vbox.add_theme_constant_override("separation", 10)
	card.add_child(vbox)

	# 角色精灵（从SpriteFrames中获取idle动画的第一帧）
	var sprite: TextureRect = TextureRect.new()
	sprite.custom_minimum_size = Vector2(150, 150)
	sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	if char_data.sprite_frames != null and char_data.sprite_frames.has_animation("idle"):
		var idle_frames = char_data.sprite_frames.get_frame_count("idle")
		if idle_frames > 0:
			sprite.texture = char_data.sprite_frames.get_frame_texture("idle", 0)
	vbox.add_child(sprite)

	# 角色名称
	var name_label: Label = Label.new()
	name_label.text = char_data.character_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_label)

	# 选择按钮
	var select_btn: Button = Button.new()
	select_btn.text = "选择"
	select_btn.custom_minimum_size = Vector2(0, 40)
	select_btn.pressed.connect(_on_select_button_pressed.bind(char_data, card))
	vbox.add_child(select_btn)

	# 属性面板（初始隐藏）
	var stats_panel: VBoxContainer = _create_stats_panel(char_data)
	stats_panel.name = "StatsPanel"
	stats_panel.visible = false
	vbox.add_child(stats_panel)

	return card

## 创建属性面板
func _create_stats_panel(char_data) -> VBoxContainer:
	var panel: VBoxContainer = VBoxContainer.new()
	panel.add_theme_constant_override("separation", 5)

	var hp_label: Label = Label.new()
	hp_label.text = "生命值: %d/%d" % [char_data.get_initial_health(), char_data.max_health]
	hp_label.add_theme_font_size_override("font_size", 16)
	panel.add_child(hp_label)

	var speed_label: Label = Label.new()
	speed_label.text = "速度: %.0f" % char_data.speed
	speed_label.add_theme_font_size_override("font_size", 16)
	panel.add_child(speed_label)

	var desc_label: Label = Label.new()
	desc_label.text = char_data.description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(180, 0)
	panel.add_child(desc_label)

	return panel

## ========== 事件处理 ==========

## 选择按钮被点击
func _on_select_button_pressed(char_data, card: Panel) -> void:
	_selected_character = char_data

	# 隐藏所有卡片的属性面板
	for c in character_container.get_children():
		if c is Panel:
			var stats: VBoxContainer = c.get_node_or_null("VBoxContainer/StatsPanel")
			if stats != null:
				stats.visible = false

	# 显示当前卡片的属性面板
	var stats: VBoxContainer = card.get_node_or_null("VBoxContainer/StatsPanel")
	if stats != null:
		stats.visible = true

	# 更新选中角色详情
	_update_selected_panel(char_data)

	# 启用开始按钮
	start_button.disabled = false

## 更新选中角色详情面板
func _update_selected_panel(char_data) -> void:
	selected_label.text = "已选择: " + char_data.character_name
	if char_data.sprite_frames != null and char_data.sprite_frames.has_animation("idle"):
		var idle_frames = char_data.sprite_frames.get_frame_count("idle")
		if idle_frames > 0:
			preview_sprite.texture = char_data.sprite_frames.get_frame_texture("idle", 0)
	stats_label.text = "生命: %d/%d  |  速度: %.0f" % [
		char_data.get_initial_health(), char_data.max_health, char_data.speed
	]
	description_label.text = char_data.description

## 开始游戏按钮被点击
func _on_start_button_pressed() -> void:
	if _selected_character == null:
		return

	# 检查GameManager是否可用
	if GameManager == null:
		push_error("GameManager is not available!")
		return

	# 将选中角色数据保存到GameManager
	GameManager.selected_character_data = _selected_character

	# 切换到 GameRoot 场景（包含常驻 Player）
	get_tree().change_scene_to_file("res://scenes/GameRoot.tscn")

## 返回按钮被点击
func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menus/StartScreen.tscn")
