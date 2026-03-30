extends Control

# 开始界面脚本

func _ready():
	# 连接按钮信号
	$VBoxContainer/StartButton.pressed.connect(_on_start_button_pressed)
	$VBoxContainer/SettingsButton.pressed.connect(_on_settings_button_pressed)
	$VBoxContainer/ExitButton.pressed.connect(_on_exit_button_pressed)

func _on_start_button_pressed():
	# 切换到角色选择场景
	get_tree().change_scene_to_file("res://scenes/CharacterSelect.tscn")

func _on_settings_button_pressed():
	# 切换到设置场景
	get_tree().change_scene_to_file("res://scenes/SettingsScreen.tscn")

func _on_exit_button_pressed():
	# 退出游戏
	get_tree().quit()
