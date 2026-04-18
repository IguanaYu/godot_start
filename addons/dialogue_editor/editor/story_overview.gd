@tool
extends VBoxContainer
## 剧情总览视图。显示所有对话图节点及其前置关系。

signal arc_saved()

const StoryArcScript := preload("res://scripts/story_arc/story_arc.gd")

var _overview_graph_edit: GraphEdit = null
var _sidebar: VBoxContainer = null
var _sidebar_scroll: ScrollContainer = null
var _arc_properties_panel: VBoxContainer = null
var _node_info_panel: VBoxContainer = null
var _arc_selector: OptionButton = null
var _status_label: Label = null

# 所有加载的对话图
var _all_graphs: Dictionary = {}  # graph_id -> DialogueGraph
# 所有加载的 StoryArc
var _all_arcs: Dictionary = {}  # arc_id -> StoryArc
# 当前选中的 arc_id（空=All Graphs）
var _current_arc_id: String = ""
# 节点映射 graph_id -> GraphNode
var _overview_nodes: Dictionary = {}
# 当前编辑的 StoryArc（如果有）
var _editing_arc = null  # StoryArc or null


func _ready() -> void:
	# 工具栏
	var toolbar := HBoxContainer.new()
	var btn_refresh := Button.new()
	btn_refresh.text = "Refresh"
	btn_refresh.pressed.connect(refresh_overview)
	toolbar.add_child(btn_refresh)
	var btn_new_arc := Button.new()
	btn_new_arc.text = "New Arc"
	btn_new_arc.pressed.connect(_on_new_arc)
	toolbar.add_child(btn_new_arc)
	var btn_save_arc := Button.new()
	btn_save_arc.text = "Save Arc"
	btn_save_arc.pressed.connect(_on_save_arc)
	toolbar.add_child(btn_save_arc)
	toolbar.add_child(VSeparator.new())
	var arc_label := Label.new()
	arc_label.text = " Arc: "
	toolbar.add_child(arc_label)
	_arc_selector = OptionButton.new()
	_arc_selector.add_item("All Graphs", 0)
	_arc_selector.item_selected.connect(_on_arc_selected)
	toolbar.add_child(_arc_selector)
	add_child(toolbar)

	# HSplitContainer
	var hsplit := HSplitContainer.new()
	hsplit.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# GraphEdit
	_overview_graph_edit = GraphEdit.new()
	_overview_graph_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_overview_graph_edit.minimap_enabled = true
	_overview_graph_edit.node_selected.connect(_on_overview_node_selected)
	_overview_graph_edit.node_deselected.connect(_on_overview_node_deselected)
	hsplit.add_child(_overview_graph_edit)

	# Sidebar
	_sidebar_scroll = ScrollContainer.new()
	_sidebar_scroll.custom_minimum_size = Vector2(280, 0)
	_sidebar_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_sidebar = VBoxContainer.new()
	_sidebar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sidebar_scroll.add_child(_sidebar)
	hsplit.add_child(_sidebar_scroll)
	add_child(hsplit)

	# 状态栏
	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 11)
	add_child(_status_label)

	_build_arc_properties_panel()
	_build_node_info_panel()
	_show_arc_properties()


func refresh_overview() -> void:
	_load_all_data()
	_rebuild_canvas()
	_rebuild_arc_selector()
	_update_status()


func _load_all_data() -> void:
	_all_graphs.clear()
	_all_arcs.clear()

	# 扫描对话图
	var dir := DirAccess.open("res://resources/dialogue/")
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var res = load("res://resources/dialogue/" + file_name)
				if res and res.get("graph_id") != null and res.graph_id != "":
					_all_graphs[res.graph_id] = res
			file_name = dir.get_next()
		dir.list_dir_end()

	# 扫描 StoryArc
	var arc_dir := DirAccess.open("res://resources/story_arcs/")
	if arc_dir:
		arc_dir.list_dir_begin()
		var fn := arc_dir.get_next()
		while fn != "":
			if fn.ends_with(".tres"):
				var res = load("res://resources/story_arcs/" + fn)
				if res and res.get("arc_id") != null and res.arc_id != "":
					_all_arcs[res.arc_id] = res
			fn = arc_dir.get_next()
		arc_dir.list_dir_end()


