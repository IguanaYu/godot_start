@tool
extends RefCounted
## 对话图序列化/反序列化工具


## 从画布状态构建 DialogueGraph 资源
static func serialize(graph_id: String, npc_id: String, nodes_dict: Dictionary,
		connections_array: Array, graph_meta: Dictionary, existing_nodes: Array,
		existing_connections: Array) -> DialogueGraph:
	var graph := DialogueGraph.new()
	graph.graph_id = graph_id
	graph.npc_id = npc_id
	graph.priority = graph_meta.get("priority", 0)
	graph.repeatable = graph_meta.get("repeatable", false)

	# 前置条件（用 assign 处理 Array[String] 类型）
	graph.prerequisite_graph_ids.assign(graph_meta.get("prerequisite_graph_ids", []))
	graph.prerequisite_quest_ids.assign(graph_meta.get("prerequisite_quest_ids", []))
	graph.prerequisite_min_day = graph_meta.get("prerequisite_min_day", 0)
	graph.prerequisite_min_exploration = graph_meta.get("prerequisite_min_exploration", 0.0)
	graph.prerequisite_flags.assign(graph_meta.get("prerequisite_flags", []))
	graph.prerequisite_logic = graph_meta.get("prerequisite_logic", "AND")

	# 完成效果
	graph.completion_flags_set.assign(graph_meta.get("completion_flags_set", []))
	graph.completion_quest_complete.assign(graph_meta.get("completion_quest_complete", []))
	graph.completion_unlock_graphs.assign(graph_meta.get("completion_unlock_graphs", []))

	# 编辑器元数据
	graph.editor_scroll_offset = graph_meta.get("editor_scroll_offset", Vector2.ZERO)
	graph.editor_zoom = graph_meta.get("editor_zoom", 1.0)

	# 节点 — 使用已有的（包含编辑过的属性）
	graph.nodes.assign(existing_nodes)

	# 连接
	for conn in connections_array:
		var dconn := DialogueConnection.new()
		dconn.from_node = conn["from_node"]
		dconn.from_port = conn["from_port"]
		dconn.to_node = conn["to_node"]
		dconn.to_port = conn["to_port"]
		graph.connections.append(dconn)

	return graph


## 从 DialogueGraph 提取节点数据和连接数据
static func deserialize(graph: DialogueGraph) -> Dictionary:
	return {
		"graph_id": graph.graph_id,
		"npc_id": graph.npc_id,
		"nodes": graph.nodes.duplicate(),
		"connections": graph.connections.duplicate(),
		"meta": {
			"priority": graph.priority,
			"repeatable": graph.repeatable,
			"prerequisite_graph_ids": Array(graph.prerequisite_graph_ids),
			"prerequisite_quest_ids": Array(graph.prerequisite_quest_ids),
			"prerequisite_min_day": graph.prerequisite_min_day,
			"prerequisite_min_exploration": graph.prerequisite_min_exploration,
			"prerequisite_flags": Array(graph.prerequisite_flags),
			"prerequisite_logic": graph.prerequisite_logic,
			"completion_flags_set": Array(graph.completion_flags_set),
			"completion_quest_complete": Array(graph.completion_quest_complete),
			"completion_unlock_graphs": Array(graph.completion_unlock_graphs),
			"editor_scroll_offset": graph.editor_scroll_offset,
			"editor_zoom": graph.editor_zoom,
		}
	}
