@tool
extends VBoxContainer
## 节点属性编辑面板

signal node_data_changed()

var _current_data: DialogueNodeData = null
var _current_type: int = -1
var _updating: bool = false


func edit_node(node_data: DialogueNodeData) -> void:
	_clear()
	if node_data == null:
		return
	_current_data = node_data
	_current_type = node_data.node_type
	_updating = true

	# 标题
	_add_label("Node: " + _type_name(_current_type))

	# node_id
	_add_field("node_id", node_data.node_id, func(v): node_data.node_id = v; node_data_changed.emit())

	# 根据类型显示不同字段
	match _current_type:
		1: _build_dialogue_fields(node_data)
		2: _build_choice_fields(node_data)
		3: _build_condition_fields(node_data)
		4: _build_action_fields(node_data)
		5: _build_sub_dialogue_fields(node_data)

	_updating = false


func _clear() -> void:
	_current_data = null
	_current_type = -1
	for child in get_children():
		child.queue_free()


func _add_label(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	add_child(label)


func _add_separator() -> void:
	var sep := HSeparator.new()
	add_child(sep)


func _add_field(label_text: String, value: String, on_change: Callable) -> LineEdit:
	var hbox := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 80
	hbox.add_child(label)
	var line := LineEdit.new()
	line.text = value
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.text_changed.connect(func(v): if not _updating: on_change.call(v))
	hbox.add_child(line)
	add_child(hbox)
	return line


func _add_option(label_text: String, options: Array, selected: int, on_change: Callable) -> OptionButton:
	var hbox := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 80
	hbox.add_child(label)
	var btn := OptionButton.new()
	for i in options.size():
		btn.add_item(options[i], i)
	btn.select(selected)
	btn.item_selected.connect(func(idx): if not _updating: on_change.call(idx))
	hbox.add_child(btn)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(hbox)
	return btn


func _add_checkbox(label_text: String, value: bool, on_change: Callable) -> CheckBox:
	var cb := CheckBox.new()
	cb.text = label_text
	cb.button_pressed = value
	cb.toggled.connect(func(v): if not _updating: on_change.call(v))
	add_child(cb)
	return cb


func _add_text_edit(value: String, on_change: Callable) -> TextEdit:
	var te := TextEdit.new()
	te.text = value
	te.custom_minimum_size.y = 60
	te.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	te.text_changed.connect(func(): if not _updating: on_change.call(te.text))
	add_child(te)
	return te


# ==================== 各节点类型的字段构建 ====================

func _build_dialogue_fields(data: DialogueNodeData) -> void:
	_add_separator()
	_add_label("Speaker:")
	_add_option("speaker", ["npc", "player", "narrator"],
		["npc", "player", "narrator"].find(data.speaker) if data.speaker in ["npc", "player", "narrator"] else 0,
		func(idx): data.speaker = ["npc", "player", "narrator"][idx]; node_data_changed.emit())
	_add_label("Text:")
	_add_text_edit(data.text_key, func(v): data.text_key = v; node_data_changed.emit())
	_add_separator()
	_add_label("Actions:")
	_build_actions_list(data)


func _build_choice_fields(data: DialogueNodeData) -> void:
	_add_separator()
	_add_label("Choices:")
	for i in data.choices.size():
		var choice: ChoiceData = data.choices[i]
		_add_label("  Choice %d:" % (i + 1))
		_add_field("  text", choice.text_key,
			func(v): choice.text_key = v; node_data_changed.emit())
	# 添加/删除按钮
	var btn_hbox := HBoxContainer.new()
	var btn_add := Button.new()
	btn_add.text = "+ Add Choice"
	btn_add.pressed.connect(func():
		if _current_data:
			var c := ChoiceData.new()
			c.text_key = "Option %d" % (_current_data.choices.size() + 1)
			_current_data.choices.append(c)
			node_data_changed.emit()
			edit_node(_current_data)
	)
	btn_hbox.add_child(btn_add)
	var btn_remove := Button.new()
	btn_remove.text = "- Remove Last"
	btn_remove.pressed.connect(func():
		if _current_data and _current_data.choices.size() > 0:
			_current_data.choices.pop_back()
			node_data_changed.emit()
			edit_node(_current_data)
	)
	btn_hbox.add_child(btn_remove)
	add_child(btn_hbox)


func _build_condition_fields(data: DialogueNodeData) -> void:
	_add_separator()
	_add_label("Condition:")
	if data.condition == null:
		data.condition = ConditionData.new()
	var cond: ConditionData = data.condition
	var type_names := [
		"FLAG_SET", "FLAG_NOT_SET", "QUEST_COMPLETED", "QUEST_ACTIVE",
		"MIN_COINS", "MIN_DAY", "MIN_EXPLORATION", "HAS_ITEM",
		"CHARACTER_IS", "CUSTOM_EXPRESSION"
	]
	_add_option("type", type_names, cond.condition_type,
		func(idx): cond.condition_type = idx; node_data_changed.emit())
	_add_checkbox("negated", cond.negated,
		func(v): cond.negated = v; node_data_changed.emit())
	_add_label("Params (key=value per line):")
	# 显示 params dictionary 为可编辑文本
	var params_text := ""
	for key in cond.params:
		params_text += "%s=%s\n" % [key, str(cond.params[key])]
	var te := _add_text_edit(params_text.strip_edges(), func(v):
		cond.params.clear()
		for line in v.split("\n"):
			var parts: PackedStringArray = line.split("=", 1)
			if parts.size() == 2:
				cond.params[parts[0].strip_edges()] = parts[1].strip_edges()
		node_data_changed.emit()
	)


func _build_action_fields(data: DialogueNodeData) -> void:
	_add_separator()
	_add_label("Actions:")
	_build_actions_list(data)
	# 添加/删除按钮
	var btn_hbox := HBoxContainer.new()
	var btn_add := Button.new()
	btn_add.text = "+ Add Action"
	btn_add.pressed.connect(func():
		if _current_data:
			var a := ActionData.new()
			_current_data.actions.append(a)
			node_data_changed.emit()
			edit_node(_current_data)
	)
	btn_hbox.add_child(btn_add)
	var btn_remove := Button.new()
	btn_remove.text = "- Remove Last"
	btn_remove.pressed.connect(func():
		if _current_data and _current_data.actions.size() > 0:
			_current_data.actions.pop_back()
			node_data_changed.emit()
			edit_node(_current_data)
	)
	btn_hbox.add_child(btn_remove)
	add_child(btn_hbox)


func _build_actions_list(data: DialogueNodeData) -> void:
	var action_names := [
		"SET_FLAG", "CLEAR_FLAG", "GIVE_COINS", "TAKE_COINS",
		"GIVE_ITEM", "TAKE_ITEM", "COMPLETE_QUEST", "START_QUEST",
		"UNLOCK_GRAPH", "TRIGGER_EVENT", "SPAWN_NPC", "CHANGE_NPC_STATE"
	]
	for i in data.actions.size():
		var action: ActionData = data.actions[i]
		_add_label("  Action %d:" % (i + 1))
		_add_option("  type", action_names, action.action_type,
			func(idx): action.action_type = idx; node_data_changed.emit())
		# params 编辑
		var params_text := ""
		for key in action.params:
			params_text += "%s=%s\n" % [key, str(action.params[key])]
		if params_text == "":
			params_text = "amount=0" if action.action_type in [2, 3] else "flag_name="
		var te := _add_text_edit(params_text.strip_edges(), func(v):
			action.params.clear()
			for line in v.split("\n"):
				var parts: PackedStringArray = line.split("=", 1)
				if parts.size() == 2:
					action.params[parts[0].strip_edges()] = parts[1].strip_edges()
			node_data_changed.emit()
		)


func _build_sub_dialogue_fields(data: DialogueNodeData) -> void:
	_add_separator()
	_add_label("Target Graph ID:")
	_add_field("target", data.target_graph_id,
		func(v): data.target_graph_id = v; node_data_changed.emit())


func _type_name(t: int) -> String:
	match t:
		0: return "Start"
		1: return "Dialogue"
		2: return "Choice"
		3: return "Condition"
		4: return "Action"
		5: return "Sub-Dialogue"
		6: return "End"
		_: return "Unknown"
