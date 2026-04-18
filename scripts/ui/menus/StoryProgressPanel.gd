extends Control
## 游戏内剧情进度面板。显示支线列表和对话图状态。

signal closed()

var _arc_buttons: VBoxContainer = null
var _detail_panel: VBoxContainer = null
var _arc_title_label: Label = null
var _arc_desc_label: Label = null
var _dialogue_list: VBoxContainer = null
var _info_label: Label = null
var _current_arc_id: String = ""


func _ready() -> void:
	# Overlay
	var overlay := ColorRect.new()
	overlay.name = "Overlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			hide_panel()
	)
	add_child(overlay)

	# MainPanel
	var main_panel := PanelContainer.new()
	main_panel.name = "MainPanel"
	main_panel.set_anchors_preset(Control.PRESET_CENTER)
	main_panel.offset_left = -450
	main_panel.offset_top = -300
	main_panel.offset_right = 450
	main_panel.offset_bottom = 300
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.corner_radius_bottom_left = 10
	main_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(main_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_child(vbox)

	# Header
	var header := HBoxContainer.new()
	_arc_title_label = Label.new()
	_arc_title_label.text = "剧情进度"
	_arc_title_label.add_theme_font_size_override("font_size", 28)
	_arc_title_label.add_theme_color_override("font_color", Color(1, 0.84, 0, 1))
	header.add_child(_arc_title_label)
	header.add_child(HSeparator.new())
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(hide_panel)
	header.add_child(close_btn)
	vbox.add_child(header)
	vbox.add_child(HSeparator.new())

	# Content HSplitContainer
	var content := HSplitContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 15)

	# 左侧支线列表
	var arc_panel := VBoxContainer.new()
	arc_panel.custom_minimum_size = Vector2(200, 0)
	var arc_title := Label.new()
	arc_title.text = "支线列表"
	arc_title.add_theme_font_size_override("font_size", 16)
	arc_panel.add_child(arc_title)
	var arc_scroll := ScrollContainer.new()
	arc_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	arc_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_arc_buttons = VBoxContainer.new()
	_arc_buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arc_scroll.add_child(_arc_buttons)
	arc_panel.add_child(arc_scroll)
	content.add_child(arc_panel)

	# 右侧详情
	_detail_panel = VBoxContainer.new()
	_detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_arc_desc_label = Label.new()
	_arc_desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_arc_desc_label.add_theme_font_size_override("font_size", 13)
	_detail_panel.add_child(_arc_desc_label)
	_detail_panel.add_child(HSeparator.new())

	var list_scroll := ScrollContainer.new()
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_dialogue_list = VBoxContainer.new()
	_dialogue_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dialogue_list.add_theme_constant_override("separation", 6)
	list_scroll.add_child(_dialogue_list)
	_detail_panel.add_child(list_scroll)

	_detail_panel.add_child(HSeparator.new())
	_info_label = Label.new()
	_info_label.add_theme_font_size_override("font_size", 13)
	_info_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	_detail_panel.add_child(_info_label)

	content.add_child(_detail_panel)
	vbox.add_child(content)

	# BackButton
	var back_btn := Button.new()
	back_btn.text = "返回"
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.pressed.connect(hide_panel)
	vbox.add_child(back_btn)


func show_panel() -> void:
	visible = true
	_build_arc_list()
	_show_all_dialogues()


func hide_panel() -> void:
	visible = false
	closed.emit()


func _build_arc_list() -> void:
	for child in _arc_buttons.get_children():
		child.queue_free()

	# "全部对话" 按钮
	var all_btn := Button.new()
	all_btn.text = "全部对话"
	all_btn.pressed.connect(_show_all_dialogues)
	_arc_buttons.add_child(all_btn)

	if DialogueManager == null:
		return
	var arcs: Array = DialogueManager.get_story_arcs()
	for arc in arcs:
		var btn := Button.new()
		var completed := 0
		for gid in arc.graph_ids:
			if DialogueManager.is_graph_completed(gid):
				completed += 1
		var name_text := arc.display_name if arc.display_name else arc.arc_id
		btn.text = "%s (%d/%d)" % [name_text, completed, arc.graph_ids.size()]
		btn.pressed.connect(_show_arc_detail.bind(arc))
		_arc_buttons.add_child(btn)


func _show_all_dialogues() -> void:
	_current_arc_id = ""
	_arc_desc_label.text = ""
	_dialogue_list_clear()
	if DialogueManager == null:
		return
	var all_ids: Array = DialogueManager.get_all_graph_ids()
	# 按 StoryArc 分组显示
	for gid in all_ids:
		_add_dialogue_row(gid)
	_update_info()


func _show_arc_detail(arc) -> void:
	_current_arc_id = arc.arc_id
	_arc_desc_label.text = arc.description if arc.description else ""
	_dialogue_list_clear()
	for gid in arc.graph_ids:
		_add_dialogue_row(gid)
	_update_info()


func _dialogue_list_clear() -> void:
	for child in _dialogue_list.get_children():
		child.queue_free()


func _add_dialogue_row(graph_id: String) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	var status_icon := Label.new()
	var display_name: String = DialogueManager.get_graph_display_name(graph_id)

	var is_completed := DialogueManager.is_graph_completed(graph_id)
	var is_unlocked := DialogueManager.is_graph_unlocked(graph_id)

	if is_completed:
		status_icon.text = "[v]"
		status_icon.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
	elif is_unlocked:
		status_icon.text = "[o]"
		status_icon.add_theme_color_override("font_color", Color(0.3, 0.6, 1.0))
	else:
		status_icon.text = "[x]"
		status_icon.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))

	status_icon.add_theme_font_size_override("font_size", 14)
	hbox.add_child(status_icon)

	var name_label := Label.new()
	name_label.text = display_name
	name_label.add_theme_font_size_override("font_size", 14)
	hbox.add_child(name_label)

	# 锁定原因
	if not is_unlocked and not is_completed:
		var reasons: Dictionary = DialogueManager.get_graph_lock_reasons(graph_id)
		var reason_parts: Array = []
		if reasons.get("missing_graphs", []).size() > 0:
			reason_parts.append("需完成: " + ", ".join(reasons["missing_graphs"]))
		if reasons.get("missing_quests", []).size() > 0:
			reason_parts.append("需任务: " + ", ".join(reasons["missing_quests"]))
		if reasons.get("need_day", 0) > 0:
			reason_parts.append("需天数 ≥ %d (当前 %d)" % [reasons["need_day"], reasons.get("current_day", 0)])
		if reasons.get("need_exploration", 0.0) > 0.0:
			reason_parts.append("需探索 ≥ %.0f%% (当前 %.0f%%)" % [reasons["need_exploration"] * 100, reasons.get("current_exploration", 0.0) * 100])
		if reasons.get("missing_flags", []).size() > 0:
			reason_parts.append("需标记: " + ", ".join(reasons["missing_flags"]))
		if reason_parts.size() > 0:
			var reason_label := Label.new()
			reason_label.text = "  (" + "; ".join(reason_parts) + ")"
			reason_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			reason_label.add_theme_font_size_override("font_size", 11)
			reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			reason_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.add_child(reason_label)

	_dialogue_list.add_child(hbox)


func _update_info() -> void:
	if _info_label == null:
		return
	var info_text := ""
	if ExplorationProgress:
		var exp_val := ExplorationProgress.get_exploration_value()
		info_text += "探索进度: %.0f%%" % (exp_val * 100)
	if GameManager:
		if info_text != "":
			info_text += "  |  "
		info_text += "天数: %d" % GameManager.current_day_number
	_info_label.text = info_text