func _rebuild_arc_selector() -> void:
	_arc_selector.clear()
	_arc_selector.add_item("All Graphs", 0)
	var idx := 1
	for arc_id in _all_arcs:
		var arc = _all_arcs[arc_id]
		_arc_selector.add_item(arc.display_name if arc.display_name else arc.arc_id, idx)
		idx += 1
	if _current_arc_id != "":
		var target := _current_arc_id
		for i in _arc_selector.item_count:
			var id_text: String = _arc_selector.get_item_text(i)
			if id_text == target:
				_arc_selector.select(i)
				break


func _rebuild_canvas() -> void:
	# 清空
	for gid in _overview_nodes:
		var n: GraphNode = _overview_nodes[gid]
		if is_instance_valid(n):
			n.queue_free()
	_overview_nodes.clear()
	_overview_graph_edit.clear_connections()

	# 确定要显示的图
	var graphs_to_show: Dictionary = {}
	if _current_arc_id == "" or _current_arc_id == "All Graphs":
		graphs_to_show = _all_graphs.duplicate()
	else:
		var arc = _all_arcs.get(_current_arc_id)
		if arc:
			for gid in arc.graph_ids:
				if _all_graphs.has(gid):
					graphs_to_show[gid] = _all_graphs[gid]

	# 创建节点
	var pos_offset := Vector2(50, 50)
	var col := 0
	var row := 0
	var max_cols := 5
	for gid in graphs_to_show:
		var graph = graphs_to_show[gid]
		var node := GraphNode.new()
		node.title = graph.display_name if graph.display_name else gid
		node.name = gid

		# 位置
		var pos := Vector2.ZERO
		var arc = _all_arcs.get(_current_arc_id) if _current_arc_id != "" else null
		if arc and arc.editor_node_positions.has(gid):
			pos = arc.editor_node_positions[gid]
		else:
			pos = pos_offset + Vector2(col * 300, row * 200)
			col += 1
			if col >= max_cols:
				col = 0
				row += 1
		node.position_offset = pos
		node.selectable = true

		# 颜色：有前置=橙，无前置=绿
		var has_prereq := false
		if graph.get("prerequisite_graph_ids") != null:
			has_prereq = graph.prerequisite_graph_ids.size() > 0
		var color := Color(0.2, 0.7, 0.2) if not has_prereq else Color(1.0, 0.6, 0.2)
		var titlebar := StyleBoxFlat.new()
		titlebar.bg_color = color
		titlebar.corner_radius_top_left = 4
		titlebar.corner_radius_top_right = 4
		titlebar.content_margin_left = 8
		titlebar.content_margin_right = 8
		titlebar.content_margin_top = 4
		titlebar.content_margin_bottom = 4
		node.add_theme_stylebox_override("titlebar", titlebar)

		# 内容标签
		var id_label := Label.new()
		id_label.text = "ID: " + gid
		id_label.add_theme_font_size_override("font_size", 11)
		node.add_child(id_label)
		if graph.npc_id != "":
			var npc_label := Label.new()
			npc_label.text = "NPC: " + graph.npc_id
			npc_label.add_theme_font_size_override("font_size", 11)
			node.add_child(npc_label)

		# 端口
		node.set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)

		node.set_meta("graph_id", gid)
		_overview_graph_edit.add_child(node)
		_overview_nodes[gid] = node

	# 连线：根据 prerequisite_graph_ids
	for gid in graphs_to_show:
		var graph = graphs_to_show[gid]
		if graph.get("prerequisite_graph_ids") == null:
			continue
		for pre_gid in graph.prerequisite_graph_ids:
			if _overview_nodes.has(pre_gid):
				_overview_graph_edit.connect_node(
					StringName(pre_gid), 0,
					StringName(gid), 0)


func _on_arc_selected(index: int) -> void:
	if index == 0:
		_current_arc_id = ""
		_editing_arc = null
	else:
		var text: String = _arc_selector.get_item_text(index)
		_current_arc_id = text
		_editing_arc = _all_arcs.get(text)
	_rebuild_canvas()
	_show_arc_properties()
	_update_status()


func _on_overview_node_selected(node: Node) -> void:
	if node and node.has_meta("graph_id"):
		var gid: String = node.get_meta("graph_id")
		_show_node_info(gid)


func _on_overview_node_deselected(_node: Node) -> void:
	_show_arc_properties()


