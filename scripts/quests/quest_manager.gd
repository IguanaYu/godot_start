extends Node
## 任务壳子管理器。只管理任务的 locked/active/completed 三态。
## 具体任务的判定逻辑以后再实现。

signal quest_started(quest_id: String)
signal quest_completed(quest_id: String)
signal quest_state_changed(quest_id: String, new_state: String)

const QUEST_DIR := "res://resources/quests/"

enum State { LOCKED, ACTIVE, COMPLETED }

# 任务定义（从 .tres 加载）
var _definitions: Dictionary = {}
# 任务运行时状态
var _states: Dictionary = {}


func _ready() -> void:
	_load_all_quests()


func _load_all_quests() -> void:
	var dir := DirAccess.open(QUEST_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var path := QUEST_DIR + file_name
			var res = load(path)
			if res and res.get("quest_id") != "":
				_definitions[res.quest_id] = res
				_states[res.quest_id] = State.LOCKED
		file_name = dir.get_next()
	dir.list_dir_end()


func start_quest(quest_id: String) -> bool:
	if not _definitions.has(quest_id):
		push_warning("QuestManager: 任务不存在 '%s'" % quest_id)
		return false
	if _states[quest_id] != State.LOCKED:
		return false
	_states[quest_id] = State.ACTIVE
	quest_started.emit(quest_id)
	quest_state_changed.emit(quest_id, "active")
	return true


func complete_quest(quest_id: String) -> bool:
	if not _definitions.has(quest_id):
		push_warning("QuestManager: 任务不存在 '%s'" % quest_id)
		return false
	if _states[quest_id] != State.ACTIVE:
		return false
	_states[quest_id] = State.COMPLETED
	quest_completed.emit(quest_id)
	quest_state_changed.emit(quest_id, "completed")
	return true


func get_quest_state(quest_id: String) -> String:
	if not _states.has(quest_id):
		return "unknown"
	match _states[quest_id]:
		State.LOCKED: return "locked"
		State.ACTIVE: return "active"
		State.COMPLETED: return "completed"
	return "unknown"


func is_quest_completed(quest_id: String) -> bool:
	return _states.get(quest_id, State.LOCKED) == State.COMPLETED


func is_quest_active(quest_id: String) -> bool:
	return _states.get(quest_id, State.LOCKED) == State.ACTIVE


func get_active_quests() -> Array[String]:
	var result: Array[String] = []
	for qid in _states:
		if _states[qid] == State.ACTIVE:
			result.append(qid)
	return result


func get_completed_quests() -> Array[String]:
	var result: Array[String] = []
	for qid in _states:
		if _states[qid] == State.COMPLETED:
			result.append(qid)
	return result


## 存档相关
func get_save_data() -> Dictionary:
	var data: Dictionary = {}
	for qid in _states:
		data[qid] = get_quest_state(qid)
	return data


func restore_save_data(data: Dictionary) -> void:
	_states.clear()
	for qid in _definitions:
		if data.has(qid):
			match data[qid]:
				"locked": _states[qid] = State.LOCKED
				"active": _states[qid] = State.ACTIVE
				"completed": _states[qid] = State.COMPLETED
				_: _states[qid] = State.LOCKED
		else:
			_states[qid] = State.LOCKED
