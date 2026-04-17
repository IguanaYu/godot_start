@tool
extends VBoxContainer
## 对话图可视化编辑器主面板

const PropertyPanelScript := preload("res://addons/dialogue_editor/editor/property_panel.gd")
const GraphSerializerScript := preload("res://addons/dialogue_editor/editor/graph_serializer.gd")

@onready var graph_edit: GraphEdit = $HSplitContainer/GraphEdit
@onready var sidebar: VBoxContainer = $HSplitContainer/Sidebar

# 属性面板
var _property_panel: VBoxContainer = null
# 图属性面板（未选中节点时显示）
var _graph_panel: VBoxContainer = null

# 当前编辑的对话图数据
var _graph: DialogueGraph = null
# 节点映射: node_id -> GraphNode
var _nodes: Dictionary = {}
# 连接列表
var _connections: Array = []
# 图元数据
var _graph_meta: Dictionary = {}
# 是否有未保存更改
var _dirty: bool = false
# 当前选中的节点ID
var _selected_node_id: String = ""
# 文件对话框
var _file_dialog: FileDialog = null


func _ready() -> void:
	_connect_toolbar()
	if graph_edit:
		graph_edit.connection_request.connect(_on_connection_request)
		graph_edit.disconnection_request.connect(_on_disconnection_request)
		graph_edit.node_selected.connect(_on_node_selected)
		graph_edit.node_deselected.connect(_on_node_deselected)

	# 创建属性面板
	_property_panel = VBoxContainer.new()
	_property_panel.set_script(PropertyPanelScript)
	_property_panel.node_data_changed.connect(_on_node_data_changed)
	_property_panel.visible = false
	sidebar.add_child(_property_panel)

	# 创建图属性面板
	_build_graph_panel()

	# 创建文件对话框
	_file_dialog = FileDialog.new()
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.filters = PackedStringArray(["*.tres"])
	_file_dialog.file_selected.connect(_on_file_selected)
	add_child(_file_dialog)

	_new_graph()


func _connect_toolbar() -> void:
	$Toolbar/BtnNew.pressed.connect(_on_new)
	$Toolbar/BtnSave.pressed.connect(_on_save)
	$Toolbar/BtnLoad.pressed.connect(_on_load)
	$Toolbar/BtnAddStart.pressed.connect(_on_add_node.bind(0))
	$Toolbar/BtnAddDialogue.pressed.connect(_on_add_node.bind(1))
	$Toolbar/BtnAddChoice.pressed.connect(_on_add_node.bind(2))
	$Toolbar/BtnAddCondition.pressed.connect(_on_add_node.bind(3))
	$Toolbar/BtnAddAction.pressed.connect(_on_add_node.bind(4))
	$Toolbar/BtnAddSub.pressed.connect(_on_add_node.bind(5))
	$Toolbar/BtnAddEnd.pressed.connect(_on_add_node.bind(6))


# ==================== 工具栏操作 ====================

func _on_new() -> void:
	_new_graph()


func _new_graph() -> void:
	_clear_canvas()
	_graph = DialogueGraph.new()
	_graph_meta = {
		"priority": 0,
		"repeatable": false,
		"prerequisite_graph_ids": [],
		"prerequisite_quest_ids": [],
		"prerequisite_min_day": 0,
		"prerequisite_min_exploration": 0.0,
		"prerequisite_flags": [],
		"prerequisite_logic": "AND",
		"completion_flags_set": [],
		"completion_quest_complete": [],
		"completion_unlock_graphs": [],
		"editor_scroll_offset": Vector2.ZERO,
		"editor_zoom": 1.0,
	}
	_dirty = false
	_selected_node_id = ""
	_show_graph_panel()
	_refresh_graph_panel()


