class_name IguanaContent
extends Resource
## Iguana 推送内容数据。定义一条可以被 Iguana AI 推送给玩家的内容。

enum ContentType {
	INTEL,
	EVENT,
	NPC_SPAWN,
	QUEST_PUSH,
	MAP_MODIFIER,
}

@export var content_id: String = ""
@export var content_type: ContentType = ContentType.INTEL
@export var display_name_key: String = ""
@export var description_key: String = ""

# 推送条件
@export var min_exploration: float = 0.0
@export var min_day: int = 0
@export var max_day: int = 999
@export var required_flags: Array[String] = []
@export var required_quests_completed: Array[String] = []
@export var required_graphs_completed: Array[String] = []
@export var required_content_completed: Array[String] = []

# 推送权重（高权重优先）
@export var push_weight: float = 1.0

# 内容参数（根据类型不同，参数不同）
@export var params: Dictionary = {}

# 运行时状态
var pushed: bool = false
