@tool
extends EditorPlugin
## 对话图可视化编辑器插件入口

var _editor_instance: Control = null


func _enter_tree() -> void:
	_editor_instance = preload("res://addons/dialogue_editor/editor/dialogue_editor.tscn").instantiate()
	add_control_to_bottom_panel(_editor_instance, "Dialogue Editor")


func _exit_tree() -> void:
	if _editor_instance:
		remove_control_from_bottom_panel(_editor_instance)
		_editor_instance.queue_free()
		_editor_instance = null