func _on_save() -> void:
	# 检查 graph_id
	if _graph.graph_id == "":
		push_warning("Dialogue Editor: graph_id 不能为空，请在右侧面板填写")
		return

	# 同步图属性
	_graph.priority = _graph_meta.get("priority", 0)
	_graph.repeatable = _graph_meta.get("repeatable", false)
	_graph.prerequisite_graph_ids.assign(_graph_meta.get("prerequisite_graph_ids", []))
	_graph.prerequisite_quest_ids.assign(_graph_meta.get("prerequisite_quest_ids", []))
	_graph.prerequisite_min_day = _graph_meta.get("prerequisite_min_day", 0)
	_graph.prerequisite_min_exploration = _graph_meta.get("prerequisite_min_exploration", 0.0)
	_graph.prerequisite_flags.assign(_graph_meta.get("prerequisite_flags", []))
	_graph.prerequisite_logic = _graph_meta.get("prerequisite_logic", "AND")
	_graph.completion_flags_set.assign(_graph_meta.get("completion_flags_set", []))
	_graph.completion_quest_complete.assign(_graph_meta.get("completion_quest_complete", []))
	_graph.completion_unlock_graphs.assign(_graph_meta.get("completion_unlock_graphs", []))
	_graph.editor_scroll_offset = graph_edit.scroll_offset
	_graph.editor_zoom = graph_edit.zoom

	# 更新节点位置
	for node_id in _nodes:
		var gn: GraphNode = _nodes[node_id]
		if is_instance_valid(gn) and gn.has_meta("node_data"):
			var nd: DialogueNodeData = gn.get_meta("node_data")
			nd.position = gn.position_offset

	# 保存
	var path := "res://resources/dialogue/" + _graph.graph_id + ".tres"
	var err := ResourceSaver.save(_graph, path)
	if err == OK:
		print("Dialogue Editor: 已保存到 ", path)
		_dirty = false
	else:
		push_warning("Dialogue Editor: 保存失败，错误码 %d" % err)


func _on_load() -> void:
	_file_dialog.current_dir = ProjectSettings.globalize_path("res://resources/dialogue/")
	_file_dialog.popup_centered_ratio(0.6)


func _on_file_selected(path: String) -> void:
	var res = load(path)
	if res == null or not res is DialogueGraph:
		push_warning("Dialogue Editor: 无法加载对话图文件")
		return

	var graph: DialogueGraph = res
	var data: Dictionary = GraphSerializerScript.deserialize(graph)

	_clear_canvas()
	_graph = graph
	_graph_meta = data["meta"]
	_dirty = false
	_selected_node_id = ""

	# 重建节点
	for node_data: DialogueNodeData in data["nodes"]:
		_graph.nodes.append(node_data)
		_create_graph_node(node_data)

	# 重建连接
	for conn: DialogueConnection in data["connections"]:
		_connections.append({
			"from_node": conn.from_node,
			"from_port": conn.from_port,
			"to_node": conn.to_node,
			"to_port": conn.to_port,
		})
		graph_edit.connect_node(
			StringName(conn.from_node), conn.from_port,
			StringName(conn.to_node), conn.to_port)

	# 恢复视口
	if _graph_meta.has("editor_scroll_offset"):
		graph_edit.scroll_offset = _graph_meta["editor_scroll_offset"]
	if _graph_meta.has("editor_zoom"):
		graph_edit.zoom = _graph_meta["editor_zoom"]

	_show_graph_panel()
	_refresh_graph_panel()
	print("Dialogue Editor: 已加载 ", graph.graph_id)


# ==================== 节点操作 ====================

func _on_add_node(node_type: int) -> void:
	var node_data := DialogueNodeData.new()
	node_data.node_id = _generate_node_id()
	node_data.node_type = node_type
	var count := _nodes.size()
	node_data.position = Vector2(100 + count * 50, 100 + count * 40)

	_graph.nodes.append(node_data)
	_create_graph_node(node_data)
	_dirty = true


func _on_node_selected(node: Node) -> void:
	if node is GraphNode and node.has_meta("node_data"):
		_selected_node_id = String(node.name)
		var node_data: DialogueNodeData = node.get_meta("node_data")
		_show_node_panel()
		if _property_panel:
			_property_panel.edit_node(node_data)


func _on_node_deselected(_node: Node) -> void:
	_selected_node_id = ""
	_show_graph_panel()
	if _property_panel:
		_property_panel.edit_node(null)


