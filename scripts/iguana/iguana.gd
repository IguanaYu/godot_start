extends Node
## Iguana 剧情管理 AI。根据玩家状态决定推送什么内容到游戏中。

signal content_pushed(content)
signal npc_should_spawn(npc_id: String, graph_id: String)

const CONTENT_DIR := "res://resources/iguana/"

# 所有可用内容
var _content_pool: Array = []
# 已推送的内容 ID
var _pushed_content: Array[String] = []
# 每次回到休息区最多推送的新内容数
@export var max_push_per_visit: int = 2


func _ready() -> void:
	_load_all_content()


func _load_all_content() -> void:
	var dir := DirAccess.open(CONTENT_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var path := CONTENT_DIR + file_name
			var res = load(path)
			if res and res.get("content_id") != "":
				_content_pool.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()


## 每次进入休息区时调用，决定推送什么新内容
func on_enter_rest_area() -> void:
	var candidates := _get_eligible_content()
	if candidates.is_empty():
		return

	# 按权重降序排序
	candidates.sort_custom(func(a, b) -> bool:
		return a.push_weight > b.push_weight
	)

	# 推送前 N 个
	var to_push := candidates.slice(0, mini(max_push_per_visit, candidates.size()))
	for content in to_push:
		_push_content(content)


## 获取所有满足推送条件的未推送内容
func _get_eligible_content() -> Array:
	var result: Array = []
	for content in _content_pool:
		if content.pushed:
			continue
		if _check_conditions(content):
			result.append(content)
	return result


## 检查单个内容的推送条件
func _check_conditions(content) -> bool:
	# 探索度
	if ExplorationProgress:
		if ExplorationProgress.get_exploration_value() < content.min_exploration:
			return false

	# 天数范围
	if GameManager.current_day_number < content.min_day:
		return false
	if GameManager.current_day_number > content.max_day:
		return false

	# 标记
	for flag in content.required_flags:
		if not DialogueManager.has_flag(flag):
			return false

	# 前置任务
	for qid in content.required_quests_completed:
		if not QuestManager.is_quest_completed(qid):
			return false

	# 前置对话图
	for gid in content.required_graphs_completed:
		if not DialogueManager.is_graph_completed(gid):
			return false

	# 前置内容
	for cid in content.required_content_completed:
		if not _pushed_content.has(cid):
			return false

	return true


## 执行推送
func _push_content(content) -> void:
	content.pushed = true
	_pushed_content.append(content.content_id)
	content_pushed.emit(content)

	var content_type = content.content_type

	if content_type == 3:  # NPC_SPAWN
		var npc_id: String = content.params.get("npc_id", "")
		var graph_id: String = content.params.get("graph_id", "")
		npc_should_spawn.emit(npc_id, graph_id)

	elif content_type == 0:  # INTEL
		var flag_name: String = "intel_" + content.content_id
		DialogueManager.set_flag(flag_name)

	elif content_type == 2:  # QUEST_PUSH
		var quest_id: String = content.params.get("quest_id", "")
		if quest_id != "":
			QuestManager.start_quest(quest_id)

	elif content_type == 1:  # EVENT
		var flag_name: String = "event_" + content.content_id
		DialogueManager.set_flag(flag_name)

	elif content_type == 4:  # MAP_MODIFIER
		var flag_name: String = "mapmod_" + content.content_id
		DialogueManager.set_flag(flag_name)


## 手动推送指定内容（调试/脚本用）
func force_push(content_id: String) -> bool:
	for content in _content_pool:
		if content.content_id == content_id and not content.pushed:
			_push_content(content)
			return true
	return false


## 存档
func get_save_data() -> Dictionary:
	return {
		"pushed_content": _pushed_content,
	}


func restore_save_data(data: Dictionary) -> void:
	_pushed_content = data.get("pushed_content", [])
	for content in _content_pool:
		content.pushed = _pushed_content.has(content.content_id)
