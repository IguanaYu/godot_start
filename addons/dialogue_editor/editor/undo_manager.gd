@tool
extends RefCounted
## 简易撤销/重做栈，记录对话图的快照

var _undo_stack: Array[Dictionary] = []
var _redo_stack: Array[Dictionary] = []
var _max_size: int = 50


func push_snapshot(snapshot: Dictionary) -> void:
	_undo_stack.append(snapshot)
	_redo_stack.clear()
	if _undo_stack.size() > _max_size:
		_undo_stack.pop_front()


func undo() -> Dictionary:
	if _undo_stack.is_empty():
		return {}
	var snapshot := _undo_stack.pop_back()
	_redo_stack.append(snapshot)
	return snapshot


func redo() -> Dictionary:
	if _redo_stack.is_empty():
		return {}
	var snapshot := _redo_stack.pop_back()
	_undo_stack.append(snapshot)
	return snapshot


func can_undo() -> bool:
	return not _undo_stack.is_empty()


func can_redo() -> bool:
	return not _redo_stack.is_empty()


func clear() -> void:
	_undo_stack.clear()
	_redo_stack.clear()


## 创建当前画布状态的快照
static func create_snapshot(graph: DialogueGraph, connections: Array, graph_meta: Dictionary) -> Dictionary:
	# 深拷贝节点数据
	var nodes_copy: Array = []
	for node_data: DialogueNodeData in graph.nodes:
		nodes_copy.append(_copy_node_data(node_data))

	# 深拷贝连接
	var conns_copy: Array = []
	for conn in connections:
		conns_copy.append({
			"from_node": conn["from_node"],
			"from_port": conn["from_port"],
			"to_node": conn["to_node"],
			"to_port": conn["to_port"],
		})

	# 深拷贝 meta
	var meta_copy: Dictionary = {}
	for key in graph_meta:
		var val = graph_meta[key]
		if val is Array:
			meta_copy[key] = val.duplicate()
		else:
			meta_copy[key] = val

	return {
		"graph_id": graph.graph_id,
		"npc_id": graph.npc_id,
		"nodes": nodes_copy,
		"connections": conns_copy,
		"meta": meta_copy,
	}


static func _copy_node_data(src: DialogueNodeData) -> DialogueNodeData:
	var dst := DialogueNodeData.new()
	dst.node_id = src.node_id
	dst.node_type = src.node_type
	dst.position = src.position
	dst.text_key = src.text_key
	dst.speaker = src.speaker
	dst.target_graph_id = src.target_graph_id

	# 拷贝 choices
	dst.choices.clear()
	for c: ChoiceData in src.choices:
		var nc := ChoiceData.new()
		nc.text_key = c.text_key
		nc.target_node_id = c.target_node_id
		if c.condition:
			nc.condition = _copy_condition(c.condition)
		for a: ActionData in c.actions:
			nc.actions.append(_copy_action(a))
		dst.choices.append(nc)

	# 拷贝 condition
	if src.condition:
		dst.condition = _copy_condition(src.condition)

	# 拷贝 actions
	dst.actions.clear()
	for a: ActionData in src.actions:
		dst.actions.append(_copy_action(a))

	return dst


static func _copy_condition(src: ConditionData) -> ConditionData:
	var dst := ConditionData.new()
	dst.condition_type = src.condition_type
	dst.negated = src.negated
	dst.params = src.params.duplicate()
	return dst


static func _copy_action(src: ActionData) -> ActionData:
	var dst := ActionData.new()
	dst.action_type = src.action_type
	dst.params = src.params.duplicate()
	return dst
