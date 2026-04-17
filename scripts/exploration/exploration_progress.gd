extends Node
## 探索进度管理器。综合多个维度计算 0~1 的探索度。

signal exploration_changed(new_value: float)
signal exploration_milestone_reached(milestone: String)

# 各维度当前值
var quests_completed: int = 0
var total_coins_earned: int = 0
var dialogues_completed: int = 0
var areas_explored: int = 0
var enemies_defeated: int = 0

# 各维度权重
@export var quest_weight: float = 0.4
@export var coin_weight: float = 0.2
@export var dialogue_weight: float = 0.2
@export var area_weight: float = 0.1
@export var combat_weight: float = 0.1

# 各维度归一化参考值（达到此值算该维度满分）
@export var quest_max: int = 20
@export var coin_max: int = 1000
@export var dialogue_max: int = 30
@export var area_max: int = 10
@export var combat_max: int = 100

# 里程碑 {阈值: 里程碑ID}
@export var milestones: Dictionary = {
	0.1: "first_steps",
	0.25: "beginner_explorer",
	0.5: "seasoned_adventurer",
	0.75: "veteran_explorer",
	1.0: "master_explorer",
}

var _current_value: float = 0.0
var _reached_milestones: Array[String] = []


func _ready() -> void:
	# 监听任务完成
	QuestManager.quest_completed.connect(_on_quest_completed)
	# 监听对话图完成
	DialogueManager.dialogue_graph_completed.connect(_on_dialogue_completed)
	# 监听金币变化（累计）
	GameManager.coins_changed.connect(_on_coins_changed)


func get_exploration_value() -> float:
	var quest_ratio := mini(float(quests_completed) / float(quest_max), 1.0)
	var coin_ratio := mini(float(total_coins_earned) / float(coin_max), 1.0)
	var dialogue_ratio := mini(float(dialogues_completed) / float(dialogue_max), 1.0)
	var area_ratio := mini(float(areas_explored) / float(area_max), 1.0)
	var combat_ratio := mini(float(enemies_defeated) / float(combat_max), 1.0)

	_current_value = (
		quest_ratio * quest_weight +
		coin_ratio * coin_weight +
		dialogue_ratio * dialogue_weight +
		area_ratio * area_weight +
		combat_ratio * combat_weight
	)
	return _current_value


func _on_quest_completed(_quest_id: String) -> void:
	quests_completed = QuestManager.get_completed_quests().size()
	_check_milestones_and_notify()


func _on_dialogue_completed(_graph_id: String) -> void:
	dialogues_completed += 1
	_check_milestones_and_notify()


func _on_coins_changed(new_coins: int) -> void:
	# 累计金币（只增不减）
	if new_coins > total_coins_earned:
		total_coins_earned = new_coins
	_check_milestones_and_notify()


func _check_milestones_and_notify() -> void:
	var old_value := _current_value
	var new_value := get_exploration_value()

	if absf(new_value - old_value) > 0.001:
		exploration_changed.emit(new_value)

	# 检查里程碑
	for threshold in milestones:
		var milestone_id: String = milestones[threshold]
		if new_value >= threshold and not _reached_milestones.has(milestone_id):
			_reached_milestones.append(milestone_id)
			DialogueManager.set_flag("exploration_" + milestone_id)
			exploration_milestone_reached.emit(milestone_id)


## 存档
func get_save_data() -> Dictionary:
	return {
		"quests_completed": quests_completed,
		"total_coins_earned": total_coins_earned,
		"dialogues_completed": dialogues_completed,
		"areas_explored": areas_explored,
		"enemies_defeated": enemies_defeated,
		"reached_milestones": _reached_milestones,
	}


func restore_save_data(data: Dictionary) -> void:
	quests_completed = data.get("quests_completed", 0)
	total_coins_earned = data.get("total_coins_earned", 0)
	dialogues_completed = data.get("dialogues_completed", 0)
	areas_explored = data.get("areas_explored", 0)
	enemies_defeated = data.get("enemies_defeated", 0)
	_reached_milestones = data.get("reached_milestones", [])
	_current_value = get_exploration_value()
