## 暂停菜单脚本（PauseMenu.gd）
## 功能：游戏中按 ESC 键显示的暂停菜单
extends CanvasLayer

class_name PauseMenu

## ========== 信号定义 ==========

signal resume_requested()
signal main_menu_requested()
signal quit_requested()

## ========== 节点引用 ==========

@onready var pause_panel: Panel = $PausePanel
@onready var settings_screen: Control = $SettingsScreen

@onready var resume_button: Button = $PausePanel/VBoxContainer/ResumeButton
@onready var settings_button: Button = $PausePanel/VBoxContainer/SettingsButton
@onready var main_menu_button: Button = $PausePanel/VBoxContainer/MainMenuButton
@onready var quit_button: Button = $PausePanel/VBoxContainer/QuitButton

## ========== 私有变量 ==========

var _is_settings_open: bool = false

## ========== 公共方法 ==========

## 显示暂停菜单
func show_pause_menu() -> void:
	visible = true
	pause_panel.visible = true
	settings_screen.visible = false
	_is_settings_open = false

## 隐藏暂停菜单
func hide_pause_menu() -> void:
	visible = false
	pause_panel.visible = false
	settings_screen.visible = false
	_is_settings_open = false

## 切换设置面板显示
func toggle_settings() -> void:
	_is_settings_open = not _is_settings_open
	pause_panel.visible = not _is_settings_open
	settings_screen.visible = _is_settings_open

## ========== 信号回调 ==========

func _on_resume_button_pressed():
	hide_pause_menu()
	resume_requested.emit()

func _on_settings_button_pressed():
	toggle_settings()

func _on_main_menu_button_pressed():
	hide_pause_menu()
	main_menu_requested.emit()

func _on_quit_button_pressed():
	hide_pause_menu()
	quit_requested.emit()

func _on_settings_back_pressed():
	toggle_settings()

## ========== 生命周期 ==========

func _ready():
	# 设置暂停模式，确保在游戏暂停时仍可处理输入
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	pause_panel.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	settings_screen.process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	# 标记 SettingsScreen 为暂停菜单模式
	if settings_screen != null and settings_screen.has_method("set"):
		settings_screen.is_in_pause_menu = true

	# 连接按钮信号
	resume_button.pressed.connect(_on_resume_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)

	# 连接 SettingsScreen 的返回按钮
	var settings_back = settings_screen.get_node("VBoxContainer/BackButton")
	if settings_back != null:
		settings_back.pressed.connect(_on_settings_back_pressed)

	# 初始隐藏
	visible = false
