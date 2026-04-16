## 玩家属性面板（PlayerStatsPanel.gd）
## 功能：按 Tab 键打开，显示角色属性、加成效果、能力、增益，支持背包页签和滚轮滚动
extends Control

## ========== 状态 ==========
var _is_open := false
var _current_tab := 0  # 0=属性, 1=背包

## ========== UI引用 ==========
var _overlay: ColorRect
var _panel: PanelContainer
var _title_label: Label
var _close_btn: Button
var _scroll: ScrollContainer
var _stats_page: VBoxContainer
var _inventory_page: VBoxContainer
var _tab_stats_btn: Button
var _tab_inventory_btn: Button

# 属性标签引用（用于动态更新）
var _hp_bar: ProgressBar
var _hp_label: Label
var _speed_label: Label
var _accel_label: Label
var _friction_label: Label
var _coins_label: Label
var _coin_rate_label: Label
var _diamond_rate_label: Label
var _enemy_rate_label: Label
var _red_keys_label: Label
var _abilities_box: VBoxContainer
var _buffs_box: VBoxContainer
var _inventory_box: VBoxContainer

## ========== 生命周期 ==========

func _ready() -> void:
	visible = false
	_build_ui()

	GameManager.coins_changed.connect(func(_v): if _is_open: _refresh_stats())
	GameManager.health_changed.connect(func(_v): if _is_open: _refresh_stats())
	GameManager.inventory_changed.connect(func(): if _is_open: _refresh_inventory())

func _input(event: InputEvent) -> void:
	if not _is_open:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_Q, KEY_1:
				_switch_tab(0)
				accept_event()
			KEY_E, KEY_2:
				_switch_tab(1)
				accept_event()

## ========== 公共方法 ==========

func is_open() -> bool:
	return _is_open

func toggle() -> void:
	if _is_open:
		close()
	else:
		open()

func open() -> void:
	_is_open = true
	visible = true
	_refresh_all()
	_scroll.scroll_vertical = 0
	# 打开动画
	_panel.pivot_offset = _panel.size / 2.0
	_panel.scale = Vector2(0.95, 0.95)
	var t := create_tween()
	t.tween_property(_panel, "scale", Vector2.ONE, 0.12).set_ease(Tween.EASE_OUT)
	get_tree().paused = true

func close() -> void:
	_is_open = false
	# 关闭动画
	_panel.pivot_offset = _panel.size / 2.0
	var t := create_tween()
	t.tween_property(_panel, "scale", Vector2(0.95, 0.95), 0.08)
	t.parallel().tween_property(self, ^"modulate:a", 0.0, 0.08)
	t.tween_callback(func():
		visible = false
		modulate.a = 1.0
		_panel.scale = Vector2.ONE
		get_tree().paused = false
	)

## ========== 页签切换 ==========

func _switch_tab(tab: int) -> void:
	if _current_tab == tab:
		return
	_current_tab = tab
	_stats_page.visible = (tab == 0)
	_inventory_page.visible = (tab == 1)
	_scroll.scroll_vertical = 0
	_update_tab_style()
	if tab == 1:
		_refresh_inventory()

func _update_tab_style() -> void:
	var active_color := Color(0.4, 0.65, 0.95)
	var inactive_color := Color(0.5, 0.5, 0.5)
	_tab_stats_btn.add_theme_color_override("font_color", active_color if _current_tab == 0 else inactive_color)
	_tab_inventory_btn.add_theme_color_override("font_color", active_color if _current_tab == 1 else inactive_color)

## ========== 事件回调 ==========

func _on_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()

func _on_close_pressed() -> void:
	close()

func _on_tab_stats_pressed() -> void:
	_switch_tab(0)

func _on_tab_inventory_pressed() -> void:
	_switch_tab(1)

## ========== UI构建 ==========

func _build_ui() -> void:
	# 全屏控制节点
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# 1. 半透明遮罩
	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0, 0, 0, 0.4)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.gui_input.connect(_on_overlay_input)
	add_child(_overlay)

	# 2. 主面板（居中，占屏幕30%宽x60%高）
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.35
	_panel.anchor_top = 0.18
	_panel.anchor_right = 0.65
	_panel.anchor_bottom = 0.82
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	panel_style.border_color = Color(0.35, 0.35, 0.45, 0.5)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(8)
	_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_panel)

	# 3. 内边距
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	_panel.add_child(margin)

	# 4. 主垂直布局
	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 6)
	margin.add_child(main_vbox)

	# 5. 标题栏
	_build_title_bar(main_vbox)

	# 6. 分隔线
	main_vbox.add_child(HSeparator.new())

	# 7. 滚动内容区
	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(_scroll)

	var content_wrapper := VBoxContainer.new()
	_scroll.add_child(content_wrapper)

	# 属性页
	_stats_page = VBoxContainer.new()
	_stats_page.add_theme_constant_override("separation", 8)
	content_wrapper.add_child(_stats_page)
	_build_stats_page()

	# 背包页
	_inventory_page = VBoxContainer.new()
	_inventory_page.add_theme_constant_override("separation", 4)
	_inventory_page.visible = false
	content_wrapper.add_child(_inventory_page)
	_build_inventory_page()

	# 8. 分隔线
	main_vbox.add_child(HSeparator.new())

	# 9. 页签栏
	_build_tab_bar(main_vbox)

