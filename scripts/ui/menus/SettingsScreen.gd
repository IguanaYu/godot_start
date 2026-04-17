extends Control

# 设置界面脚本 - 用于调整游戏音量和显示设置

## 设置面板关闭信号（用于暂停菜单中的返回）
signal settings_closed()

## 是否在暂停菜单中使用（由 PauseMenu 设置）
var is_in_pause_menu: bool = false

## 窗口模式选项
const WINDOW_MODES: Array[String] = ["窗口化", "全屏", "独占全屏"]
const WINDOW_MODE_VALUES: Array[int] = [
	DisplayServer.WINDOW_MODE_WINDOWED,
	DisplayServer.WINDOW_MODE_FULLSCREEN,
	DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN,
]

func _ready():
	# 从GameManager读取当前音量值并设置滑块位置
	_master_slider.value = GameManager.get_master_volume() * 100
	_sfx_slider.value = GameManager.get_sfx_volume() * 100
	_music_slider.value = GameManager.get_music_volume() * 100

	# 更新音量值标签
	_update_volume_labels()

	# 初始化显示设置下拉框
	_init_display_options()

	# 连接按钮信号
	_back_button.pressed.connect(_on_back_button_pressed)

	# 连接滑块信号
	_master_slider.value_changed.connect(_on_master_slider_value_changed)
	_sfx_slider.value_changed.connect(_on_sfx_slider_value_changed)
	_music_slider.value_changed.connect(_on_music_slider_value_changed)

	# 连接显示设置信号
	_window_mode_option.item_selected.connect(_on_window_mode_selected)
	_resolution_option.item_selected.connect(_on_resolution_selected)
	_fps_check_button.toggled.connect(_on_fps_toggle)

	# 初始化性能显示开关状态
	_fps_check_button.set_pressed_no_signal(GameManager.get_show_fps())

	# 应用焦点样式
	_apply_focus_styles()

	# 设置焦点链
	_setup_focus_chain()

	# 默认聚焦到主音量滑块
	_master_slider.grab_focus()

## 主音量滑块值改变时调用
func _on_master_slider_value_changed(value: float):
	var volume: float = value / 100.0
	GameManager.set_master_volume(volume)
	_master_volume_label.text = str(int(value)) + "%"

## 音效音量滑块值改变时调用
func _on_sfx_slider_value_changed(value: float):
	var volume: float = value / 100.0
	GameManager.set_sfx_volume(volume)
	_sfx_volume_label.text = str(int(value)) + "%"

## 背景音乐音量滑块值改变时调用
func _on_music_slider_value_changed(value: float):
	var volume: float = value / 100.0
	GameManager.set_music_volume(volume)
	_music_volume_label.text = str(int(value)) + "%"

## 返回按钮点击时返回开始界面
func _on_back_button_pressed():
	# 如果在暂停菜单中使用，发出信号
	if is_in_pause_menu:
		settings_closed.emit()
	else:
		# 否则返回开始界面（主菜单模式）
		get_tree().change_scene_to_file("res://scenes/ui/menus/StartScreen.tscn")

## 更新所有音量值标签
func _update_volume_labels():
	_master_volume_label.text = str(int(_master_slider.value)) + "%"
	_sfx_volume_label.text = str(int(_sfx_slider.value)) + "%"
	_music_volume_label.text = str(int(_music_slider.value)) + "%"

## 应用焦点视觉样式
func _apply_focus_styles() -> void:
	# 按钮样式
	FocusStyleHelper.apply_button_style(_back_button)

	# 滑块样式：设置滑块步长为 5（每次 A/D 增减 5%）
	_master_slider.step = 5.0
	_sfx_slider.step = 5.0
	_music_slider.step = 5.0

## 设置焦点链
func _setup_focus_chain() -> void:
	var controls := [_master_slider, _sfx_slider, _music_slider, _window_mode_option, _resolution_option, _fps_check_button, _back_button]

	for i in range(controls.size()):
		var ctrl = controls[i]
		var prev_idx = (i - 1 + controls.size()) % controls.size()
		var next_idx = (i + 1) % controls.size()

		ctrl.focus_neighbor_top = controls[prev_idx].get_path()
		ctrl.focus_neighbor_bottom = controls[next_idx].get_path()
		ctrl.focus_previous = controls[prev_idx].get_path()
		ctrl.focus_next = controls[next_idx].get_path()

## 初始化显示设置下拉框
func _init_display_options() -> void:
	# 填充窗口模式选项
	for mode_name in WINDOW_MODES:
		_window_mode_option.add_item(mode_name)
	# 设置当前选中项
	var current_mode = GameManager.get_window_mode()
	for i in range(WINDOW_MODE_VALUES.size()):
		if WINDOW_MODE_VALUES[i] == current_mode:
			_window_mode_option.select(i)
			break

	# 填充分辨率选项
	for res in GameManager.RESOLUTIONS:
		_resolution_option.add_item("%dx%d" % [res.x, res.y])
	# 设置当前选中项
	_resolution_option.select(GameManager.get_resolution_index())

## 窗口模式切换
func _on_window_mode_selected(index: int) -> void:
	if index >= 0 and index < WINDOW_MODE_VALUES.size():
		GameManager.set_window_mode(WINDOW_MODE_VALUES[index])

## 分辨率切换
func _on_resolution_selected(index: int) -> void:
	GameManager.set_resolution_index(index)

## 性能显示开关切换
func _on_fps_toggle(toggled: bool) -> void:
	GameManager.set_show_fps(toggled)

# 节点引用（在场景中自动设置）
@onready var _master_slider: HSlider = $VBoxContainer/MasterVolumeContainer/MasterSlider
@onready var _sfx_slider: HSlider = $VBoxContainer/SfxVolumeContainer/SfxSlider
@onready var _music_slider: HSlider = $VBoxContainer/MusicVolumeContainer/MusicSlider
@onready var _master_volume_label: Label = $VBoxContainer/MasterVolumeContainer/MasterVolumeLabel
@onready var _sfx_volume_label: Label = $VBoxContainer/SfxVolumeContainer/SfxVolumeLabel
@onready var _music_volume_label: Label = $VBoxContainer/MusicVolumeContainer/MusicVolumeLabel
@onready var _window_mode_option: OptionButton = $VBoxContainer/WindowModeContainer/WindowModeOptionButton
@onready var _resolution_option: OptionButton = $VBoxContainer/ResolutionContainer/ResolutionOptionButton
@onready var _fps_check_button: CheckButton = $VBoxContainer/FPSContainer/FPSCheckButton
@onready var _back_button: Button = $VBoxContainer/BackButton
