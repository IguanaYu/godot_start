@tool
extends RefCounted
## 对话图保存前验证器


## 验证对话图，返回错误列表。空列表表示通过。
static func validate(graph: DialogueGraph, connections: Array) -> Array[String]:
	var errors: Array[String] = []

	# 1. graph_id 非空
	if graph.graph_id.strip_edges() == "":
		errors.append("graph_id 不能为空")

	# 2. 至少 1 个 START 和 1 个 END
	var has_start := false
	var has_end := false
	for node_data: DialogueNodeData in graph.nodes:
		if node_data.node_type == 0:  # START
			has_start = true
		if node_data.node_type == 6:  # END
			has_end = true
	if not has_start:
		errors.append("至少需要 1 个 Start 节点")
	if not has_end:
		errors.append("至少需要 1 个 End 节点")

	# 3. node_id 无重复
	var seen_ids: Dictionary = {}
	for node_data: DialogueNodeData in graph.nodes:
		if seen_ids.has(node_data.node_id):
			errors.append("重复的 node_id: %s" % node_data.node_id)
		seen_ids[node_data.node_id] = true

	# 4. 所有节点可达（从 START 出发 BFS）
	if has_start and graph.nodes.size() > 1:
		var reachable: Dictionary = {}
		var queue: Array = []
		# 找到 START 节点
		for node_data: DialogueNodeData in graph.nodes:
			if node_data.node_type == 0:
				queue.append(node_data.node_id)
				reachable[node_data.node_id] = true
				break
		# 构建邻接表
		var adj: Dictionary = {}  # node_id -> Array of target node_ids
		for conn in connections:
			var from: String = conn["from_node"]
			var to: String = conn["to_node"]
			if not adj.has(from):
				adj[from] = []
			adj[from].append(to)
		# BFS
		while queue.size() > 0:
			var current: String = queue.pop_front()
			if adj.has(current):
				for neighbor in adj[current]:
					if not reachable.has(neighbor):
						reachable[neighbor] = true
						queue.append(neighbor)
		# 检查不可达节点
		for node_data: DialogueNodeData in graph.nodes:
			if not reachable.has(node_data.node_id):
				errors.append("节点 '%s' 不可达（没有从 Start 到该节点的路径）" % node_data.node_id)

	# 5. CHOICE 至少 1 个选项
	for node_data: DialogueNodeData in graph.nodes:
		if node_data.node_type == 2 and node_data.choices.size() == 0:
			errors.append("Choice 节点 '%s' 没有选项" % node_data.node_id)

	# 6. CONDITION 有 true/false 连线
	for node_data: DialogueNodeData in graph.nodes:
		if node_data.node_type == 3:  # CONDITION
			var has_true := false
			var has_false := false
			for conn in connections:
				if conn["from_node"] == node_data.node_id:
					if conn["from_port"] == 0:
						has_true = true
					if conn["from_port"] == 1:
						has_false = true
			if not has_true:
				errors.append("Condition 节点 '%s' 缺少 True (port 0) 连线" % node_data.node_id)
			if not has_false:
				errors.append("Condition 节点 '%s' 缺少 False (port 1) 连线" % node_data.node_id)

	# 7. SUB_DIALOGUE target_graph_id 非空
	for node_data: DialogueNodeData in graph.nodes:
		if node_data.node_type == 5 and node_data.target_graph_id.strip_edges() == "":
			errors.append("Sub-Dialogue 节点 '%s' 的 target_graph_id 为空" % node_data.node_id)

	return errors
