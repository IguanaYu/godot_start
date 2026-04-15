## 地图选择面板脚本（MapSelectPanel.gd）
## 功能：展示可选地图列表，供玩家选择目的地
## 节点结构：Panel (根节点)
##   └── VBoxContainer
##       ├── TitleLabel — 标题
##       ├── MapsContainer (VBoxContainer) — 地图按钮容器
##       └── CloseButton — 关闭按钮

extends Panel

## ========== 信号定义 ==========

## 玩家选择了一张地图时发出
signal map_chosen(map_config: MapConfig)

## ========== 节点引用 ==========

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var maps_container: VBoxContainer = $VBoxContainer/MapsContainer
@onready var close_button: Button = $VBoxContainer/CloseButton

## ========== Godot 生命周期函数 ==========

func _ready() -> void:
	close_button.pressed.connect(_on_close)
	visible = false

## ========== 公共方法 ==========

## 显示面板并填充地图按钮
func show_with_maps(maps: Array) -> void:
	# 清空旧按钮
	for child in maps_container.get_children():
		child.queue_free()

	# 为每张地图创建按钮
	for mc in maps:
		var btn = Button.new()
		btn.text = "%s — %s" % [mc.map_name, mc.description]
		btn.custom_minimum_size = Vector2(300, 50)
		btn.pressed.connect(_on_map_button.bind(mc))
		maps_container.add_child(btn)

	visible = true

## ========== 信号回调 ==========

func _on_map_button(mc: MapConfig) -> void:
	visible = false
	map_chosen.emit(mc)

func _on_close() -> void:
	visible = false
