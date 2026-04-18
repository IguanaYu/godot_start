extends Node
## 对话运行时。执行对话图，驱动 DialogueUI，处理节点流转。

signal dialogue_started(graph_id: String)
signal dialogue_ended(graph_id: String)
signal action_triggered(action)

const ConditionEvaluatorScript := preload("res://scripts/dialogue/condition_evaluator.gd")

var _current_graph = null
var _current_node = null
var _is_active: bool = false
# 子对话栈（保存现场）
var _dialogue_stack: Array = []
# UI 引用
var dialogue_ui: Control = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func is_active() -> bool:
	return _is_active


func start_dialogue(graph) -> void:
	if _is_active:
		push_warning("DialogueRunner: 已有对话在进行中")
		return
	_current_graph = graph
	_current_node = _find_start_node(graph)
	_is_active = true
	dialogue_started.emit(graph.graph_id)
	_show_ui()
	_process_current_node()


func advance(choice_index: int = -1) -> void:
	if not _is_active or _current_node == null:
		return

	var node_type = _current_node.node_type

	if node_type == 0:  # START
		_goto_next(0)
	elif node_type == 1:  # DIALOGUE
		_goto_next(0)
	elif node_type == 2:  # CHOICE
		_handle_choice(choice_index)
	elif node_type == 3:  # CONDITION
		_goto_next(choice_index)
	elif node_type == 4:  # ACTION
		_goto_next(0)
	elif node_type == 5:  # SUB_DIALOGUE
		_goto_next(0)
	elif node_type == 6:  # END
		_end_dialogue()


func _process_current_node() -> void:
	if _current_node == null:
		_end_dialogue()
		return

	var node_type = _current_node.node_type

	if node_type == 0:  # START
		advance()

	elif node_type == 1:  # DIALOGUE
		_execute_actions(_current_node.actions)
		if dialogue_ui:
			dialogue_ui.show_dialogue(
				_get_speaker_name(_current_node.speaker),
				_get_text(_current_node.text_key),
				_current_node.portrait_override
			)

	elif node_type == 2:  # CHOICE
		var visible_choices := _get_visible_choices()
		if dialogue_ui:
			dialogue_ui.show_choices(visible_choices)

	elif node_type == 3:  # CONDITION
		var result := ConditionEvaluatorScript.evaluate(_current_node.condition)
		advance(0 if result else 1)

	elif node_type == 4:  # ACTION
		_execute_actions(_current_node.actions)
		advance()

	elif node_type == 5:  # SUB_DIALOGUE
		var sub_graph = DialogueManager.get_graph(_current_node.target_graph_id)
		if sub_graph:
			_dialogue_stack.append({
				"graph": _current_graph,
				"node_id": _current_node.node_id
			})
			_current_graph = sub_graph
			_current_node = _find_start_node(sub_graph)
			_process_current_node()
		else:
			push_warning("DialogueRunner: 子对话图不存在 '%s'" % _current_node.target_graph_id)
			advance()

	elif node_type == 6:  # END
		if dialogue_ui:
			dialogue_ui.hide_choices()
		advance()


func _handle_choice(choice_index: int) -> void:
	if choice_index < 0:
		return
	var visible_choices := _get_visible_choices()
	if choice_index >= visible_choices.size():
		return

	var choice = visible_choices[choice_index]
	_execute_actions(choice.actions)

	# 如果选项指定了目标节点，直接跳转
	if choice.target_node_id != "":
		var node = _find_node_by_id(choice.target_node_id)
		if node:
			_current_node = node
			_process_current_node()
			return
	# 否则走 from_port = choice_index + 1 的连接
	_goto_next(choice_index + 1)


