extends Control

# 开始界面脚本

func _ready():
	# 连接按钮信号
	$VBoxContainer/StartButton.pressed.connect(_on_start_button_pressed)
	$VBoxContainer/ExitButton.pressed.connect(_on_exit_button_pressed)

func _on_start_button_pressed():
	# 切换到主游戏场景
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_exit_button_pressed():
	# 退出游戏
	get_tree().quit()
