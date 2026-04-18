extends Interactable
## 剧情查看 NPC。与玩家交互时打开剧情进度面板。

var _panel: Control = null


func set_panel(panel: Control) -> void:
	_panel = panel


func interact() -> void:
	super.interact()
	if _panel == null:
		return
	if _panel.visible:
		_panel.hide_panel()
	else:
		_panel.show_panel()