func _on_node_data_changed() -> void:
	_dirty = true
	if _selected_node_id != "" and _nodes.has(_selected_node_id):
		var node: GraphNode = _nodes[_selected_node_id]
		var node_data: DialogueNodeData = node.get_meta("node_data")
		_update_node_display(node, node_data)


func _on_connection_request(from: StringName, from_port: int, to: StringName, to_port: int) -> void:
	graph_edit.connect_node(from, from_port, to, to_port)
	_connections.append({
		"from_node": String(from),
		"from_port": from_port,
		"to_node": String(to),
		"to_port": to_port,
	})
	_dirty = true


func _on_disconnection_request(from: StringName, from_port: int, to: StringName, to_port: int) -> void:
	graph_edit.disconnect_node(from, from_port, to, to_port)
	_connections.erase({
		"from_node": String(from),
		"from_port": from_port,
		"to_node": String(to),
		"to_port": to_port,
	})
	_dirty = true


# ==================== 节点创建/更新 ====================

func _create_graph_node(node_data: DialogueNodeData) -> void:
	var node := GraphNode.new()
	node.title = _get_node_type_name(node_data.node_type)
	node.name = node_data.node_id
	node.position_offset = node_data.position
	node.selectable = true

	# 标题栏颜色
	var color := _get_node_color(node_data.node_type)
	var titlebar := StyleBoxFlat.new()
	titlebar.bg_color = color
	titlebar.corner_radius_top_left = 4
	titlebar.corner_radius_top_right = 4
	titlebar.content_margin_left = 8
	titlebar.content_margin_right = 8
	titlebar.content_margin_top = 4
	titlebar.content_margin_bottom = 4
	node.add_theme_stylebox_override("titlebar", titlebar)

	# 预览标签
	var label := Label.new()
	label.name = "PreviewLabel"
	label.text = _get_node_preview(node_data)
	label.add_theme_font_size_override("font_size", 12)
	node.add_child(label)

	# Choice 节点：添加选项标签行
	if node_data.node_type == 2:
		for i in node_data.choices.size():
			var choice_label := Label.new()
			choice_label.text = "  %d. %s" % [i + 1, node_data.choices[i].text_key]
			choice_label.add_theme_font_size_override("font_size", 12)
			node.add_child(choice_label)

	_setup_ports(node, node_data)
	node.set_meta("node_data", node_data)

	graph_edit.add_child(node)
	_nodes[node_data.node_id] = node
	node.delete_request.connect(_on_node_delete.bind(node_data.node_id))


func _setup_ports(node: GraphNode, data: DialogueNodeData) -> void:
	match data.node_type:
		0:  # START
			node.set_slot(0, false, 0, Color.WHITE, true, 0, Color.GREEN)
		1:  # DIALOGUE
			node.set_slot(0, true, 0, Color.WHITE, true, 0, Color.CYAN)
		2:  # CHOICE
			node.set_slot(0, true, 0, Color.WHITE, false, 0, Color.WHITE)
			for i in data.choices.size():
				node.set_slot(i + 1, false, 0, Color.WHITE, true, 0, Color(1.0, 0.9, 0.3))
		3:  # CONDITION
			node.set_slot(0, true, 0, Color.WHITE, true, 0, Color.GREEN)
		4:  # ACTION
			node.set_slot(0, true, 0, Color.WHITE, true, 0, Color.CYAN)
		5:  # SUB_DIALOGUE
			node.set_slot(0, true, 0, Color.WHITE, true, 0, Color.CYAN)
		6:  # END
			node.set_slot(0, true, 0, Color.WHITE, false, 0, Color.WHITE)


func _update_node_display(node: GraphNode, data: DialogueNodeData) -> void:
	var label: Label = node.get_node_or_null("PreviewLabel")
	if label:
		label.text = _get_node_preview(data)
	if data.node_type == 2:
		# 重建 choice 行和端口
		var children := node.get_children()
		for child in children:
			if child.name != "PreviewLabel":
				node.remove_child(child)
				child.queue_free()
		# 清除旧 slot
		for i in range(1, 10):
			node.clear_slot(i)
		node.set_slot(0, true, 0, Color.WHITE, false, 0, Color.WHITE)
		for i in data.choices.size():
			var choice_label := Label.new()
			choice_label.text = "  %d. %s" % [i + 1, data.choices[i].text_key]
			choice_label.add_theme_font_size_override("font_size", 12)
			node.add_child(choice_label)
			node.set_slot(i + 1, false, 0, Color.WHITE, true, 0, Color(1.0, 0.9, 0.3))


