extends Control

# 设置界面脚本 - 用于调整游戏音量设置

func _ready():
	# 从GameManager读取当前音量值并设置滑块位置
	_master_slider.value = GameManager.get_master_volume() * 100
	_sfx_slider.value = GameManager.get_sfx_volume() * 100
	_music_slider.value = GameManager.get_music_volume() * 100

	# 更新音量值标签
	_update_volume_labels()

	# 连接按钮信号
	_back_button.pressed.connect(_on_back_button_pressed)

	# 连接滑块信号
	_master_slider.value_changed.connect(_on_master_slider_value_changed)
	_sfx_slider.value_changed.connect(_on_sfx_slider_value_changed)
	_music_slider.value_changed.connect(_on_music_slider_value_changed)

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
	get_tree().change_scene_to_file("res://scenes/StartScreen.tscn")

## 更新所有音量值标签
func _update_volume_labels():
	_master_volume_label.text = str(int(_master_slider.value)) + "%"
	_sfx_volume_label.text = str(int(_sfx_slider.value)) + "%"
	_music_volume_label.text = str(int(_music_slider.value)) + "%"

# 节点引用（在场景中自动设置）
@onready var _master_slider: HSlider = $VBoxContainer/MasterVolumeContainer/MasterSlider
@onready var _sfx_slider: HSlider = $VBoxContainer/SfxVolumeContainer/SfxSlider
@onready var _music_slider: HSlider = $VBoxContainer/MusicVolumeContainer/MusicSlider
@onready var _master_volume_label: Label = $VBoxContainer/MasterVolumeContainer/MasterVolumeLabel
@onready var _sfx_volume_label: Label = $VBoxContainer/SfxVolumeContainer/SfxVolumeLabel
@onready var _music_volume_label: Label = $VBoxContainer/MusicVolumeContainer/MusicVolumeLabel
@onready var _back_button: Button = $VBoxContainer/BackButton
