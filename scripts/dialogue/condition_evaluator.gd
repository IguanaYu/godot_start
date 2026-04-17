class_name ConditionEvaluator
extends RefCounted
## 条件评估工具。根据 ConditionData 检查游戏状态。


static func evaluate(condition) -> bool:
	if condition == null:
		return true

	var result := _check(condition)
	if condition.negated:
		return not result
	return result


static func _check(condition) -> bool:
	# condition_type: 0=FLAG_SET, 1=FLAG_NOT_SET, 2=QUEST_COMPLETED, 3=QUEST_ACTIVE
	# 4=MIN_COINS, 5=MIN_DAY, 6=MIN_EXPLORATION, 7=HAS_ITEM, 8=CHARACTER_IS, 9=CUSTOM
	var ctype = condition.condition_type

	match ctype:
		0:  # FLAG_SET
			var flag_name: String = condition.params.get("flag_name", "")
			return DialogueManager.has_flag(flag_name)

		1:  # FLAG_NOT_SET
			var flag_name: String = condition.params.get("flag_name", "")
			return not DialogueManager.has_flag(flag_name)

		2:  # QUEST_COMPLETED
			var quest_id: String = condition.params.get("quest_id", "")
			return QuestManager.is_quest_completed(quest_id)

		3:  # QUEST_ACTIVE
			var quest_id: String = condition.params.get("quest_id", "")
			return QuestManager.is_quest_active(quest_id)

		4:  # MIN_COINS
			var amount: int = condition.params.get("amount", 0)
			return GameManager._coins >= amount

		5:  # MIN_DAY
			var day: int = condition.params.get("day", 0)
			return GameManager.current_day_number >= day

		6:  # MIN_EXPLORATION
			var value: float = condition.params.get("value", 0.0)
			if ExplorationProgress:
				return ExplorationProgress.get_exploration_value() >= value
			return false

		7:  # HAS_ITEM
			return false

		8:  # CHARACTER_IS
			var char_type: String = condition.params.get("character", "")
			if GameManager.selected_character_data:
				return GameManager.selected_character_data.resource_path.find(char_type) >= 0
			return false

		9:  # CUSTOM_EXPRESSION
			return false

		_:
			return false