# ==================== Arc Properties Panel ====================

func _build_arc_properties_panel() -> void:
	_arc_properties_panel = VBoxContainer.new()
	_arc_properties_panel.name = "ArcPropertiesPanel"

	var title := Label.new()
	title.text = "Arc Properties"
	title.add_theme_font_size_override("font_size", 14)
	_arc_properties_panel.add_child(title)

	_add_arc_field("arc_id", "Arc ID")
	_add_arc_field("arc_name", "Display Name")
	_add_arc_desc_field()
	_add_arc_color_picker()
	_add_arc_graph_ids_editor()

	_sidebar.add_child(_arc_properties_panel)


func _add_arc_field(field_name: String, label_text: String) -> void:
	var hbox := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 100
	hbox.add_child(label)
	var line := LineEdit.new()
	line.name = field_name
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.text_changed.connect(func(v): _on_arc_field_changed(field_name, v))
	hbox.add_child(line)
	_arc_properties_panel.add_child(hbox)


func _add_arc_desc_field() -> void:
	var label := Label.new()
	label.text = "Description"
	_arc_properties_panel.add_child(label)
	var te := TextEdit.new()
	te.name = "arc_desc"
	te.custom_minimum_size.y = 50
	te.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	te.text_changed.connect(func(): _on_arc_field_changed("arc_desc", te.text))
	_arc_properties_panel.add_child(te)


func _add_arc_color_picker() -> void:
	var hbox := HBoxContainer.new()
	var label := Label.new()
	label.text = "Color"
	label.custom_minimum_size.x = 100
	hbox.add_child(label)
	var cp := ColorPickerButton.new()
	cp.name = "arc_color"
	cp.color = Color.WHITE
	cp.color_changed.connect(func(c): _on_arc_field_changed("arc_color", c))
	hbox.add_child(cp)
	_arc_properties_panel.add_child(hbox)


func _add_arc_graph_ids_editor() -> void:
	_arc_properties_panel.add_child(HSeparator.new())
	var label := Label.new()
	label.text = "Graph IDs (one per line)"
	_arc_properties_panel.add_child(label)
	var te := TextEdit.new()
	te.name = "arc_graph_ids"
	te.custom_minimum_size.y = 80
	te.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	te.text_changed.connect(func(): _on_arc_field_changed("arc_graph_ids", te.text))
	_arc_properties_panel.add_child(te)


func _on_arc_field_changed(field: String, value) -> void:
	if _editing_arc == null:
		return
	match field:
		"arc_id":
			_editing_arc.arc_id = value
		"arc_name":
			_editing_arc.display_name = value
		"arc_desc":
			_editing_arc.description = value
		"arc_color":
			_editing_arc.color = value
		"arc_graph_ids":
			var ids: Array = []
			for line in value.split("\n"):
				line = line.strip_edges()
				if line != "":
					ids.append(line)
			_editing_arc.graph_ids = ids


func _refresh_arc_properties() -> void:
	if _editing_arc == null:
		_set_arc_field("arc_id", "")
		_set_arc_field("arc_name", "")
		_set_arc_text("arc_desc", "")
		_set_arc_text("arc_graph_ids", "")
		return
	_set_arc_field("arc_id", _editing_arc.arc_id)
	_set_arc_field("arc_name", _editing_arc.display_name)
	_set_arc_text("arc_desc", _editing_arc.description)
	_set_arc_text("arc_graph_ids", "\n".join(_editing_arc.graph_ids))
	var cp: ColorPickerButton = _arc_properties_panel.get_node_or_null("arc_color")
	if cp:
		cp.color = _editing_arc.color


func _set_arc_field(name: String, text: String) -> void:
	var node: LineEdit = _arc_properties_panel.get_node_or_null(name)
	if node:
		node.text = text


func _set_arc_text(name: String, text: String) -> void:
	var node: TextEdit = _arc_properties_panel.get_node_or_null(name)
	if node:
		node.text = text


# ==================== Node Info Panel ====================

func _build_node_info_panel() -> void:
	_node_info_panel = VBoxContainer.new()
	_node_info_panel.name = "NodeInfoPanel"
	_node_info_panel.visible = false

	var title := Label.new()
	title.text = "Graph Info"
	title.add_theme_font_size_override("font_size", 14)
	_node_info_panel.add_child(title)

	var info_label := Label.new()
	info_label.name = "InfoLabel"
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_node_info_panel.add_child(info_label)

	_sidebar.add_child(_node_info_panel)