func _build_title_bar(parent: VBoxContainer) -> void:
	var hbox := HBoxContainer.new()
	parent.add_child(hbox)

	_title_label = Label.new()
	_title_label.text = "角色"
	_title_label.add_theme_font_size_override("font_size", 16)
	_title_label.add_theme_color_override("font_color", Color.WHITE)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(_title_label)

	_close_btn = Button.new()
	_close_btn.text = "x"
	_close_btn.flat = true
	_close_btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_close_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	_close_btn.add_theme_font_size_override("font_size", 14)
	_close_btn.custom_minimum_size.x = 24
	_close_btn.pressed.connect(_on_close_pressed)
	hbox.add_child(_close_btn)

func _build_tab_bar(parent: VBoxContainer) -> void:
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)
	parent.add_child(hbox)

	_tab_stats_btn = Button.new()
	_tab_stats_btn.text = "属性"
	_tab_stats_btn.flat = true
	_tab_stats_btn.add_theme_font_size_override("font_size", 14)
	_tab_stats_btn.pressed.connect(_on_tab_stats_pressed)
	hbox.add_child(_tab_stats_btn)

	_tab_inventory_btn = Button.new()
	_tab_inventory_btn.text = "背包"
	_tab_inventory_btn.flat = true
	_tab_inventory_btn.add_theme_font_size_override("font_size", 14)
	_tab_inventory_btn.pressed.connect(_on_tab_inventory_pressed)
	hbox.add_child(_tab_inventory_btn)

	_update_tab_style()

func _build_stats_page() -> void:
	# === 基础属性区 ===
	_stats_page.add_child(_make_section_header("基础属性"))

	# 生命值（进度条 + 数字）
	var hp_box := HBoxContainer.new()
	var hp_name := _make_label("生命值", Color(0.7, 0.7, 0.7))
	hp_name.custom_minimum_size.x = 65
	hp_box.add_child(hp_name)

	_hp_bar = ProgressBar.new()
	_hp_bar.show_percentage = false
	_hp_bar.custom_minimum_size.x = 80
	_hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var hp_bg := StyleBoxFlat.new()
	hp_bg.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	hp_bg.set_corner_radius_all(3)
	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.2, 0.8, 0.2, 1.0)
	hp_fill.set_corner_radius_all(3)
	_hp_bar.add_theme_stylebox_override("background", hp_bg)
	_hp_bar.add_theme_stylebox_override("fill", hp_fill)
	hp_box.add_child(_hp_bar)

	_hp_label = _make_label("3/3", Color.WHITE)
	hp_box.add_child(_hp_label)
	_stats_page.add_child(hp_box)

	# 移动速度、加速度、摩擦力
	_speed_label = _add_stat_row(_stats_page, "移动速度", "200")
	_accel_label = _add_stat_row(_stats_page, "加速度", "1000")
	_friction_label = _add_stat_row(_stats_page, "摩擦力", "1500")

	# === 加成效果区 ===
	_stats_page.add_child(_make_section_header("加成效果"))
	_coins_label = _add_stat_row(_stats_page, "金币", "0")
	_coin_rate_label = _add_stat_row(_stats_page, "金币产出", "+0%")
	_diamond_rate_label = _add_stat_row(_stats_page, "钻石产出", "+0%")
	_enemy_rate_label = _add_stat_row(_stats_page, "敌人频率", "+0%")
	_red_keys_label = _add_stat_row(_stats_page, "红钥匙", "0")

	# === 角色能力区 ===
	_stats_page.add_child(_make_section_header("角色能力"))
	_abilities_box = VBoxContainer.new()
	_abilities_box.add_theme_constant_override("separation", 4)
	_stats_page.add_child(_abilities_box)

	# === 当前增益区 ===
	_stats_page.add_child(_make_section_header("当前增益"))
	_buffs_box = VBoxContainer.new()
	_buffs_box.add_theme_constant_override("separation", 2)
	_stats_page.add_child(_buffs_box)

func _build_inventory_page() -> void:
	_inventory_box = VBoxContainer.new()
	_inventory_box.add_theme_constant_override("separation", 6)
	_inventory_page.add_child(_inventory_box)

## ========== 数据刷新 ==========

func _refresh_all() -> void:
	_refresh_stats()
	if _current_tab == 1:
		_refresh_inventory()

