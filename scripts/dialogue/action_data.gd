class_name ActionData
extends Resource
## 对话动作数据。对话节点执行时触发的游戏事件。

enum ActionType {
	SET_FLAG,
	CLEAR_FLAG,
	GIVE_COINS,
	TAKE_COINS,
	GIVE_ITEM,
	TAKE_ITEM,
	COMPLETE_QUEST,
	START_QUEST,
	UNLOCK_GRAPH,
	TRIGGER_EVENT,
	SPAWN_NPC,
	CHANGE_NPC_STATE,
}

@export var action_type: ActionType = ActionType.SET_FLAG
@export var params: Dictionary = {}
