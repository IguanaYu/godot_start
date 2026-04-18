class_name RewardData
extends Resource
## 奖励数据。可复用的奖励包，可被对话 Action 或任务引用。

enum RewardType { COINS, ITEM, FLAG, MAX_HEALTH }


class RewardEntry extends Resource:
	var reward_type: RewardType = RewardType.COINS
	var amount: int = 0
	var item_id: String = ""
	var flag_name: String = ""


@export var reward_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var entries: Array = []


func grant() -> void:
	## 发放所有奖励。空壳实现，后续填充具体逻辑。
	push_warning("RewardData.grant() 尚未实现: %s" % reward_id)
