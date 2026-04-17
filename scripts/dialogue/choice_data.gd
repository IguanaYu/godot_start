class_name ChoiceData
extends Resource
## 对话选项数据。玩家在对话中的选择，可附带条件和动作。

@export var text_key: String = ""
@export var condition: ConditionData = null  ## 显示条件（null = 始终显示）
@export var actions: Array[ActionData] = []  ## 选择后触发的动作
@export var target_node_id: String = ""      ## 下一节点（空 = 按连接走）
