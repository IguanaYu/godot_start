class_name DialogueGraph
extends Resource
## 对话图数据。一段完整的对话，由多个节点和连接组成。

@export var graph_id: String = ""
@export var npc_id: String = ""
@export var priority: int = 0
@export var repeatable: bool = false

@export var nodes: Array[DialogueNodeData] = []
@export var connections: Array[DialogueConnection] = []

# ── 前置条件 ──
@export var prerequisite_graph_ids: Array[String] = []
@export var prerequisite_quest_ids: Array[String] = []
@export var prerequisite_min_day: int = 0
@export var prerequisite_min_exploration: float = 0.0
@export var prerequisite_flags: Array[String] = []
@export var prerequisite_logic: String = "AND"  ## "AND" / "OR"

# ── 完成效果 ──
@export var completion_flags_set: Array[String] = []
@export var completion_quest_complete: Array[String] = []
@export var completion_unlock_graphs: Array[String] = []

# ── 编辑器元数据 ──
@export var editor_scroll_offset: Vector2 = Vector2.ZERO
@export var editor_zoom: float = 1.0
