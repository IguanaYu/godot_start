class_name DialogueNodeData
extends Resource
## 对话节点数据。对话图中的单个节点。

enum NodeType {
	START,
	DIALOGUE,
	CHOICE,
	CONDITION,
	ACTION,
	SUB_DIALOGUE,
	END,
}

@export var node_id: String = ""
@export var node_type: NodeType = NodeType.DIALOGUE
@export var position: Vector2 = Vector2.ZERO

# 文本相关
@export var text_key: String = ""
@export var speaker: String = ""           ## "npc" / "player" / "narrator" / 自定义 NPC ID
@export var portrait_override: Texture2D = null

# 选择相关（仅 CHOICE 类型）
@export var choices: Array[ChoiceData] = []

# 条件相关（仅 CONDITION 类型）
@export var condition: ConditionData = null

# 动作相关（ACTION 类型，或 DIALOGUE 类型附带的动作）
@export var actions: Array[ActionData] = []

# 子对话（仅 SUB_DIALOGUE 类型）
@export var target_graph_id: String = ""
