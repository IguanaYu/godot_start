class_name ConditionData
extends Resource
## 条件数据。用于对话分支判断和选项显示条件。

enum ConditionType {
	FLAG_SET,
	FLAG_NOT_SET,
	QUEST_COMPLETED,
	QUEST_ACTIVE,
	MIN_COINS,
	MIN_DAY,
	MIN_EXPLORATION,
	HAS_ITEM,
	CHARACTER_IS,
	CUSTOM_EXPRESSION,
}

@export var condition_type: ConditionType = ConditionType.FLAG_SET
@export var params: Dictionary = {}  ## 条件参数，如 {"flag_name": "talked_to_elder"}
@export var negated: bool = false    ## 取反
