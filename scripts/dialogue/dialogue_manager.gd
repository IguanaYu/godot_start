extends Node
## 对话图总管理器。管理所有对话图的加载、解锁关系和完成状态。

signal dialogue_graph_completed(graph_id: String)
signal dialogue_graph_unlocked(graph_id: String)

const DIALOGUE_DIR := "res://resources/dialogue/"

# 所有对话图定义
var _graph_definitions: Dictionary = {}
# 已完成的对话图
var _completed_graphs: Array[String] = []
# 已解锁的对话图
var _unlocked_graphs: Array[String] = []
# 对话标记系统
var _flags: Dictionary = {}


func _ready() -> void:
	_load_all_graphs()
	_initialize_unlocked_graphs()


func _load_all_graphs() -> void:
	_load_graphs_recursive(DIALOGUE_DIR)


func _load_graphs_recursive(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		var full_path := dir_path + file_name
		if dir.current_is_dir():
			_load_graphs_recursive(full_path + "/")
		elif file_name.ends_with(".tres"):
			var res = load(full_path)
			if res and res.get("graph_id") != "":
				_graph_definitions[res.graph_id] = res
		file_name = dir.get_next()
	dir.list_dir_end()


func _initialize_unlocked_graphs() -> void:
	for graph_id in _graph_definitions:
		var graph = _graph_definitions[graph_id]
		if _check_prerequisites(graph):
			_unlock_graph(graph_id)


## 检查对话图的前置条件是否全部满足
func _check_prerequisites(graph) -> bool:
	var results: Array[bool] = []

	# 前置对话图
	if graph.prerequisite_graph_ids.size() > 0:
		var met := true
		for gid in graph.prerequisite_graph_ids:
			if not _completed_graphs.has(gid):
				met = false
				break
		results.append(met)

	# 前置任务
	if graph.prerequisite_quest_ids.size() > 0:
		var met := true
		for qid in graph.prerequisite_quest_ids:
			if not QuestManager.is_quest_completed(qid):
				met = false
				break
		results.append(met)

	# 最低天数
	if graph.prerequisite_min_day > 0:
		results.append(GameManager.current_day_number >= graph.prerequisite_min_day)

	# 最低探索度
	if graph.prerequisite_min_exploration > 0.0:
		if ExplorationProgress:
			results.append(ExplorationProgress.get_exploration_value() >= graph.prerequisite_min_exploration)
		else:
			results.append(false)

	# 前置标记
	if graph.prerequisite_flags.size() > 0:
		var met := true
		for flag in graph.prerequisite_flags:
			if not _flags.get(flag, false):
				met = false
				break
		results.append(met)

	# 没有任何前置条件 → 默认解锁
	if results.is_empty():
		return true

	# 组合逻辑
	if graph.prerequisite_logic == "OR":
		return results.has(true)
	else:
		return not results.has(false)


func _unlock_graph(graph_id: String) -> void:
	if _unlocked_graphs.has(graph_id):
		return
	_unlocked_graphs.append(graph_id)
	dialogue_graph_unlocked.emit(graph_id)


## 检查是否解锁了新的对话图（某事件发生后调用）
func check_and_unlock_graphs() -> void:
	for graph_id in _graph_definitions:
		if _unlocked_graphs.has(graph_id):
			continue
		var graph = _graph_definitions[graph_id]
		if _check_prerequisites(graph):
			_unlock_graph(graph_id)


func complete_graph(graph_id: String) -> void:
	if _completed_graphs.has(graph_id):
		return
	_completed_graphs.append(graph_id)

	var graph = _graph_definitions.get(graph_id)
	if graph:
		# 设置完成标记
		for flag in graph.completion_flags_set:
			set_flag(flag)
		# 标记任务完成
		for qid in graph.completion_quest_complete:
			QuestManager.complete_quest(qid)

	dialogue_graph_completed.emit(graph_id)
	check_and_unlock_graphs()


func is_graph_unlocked(graph_id: String) -> bool:
	return _unlocked_graphs.has(graph_id)


func is_graph_completed(graph_id: String) -> bool:
	return _completed_graphs.has(graph_id)


func get_graph(graph_id: String):
	return _graph_definitions.get(graph_id)


## 获取某个 NPC 所有已解锁且可用的对话图，按优先级降序
func get_available_graphs_for_npc(npc_id: String) -> Array:
	var result: Array = []
	for graph_id in _unlocked_graphs:
		var graph = _graph_definitions[graph_id]
		if graph.npc_id != npc_id:
			continue
		# 已完成且不可重复 → 跳过
		if _completed_graphs.has(graph_id) and not graph.repeatable:
			continue
		result.append(graph)
	result.sort_custom(func(a, b) -> bool:
		return a.priority > b.priority
	)
	return result


## 获取某个 NPC 优先级最高的可用对话图
func get_next_graph_for_npc(npc_id: String):
	var available := get_available_graphs_for_npc(npc_id)
	if available.is_empty():
		return null
	return available[0]


func set_flag(flag_name: String, value: bool = true) -> void:
	_flags[flag_name] = value
	check_and_unlock_graphs()


func has_flag(flag_name: String) -> bool:
	return _flags.get(flag_name, false)


func clear_flag(flag_name: String) -> void:
	_flags.erase(flag_name)


## 程序化注册对话图（测试/脚本用，不从 .tres 加载）
func register_graph(graph) -> void:
	if graph == null or graph.get("graph_id") == "":
		return
	_graph_definitions[graph.graph_id] = graph
	if not _unlocked_graphs.has(graph.graph_id) and _check_prerequisites(graph):
		_unlock_graph(graph.graph_id)


## 存档
func get_save_data() -> Dictionary:
	return {
		"completed_graphs": _completed_graphs,
		"unlocked_graphs": _unlocked_graphs,
		"flags": _flags.duplicate(),
	}


func restore_save_data(data: Dictionary) -> void:
	_completed_graphs = data.get("completed_graphs", [])
	_unlocked_graphs = data.get("unlocked_graphs", [])
	_flags = data.get("flags", {})