func _goto_next(from_port: int) -> void:
	var next_node_id := ""
	for conn in _current_graph.connections:
		if conn.from_node == _current_node.node_id and conn.from_port == from_port:
			next_node_id = conn.to_node
			break

	if next_node_id == "":
		# 尝试默认出口
		if from_port != 0:
			for conn in _current_graph.connections:
				if conn.from_node == _current_node.node_id and conn.from_port == 0:
					next_node_id = conn.to_node
					break
		# 检查子对话栈
		if next_node_id == "" and _dialogue_stack.size() > 0:
			var state: Dictionary = _dialogue_stack.pop_back()
			_current_graph = state["graph"]
			_current_node = _find_node_by_id(state["node_id"])
			for conn in _current_graph.connections:
				if conn.from_node == _current_node.node_id and conn.from_port == 0:
					next_node_id = conn.to_node
					break
			if next_node_id == "":
				_end_dialogue()
				return
			_current_node = _find_node_by_id(next_node_id)
			_process_current_node()
			return
		if next_node_id == "":
			_end_dialogue()
			return

	_current_node = _find_node_by_id(next_node_id)
	_process_current_node()


func _end_dialogue() -> void:
	if not _is_active:
		return
	_is_active = false
	_hide_ui()
	var graph_id = _current_graph.graph_id if _current_graph else ""
	DialogueManager.complete_graph(graph_id)
	dialogue_ended.emit(graph_id)
	_current_graph = null
	_current_node = null
	_dialogue_stack.clear()


func _find_start_node(graph) -> Variant:
	for node in graph.nodes:
		if node.node_type == 0:  # START
			return node
	if graph.nodes.size() > 0:
		return graph.nodes[0]
	return null


func _find_node_by_id(node_id: String) -> Variant:
	if _current_graph == null:
		return null
	for node in _current_graph.nodes:
		if node.node_id == node_id:
			return node
	return null


func _get_visible_choices() -> Array:
	var result: Array = []
	if _current_node == null:
		return result
	for choice in _current_node.choices:
		if choice.condition == null or ConditionEvaluatorScript.evaluate(choice.condition):
			result.append(choice)
	return result


func _execute_actions(actions: Array) -> void:
	for action in actions:
		_execute_action(action)
		action_triggered.emit(action)


func _execute_action(action) -> void:
	# 优先使用 RewardData（如果有）
	if action.reward != null:
		action.reward.grant()
		return

	var action_type = action.action_type

	if action_type == 0:  # SET_FLAG
		var flag_name: String = action.params.get("flag_name", "")
		if flag_name != "":
			DialogueManager.set_flag(flag_name)

	elif action_type == 1:  # CLEAR_FLAG
		var flag_name: String = action.params.get("flag_name", "")
		if flag_name != "":
			DialogueManager.clear_flag(flag_name)

	elif action_type == 2:  # GIVE_COINS
		var amount: int = action.params.get("amount", 0)
		GameManager.add_coins(amount)

	elif action_type == 3:  # TAKE_COINS
		var amount: int = action.params.get("amount", 0)
		GameManager.add_coins(-amount)

	elif action_type == 6:  # COMPLETE_QUEST
		var quest_id: String = action.params.get("quest_id", "")
		if quest_id != "":
			QuestManager.complete_quest(quest_id)

	elif action_type == 7:  # START_QUEST
		var quest_id: String = action.params.get("quest_id", "")
		if quest_id != "":
			QuestManager.start_quest(quest_id)

	elif action_type == 8:  # UNLOCK_GRAPH
		var graph_id: String = action.params.get("graph_id", "")
		if graph_id != "":
			DialogueManager._unlock_graph(graph_id)


func _get_text(text_key: String) -> String:
	if text_key == "":
		return ""
	return text_key


func _get_speaker_name(speaker: String) -> String:
	match speaker:
		"player": return "旅行者"
		"narrator": return ""
		"": return ""
		_: return speaker


func _show_ui() -> void:
	if dialogue_ui:
		dialogue_ui.visible = true


func _hide_ui() -> void:
	if dialogue_ui:
		dialogue_ui.visible = false
		dialogue_ui.hide_dialogue()