func _on_node_delete(node_id: String) -> void:
	var node: GraphNode = _nodes.get(node_id)
	if node == null:
		return
	var to_remove: Array = []
	for conn in _connections:
		if conn["from_node"] == node_id or conn["to_node"] == node_id:
			to_remove.append(conn)
	for conn in to_remove:
		graph_edit.disconnect_node(StringName(conn["from_node"]), conn["from_port"],
			StringName(conn["to_node"]), conn["to_port"])
		_connections.erase(conn)
	var node_data: DialogueNodeData = node.get_meta("node_data")
	_graph.nodes.erase(node_data)
	_nodes.erase(node_id)
	if _selected_node_id == node_id:
		_selected_node_id = ""
		_show_graph_panel()
		if _property_panel:
			_property_panel.edit_node(null)
	node.queue_free()
	_dirty = true


func _clear_canvas() -> void:
	for node_id in _nodes:
		var node: GraphNode = _nodes[node_id]
		if is_instance_valid(node):
			node.queue_free()
	_nodes.clear()
	_connections.clear()
	graph_edit.clear_connections()


# ==================== 图属性面板 ====================

func _build_graph_panel() -> void:
	_graph_panel = VBoxContainer.new()
	_graph_panel.name = "GraphPanel"

	# 标题
	var title := Label.new()
	title.text = "Graph Properties"
	title.add_theme_font_size_override("font_size", 14)
	_graph_panel.add_child(title)

	# graph_id
	_add_graph_field("graph_id", "", func(v): _graph.graph_id = v; _dirty = true)
	# npc_id
	_add_graph_field("npc_id", "", func(v): _graph.npc_id = v; _dirty = true)
	# priority
	_add_graph_spinbox("priority", 0, func(v): _graph_meta["priority"] = v; _dirty = true)
	# repeatable
	var repeat_cb := CheckBox.new()
	repeat_cb.text = "Repeatable"
	repeat_cb.name = "Repeatable"
	repeat_cb.toggled.connect(func(v): _graph_meta["repeatable"] = v; _dirty = true)
	_graph_panel.add_child(repeat_cb)

	# 分隔
	_graph_panel.add_child(HSeparator.new())
	var prereq_label := Label.new()
	prereq_label.text = "Prerequisites"
	_graph_panel.add_child(prereq_label)
	# prerequisite_logic
	_add_graph_option("logic", ["AND", "OR"], 0,
		func(idx): _graph_meta["prerequisite_logic"] = ["AND", "OR"][idx]; _dirty = true)
	# prerequisite_flags
	_add_graph_multiline("prereq_flags", "",
		func(v): _parse_string_array(v, "prerequisite_flags"); _dirty = true)
	# prerequisite_min_day
	_add_graph_spinbox("min_day", 0,
		func(v): _graph_meta["prerequisite_min_day"] = v; _dirty = true)

	# 分隔
	_graph_panel.add_child(HSeparator.new())
	var comp_label := Label.new()
	comp_label.text = "Completion Effects"
	_graph_panel.add_child(comp_label)
	# completion_flags_set
	_add_graph_multiline("comp_flags", "",
		func(v): _parse_string_array(v, "completion_flags_set"); _dirty = true)

	sidebar.add_child(_graph_panel)


func _refresh_graph_panel() -> void:
	if _graph_panel == null:
		return
	# 更新字段值
	_set_field_text("graph_id", _graph.graph_id)
	_set_field_text("npc_id", _graph.npc_id)
	_set_spinbox_value("priority", _graph_meta.get("priority", 0))
	var cb: CheckBox = _graph_panel.get_node_or_null("Repeatable")
	if cb:
		cb.button_pressed = _graph_meta.get("repeatable", false)
	_set_field_text("prereq_flags", ",".join(_graph_meta.get("prerequisite_flags", [])))
	_set_spinbox_value("min_day", _graph_meta.get("prerequisite_min_day", 0))
	_set_field_text("comp_flags", ",".join(_graph_meta.get("completion_flags_set", [])))


