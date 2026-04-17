class_name DialogueNPC
extends Interactable
## 对话 NPC 组件。玩家与之交互时触发对话系统。

@export var npc_id: String = ""
@export var npc_name: String = ""
@export var default_portrait: Texture2D = null


func interact() -> void:
	super.interact()
	if DialogueRunner.is_active():
		return
	var graph := DialogueManager.get_next_graph_for_npc(npc_id)
	if graph:
		DialogueRunner.start_dialogue(graph)