func _show_node_info(graph_id: String) -> void:
	_arc_properties_panel.visible = false
	_node_info_panel.visible = true

	var graph = _all_graphs.get(graph_id)
	var info: String = ""
	if graph == null:
		info = "Graph '%s' not found" % graph_id
	else:
		info += "ID: %s\n" % graph_id
		if graph.display_name:
			info += "Name: %s\n" % graph.display_name
		if graph.npc_id:
			info += "NPC: %s\n" % graph.npc_id
		info += "\n--- Prerequisites ---\n"
		if graph.get("prerequisite_graph_ids") != null and graph.prerequisite_graph_ids.size() > 0:
			info += "Graphs: %s\n" % ", ".join(graph.prerequisite_graph_ids)
		if graph.get("prerequisite_quest_ids") != null and graph.prerequisite_quest_ids.size() > 0:
			info += "Quests: %s\n" % ", ".join(graph.prerequisite_quest_ids)
		if graph.get("prerequisite_min_day") != null and graph.prerequisite_min_day > 0:
			info += "Min Day: %d\n" % graph.prerequisite_min_day
		if graph.get("prerequisite_min_exploration") != null and graph.prerequisite_min_exploration > 0.0:
			info += "Min Exploration: %.0f%%\n" % (graph.prerequisite_min_exploration * 100)
		if graph.get("prerequisite_flags") != null and graph.prerequisite_flags.size() > 0:
			info += "Flags: %s\n" % ", ".join(graph.prerequisite_flags)
		info += "\n--- Completion Effects ---\n"
		if graph.get("completion_flags_set") != null and graph.completion_flags_set.size() > 0:
			info += "Set Flags: %s\n" % ", ".join(graph.completion_flags_set)
		if graph.get("completion_quest_complete") != null and graph.completion_quest_complete.size() > 0:
			info += "Complete Quests: %s\n" % ", ".join(graph.completion_quest_complete)
		if graph.get("completion_unlock_graphs") != null and graph.completion_unlock_graphs.size() > 0:
			info += "Unlock Graphs: %s\n" % ", ".join(graph.completion_unlock_graphs)

	var label: Label = _node_info_panel.get_node_or_null("InfoLabel")
	if label:
		label.text = info


func _show_arc_properties() -> void:
	_arc_properties_panel.visible = true
	_node_info_panel.visible = false
	_refresh_arc_properties()


# ==================== Arc CRUD ====================

func _on_new_arc() -> void:
	var new_arc := StoryArcScript.new()
	new_arc.arc_id = "new_arc_" + str(Time.get_ticks_msec())
	new_arc.display_name = "New Story Arc"
	_all_arcs[new_arc.arc_id] = new_arc
	_editing_arc = new_arc
	_current_arc_id = new_arc.arc_id
	_rebuild_arc_selector()
	# select the new arc
	for i in _arc_selector.item_count:
		if _arc_selector.get_item_text(i) == new_arc.arc_id:
			_arc_selector.select(i)
			break
	_show_arc_properties()


func _on_save_arc() -> void:
	if _editing_arc == null:
		push_warning("Story Overview: No arc selected to save")
		return
	if _editing_arc.arc_id == "":
		push_warning("Story Overview: arc_id cannot be empty")
		return

	# 保存节点位置
	for gid in _overview_nodes:
		var node: GraphNode = _overview_nodes[gid]
		if is_instance_valid(node):
			_editing_arc.editor_node_positions[gid] = node.position_offset

	var path := "res://resources/story_arcs/" + _editing_arc.arc_id + ".tres"
	var err := ResourceSaver.save(_editing_arc, path)
	if err == OK:
		print("Story Overview: Saved arc to ", path)
	else:
		push_warning("Story Overview: Save failed, error %d" % err)


func _update_status() -> void:
	if _status_label == null:
		return
	var arc_text := _current_arc_id if _current_arc_id != "" else "All"
	_status_label.text = "Arc: %s | Graphs: %d | Loaded Arcs: %d" % [arc_text, _overview_nodes.size(), _all_arcs.size()]