func _add_graph_field(name: String, value: String, on_change: Callable) -> void:
	var hbox := HBoxContainer.new()
	var label := Label.new()
	label.text = name
	label.custom_minimum_size.x = 80
	hbox.add_child(label)
	var line := LineEdit.new()
	line.name = name
	line.text = value
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.text_changed.connect(func(v): on_change.call(v))
	hbox.add_child(line)
	_graph_panel.add_child(hbox)


func _add_graph_spinbox(name: String, value: int, on_change: Callable) -> void:
	var hbox := HBoxContainer.new()
	var label := Label.new()
	label.text = name
	label.custom_minimum_size.x = 80
	hbox.add_child(label)
	var spin := SpinBox.new()
	spin.name = name
	spin.value = value
	spin.min_value = 0
	spin.max_value = 9999
	spin.value_changed.connect(func(v): on_change.call(int(v)))
	hbox.add_child(spin)
	_graph_panel.add_child(hbox)


func _add_graph_option(name: String, options: Array, selected: int, on_change: Callable) -> void:
	var hbox := HBoxContainer.new()
	var label := Label.new()
	label.text = name
	label.custom_minimum_size.x = 80
	hbox.add_child(label)
	var btn := OptionButton.new()
	btn.name = name
	for opt in options:
		btn.add_item(opt)
	btn.select(selected)
	btn.item_selected.connect(func(idx): on_change.call(idx))
	hbox.add_child(btn)
	_graph_panel.add_child(hbox)


func _add_graph_multiline(name: String, value: String, on_change: Callable) -> void:
	var label := Label.new()
	label.text = name + " (comma separated)"
	_graph_panel.add_child(label)
	var line := LineEdit.new()
	line.name = name
	line.text = value
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.text_changed.connect(func(v): on_change.call(v))
	_graph_panel.add_child(line)


func _set_field_text(name: String, text: String) -> void:
	var node: LineEdit = _graph_panel.get_node_or_null(name)
	if node:
		node.text = text


func _set_spinbox_value(name: String, value: int) -> void:
	var node: SpinBox = _graph_panel.get_node_or_null(name)
	if node:
		node.value = value


func _parse_string_array(text: String, key: String) -> void:
	var arr: Array = []
	for s in text.split(","):
		s = s.strip_edges()
		if s != "":
			arr.append(s)
	_graph_meta[key] = arr


func _show_graph_panel() -> void:
	if _graph_panel:
		_graph_panel.visible = true
	if _property_panel:
		_property_panel.visible = false


func _show_node_panel() -> void:
	if _graph_panel:
		_graph_panel.visible = false
	if _property_panel:
		_property_panel.visible = true


# ==================== 工具函数 ====================

func _generate_node_id() -> String:
	return "node_" + str(Time.get_ticks_msec())


func _get_node_preview(data: DialogueNodeData) -> String:
	match data.node_type:
		0: return "Entry point"
		1: return data.text_key.left(40) if data.text_key else "(empty)"
		2: return "%d choices" % data.choices.size()
		3:
			if data.condition:
				return "Condition: type %d" % data.condition.condition_type
			return "(no condition)"
		4: return "%d actions" % data.actions.size()
		5: return "-> %s" % data.target_graph_id if data.target_graph_id else "(no target)"
		6: return "End"
		_: return ""


func _get_node_type_name(node_type: int) -> String:
	match node_type:
		0: return "Start"
		1: return "Dialogue"
		2: return "Choice"
		3: return "Condition"
		4: return "Action"
		5: return "Sub-Dialogue"
		6: return "End"
		_: return "Unknown"


func _get_node_color(node_type: int) -> Color:
	match node_type:
		0: return Color.GREEN
		1: return Color(0.4, 0.6, 1.0)
		2: return Color(1.0, 0.9, 0.3)
		3: return Color(1.0, 0.6, 0.2)
		4: return Color(0.7, 0.4, 1.0)
		5: return Color(0.3, 0.9, 0.9)
		6: return Color(1.0, 0.3, 0.3)
		_: return Color.WHITE
