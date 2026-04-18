class_name StoryArc
extends Resource
## 支线剧情定义。组织多个 DialogueGraph 为一条支线，用于编辑器总览和游戏内进度展示。

@export var arc_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var graph_ids: Array[String] = []
@export var color: Color = Color.WHITE

# 编辑器元数据：graph_id -> Vector2 节点位置
@export var editor_node_positions: Dictionary = {}
