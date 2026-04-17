extends Control

# 开始界面脚本

func _ready():
	# 连接按钮信号
	$VBoxContainer/StartButton.pressed.connect(_on_start_button_pressed)
	$VBoxContainer/SettingsButton.pressed.connect(_on_settings_button_pressed)
	$VBoxContainer/DialogueTestButton.pressed.connect(_on_dialogue_test_button_pressed)
	$VBoxContainer/ExitButton.pressed.connect(_on_exit_button_pressed)

	# 应用焦点样式
	FocusStyleHelper.apply_to_all_buttons($VBoxContainer)

	# 设置焦点链：上下相邻按钮互为邻居
	$VBoxContainer/StartButton.focus_neighbor_top = $VBoxContainer/ExitButton.get_path()
	$VBoxContainer/StartButton.focus_neighbor_bottom = $VBoxContainer/SettingsButton.get_path()
	$VBoxContainer/SettingsButton.focus_neighbor_top = $VBoxContainer/StartButton.get_path()
	$VBoxContainer/SettingsButton.focus_neighbor_bottom = $VBoxContainer/DialogueTestButton.get_path()
	$VBoxContainer/DialogueTestButton.focus_neighbor_top = $VBoxContainer/SettingsButton.get_path()
	$VBoxContainer/DialogueTestButton.focus_neighbor_bottom = $VBoxContainer/ExitButton.get_path()
	$VBoxContainer/ExitButton.focus_neighbor_top = $VBoxContainer/DialogueTestButton.get_path()
	$VBoxContainer/ExitButton.focus_neighbor_bottom = $VBoxContainer/StartButton.get_path()

	# 默认聚焦到开始游戏按钮
	$VBoxContainer/StartButton.grab_focus()

func _on_start_button_pressed():
	# 切换到角色选择场景
	get_tree().change_scene_to_file("res://scenes/ui/menus/CharacterSelect.tscn")

func _on_settings_button_pressed():
	# 切换到设置场景
	get_tree().change_scene_to_file("res://scenes/ui/menus/SettingsScreen.tscn")

func _on_dialogue_test_button_pressed():
	get_tree().change_scene_to_file("res://scenes/test/DialogueTest.tscn")

func _on_exit_button_pressed():
	# 退出游戏
	get_tree().quit()