func _refresh_stats() -> void:
	var player_node = GameManager.player
	var char_data = GameManager.selected_character_data

	# 角色名
	if char_data != null and char_data.get("character_name") != null:
		_title_label.text = char_data.character_name
	else:
		_title_label.text = "角色"

	# 生命值
	var health := GameManager.get_health()
	var max_hp := GameManager.max_health
	_hp_bar.max_value = float(max_hp)
	_hp_bar.value = float(health)
	_hp_label.text = "%d/%d" % [health, max_hp]

	# 移动属性
	if player_node != null and is_instance_valid(player_node):
		var speed: float = player_node.base_speed
		var bonus_pct: float = GameManager.speed_boost_percent
		var speed_text := "%.0f" % speed
		if bonus_pct > 0:
			speed_text += " (+%.0f%%)" % bonus_pct
		if player_node._speed_multiplier > 1.0:
			speed_text += " x%.1f" % player_node._speed_multiplier
		_speed_label.text = speed_text
		_accel_label.text = "%.0f" % player_node.acceleration
		_friction_label.text = "%.0f" % player_node.friction

	# 加成效果
	_coins_label.text = "%d" % GameManager.get_coins()
	_set_bonus_label(_coin_rate_label, GameManager.coin_spawn_rate_bonus)
	_set_bonus_label(_diamond_rate_label, GameManager.diamond_spawn_rate_bonus)
	_set_bonus_label(_enemy_rate_label, GameManager.enemy_spawn_rate_penalty)
	_red_keys_label.text = "%d" % GameManager.red_keys_collected

	# 角色能力
	_refresh_abilities(char_data)

	# 当前增益
	_refresh_buffs(player_node)

func _set_bonus_label(label: Label, value: float) -> void:
	if value > 0:
		label.text = "+%.0f%%" % value
		label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	elif value < 0:
		label.text = "%.0f%%" % value
		label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	else:
		label.text = "+0%"
		label.add_theme_color_override("font_color", Color.WHITE)

func _refresh_abilities(char_data) -> void:
	for child in _abilities_box.get_children():
		child.queue_free()

	if char_data == null or not char_data.has_method("get_enabled_abilities"):
		_abilities_box.add_child(_make_label("  无", Color(0.5, 0.5, 0.5)))
		return

	var abilities = char_data.get_enabled_abilities()
	if abilities.is_empty():
		_abilities_box.add_child(_make_label("  无", Color(0.5, 0.5, 0.5)))
		return

	for ability in abilities:
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 1)

		var name_lbl := _make_label("  * " + ability.ability_name, Color(0.9, 0.8, 0.3))
		name_lbl.add_theme_font_size_override("font_size", 12)
		box.add_child(name_lbl)

		if ability.ability_description != "":
			var desc_lbl := _make_label("    " + ability.ability_description, Color(0.6, 0.6, 0.6))
			desc_lbl.add_theme_font_size_override("font_size", 11)
			box.add_child(desc_lbl)

		_abilities_box.add_child(box)

func _refresh_buffs(player_node) -> void:
	for child in _buffs_box.get_children():
		child.queue_free()

	if player_node == null or not is_instance_valid(player_node):
		_buffs_box.add_child(_make_label("  当前无活跃增益", Color(0.5, 0.5, 0.5)))
		return

	var buffs: Dictionary = player_node._buff_timers
	if buffs.is_empty():
		_buffs_box.add_child(_make_label("  当前无活跃增益", Color(0.5, 0.5, 0.5)))
		return

	for buff_name in buffs:
		var time_left: float = buffs[buff_name]
		var display_name := _buff_display_name(str(buff_name))
		var color := Color(0.3, 0.9, 0.3) if str(buff_name) == "speed_boost" else Color(0.9, 0.8, 0.2)
		_buffs_box.add_child(_make_label("  > %s  %.1fs" % [display_name, time_left], color))

func _refresh_inventory() -> void:
	for child in _inventory_box.get_children():
		child.queue_free()

	var items = GameManager.get_inventory_items()
	if items.is_empty():
		_inventory_box.add_child(_make_label("  背包为空", Color(0.5, 0.5, 0.5)))
		return

	for item in items:
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 1)

		var item_name = "未知物品"
		if item and item.get("item_name") != null:
			item_name = item.item_name

		var name_lbl := _make_label("  - " + item_name, Color.WHITE)
		name_lbl.add_theme_font_size_override("font_size", 12)
		box.add_child(name_lbl)

		if item and item.get("item_description") != null and item.item_description != "":
			var desc_lbl := _make_label("    " + item.item_description, Color(0.6, 0.6, 0.6))
			desc_lbl.add_theme_font_size_override("font_size", 11)
			box.add_child(desc_lbl)

		_inventory_box.add_child(box)

## ========== 辅助方法 ==========

func _make_label(text: String, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 12)
	return lbl

func _add_stat_row(parent: VBoxContainer, name_text: String, default_value: String) -> Label:
	var hbox := HBoxContainer.new()
	var name_lbl := _make_label(name_text, Color(0.7, 0.7, 0.7))
	name_lbl.custom_minimum_size.x = 65
	hbox.add_child(name_lbl)
	var value_lbl := _make_label(default_value, Color.WHITE)
	hbox.add_child(value_lbl)
	parent.add_child(hbox)
	return value_lbl

func _make_section_header(text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.9, 0.9, 0.9, 0.08)
	style.set_corner_radius_all(3)
	panel.add_theme_stylebox_override("panel", style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_bottom", 3)
	panel.add_child(margin)

	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	margin.add_child(lbl)

	return panel

func _buff_display_name(buff_name: String) -> String:
	match buff_name:
		"speed_boost": return "加速"
		"star_invincibility": return "无敌星"
		_: return buff_name
