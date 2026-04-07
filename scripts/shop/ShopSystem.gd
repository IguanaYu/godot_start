## 商店系统脚本（ShopSystem.gd）
## 功能：管理商店UI显示，处理商品购买和刷新
## 附加到：商店UI面板

extends Panel

class_name ShopPanelUI

## ========== 可配置变量 ==========

## 刷新价格
@export var refresh_price: int = 10

## ========== 节点引用 ==========

## 商店标题
@onready var title_label: Label = $VBoxContainer/TitleLabel
## 商品容器
@onready var items_container: VBoxContainer = $VBoxContainer/ItemsContainer
## 刷新按钮
@onready var refresh_button: Button = $VBoxContainer/RefreshButton
## 关闭按钮
@onready var close_button: Button = $VBoxContainer/CloseButton

## ========== 私有变量 ==========

## 当前商品列表
var _current_items: Array = []
## 当前ShopNPC引用
var _current_shop_npc: Node = null
## 商品槽位数组
var _item_slots: Array = []

## ========== Godot 生命周期函数 ==========

func _ready() -> void:
	# 连接按钮信号
	if refresh_button != null:
		refresh_button.pressed.connect(_on_refresh_button_pressed)
	if close_button != null:
		close_button.pressed.connect(_on_close_button_pressed)

	# 创建商品槽位
	_create_item_slots()

	# 更新刷新按钮文本
	_update_refresh_button()

## ========== UI创建 ==========

## 创建商品槽位
func _create_item_slots() -> void:
	if items_container == null:
		return

	# 清空现有槽位
	for child in items_container.get_children():
		child.queue_free()

	_item_slots.clear()

	# 创建3个商品槽位
	for i in range(3):
		var slot = _create_item_slot(i)
		items_container.add_child(slot)
		_item_slots.append(slot)

## 创建单个商品槽位
func _create_item_slot(index: int) -> Panel:
	var slot = Panel.new()
	slot.custom_minimum_size = Vector2(400, 100)

	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE)
	slot.add_child(vbox)

	# 商品名称
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = "空槽位"
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# 商品描述
	var desc_label = Label.new()
	desc_label.name = "DescLabel"
	desc_label.text = ""
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(desc_label)

	# 底部容器（价格+购买按钮）
	var hbox = HBoxContainer.new()
	vbox.add_child(hbox)

	# 价格标签
	var price_label = Label.new()
	price_label.name = "PriceLabel"
	price_label.text = ""
	price_label.add_theme_font_size_override("font_size", 18)
	price_label.custom_minimum_size = Vector2(200, 0)
	hbox.add_child(price_label)

	# 购买按钮
	var buy_button = Button.new()
	buy_button.name = "BuyButton"
	buy_button.text = "购买"
	buy_button.custom_minimum_size = Vector2(150, 40)
	buy_button.pressed.connect(_on_buy_button_pressed.bind(index))
	hbox.add_child(buy_button)

	return slot

## ========== 公共方法 ==========

## 设置商品列表
func set_items(items: Array) -> void:
	_current_items = items
	_update_item_slots()

## 设置当前商店NPC
func set_shop_npc(npc: Node) -> void:
	_current_shop_npc = npc

## ========== UI更新 ==========

## 更新商品槽位显示
func _update_item_slots() -> void:
	for i in range(_item_slots.size()):
		var slot = _item_slots[i]
		if slot == null:
			continue

		var name_label = slot.get_node_or_null("VBoxContainer/NameLabel")
		var desc_label = slot.get_node_or_null("VBoxContainer/DescLabel")
		var price_label = slot.get_node_or_null("VBoxContainer/HBoxContainer/PriceLabel")
		var buy_button = slot.get_node_or_null("VBoxContainer/HBoxContainer/BuyButton")

		if i < _current_items.size():
			# 有商品
			var item = _current_items[i]
			if name_label != null:
				name_label.text = item.item_name
			if desc_label != null:
				desc_label.text = item.get_display_description()
			if price_label != null:
				price_label.text = "价格: %d 金币" % item.price
			if buy_button != null:
				buy_button.disabled = GameManager.get_coins() < item.price
				buy_button.text = "购买"
		else:
			# 空槽位
			if name_label != null:
				name_label.text = "空槽位"
			if desc_label != null:
				desc_label.text = ""
			if price_label != null:
				price_label.text = ""
			if buy_button != null:
				buy_button.disabled = true
				buy_button.text = "无商品"

## 更新刷新按钮
func _update_refresh_button() -> void:
	if refresh_button != null:
		refresh_button.text = "刷新商品 (%d金币)" % refresh_price

## ========== 信号回调 ==========

## 购买按钮按下
func _on_buy_button_pressed(index: int) -> void:
	if _current_shop_npc != null and index < _current_items.size():
		_current_shop_npc.buy_item(index)
		_update_item_slots()
		_update_refresh_button()

## 刷新按钮按下
func _on_refresh_button_pressed() -> void:
	# 检查金币
	if GameManager.get_coins() < refresh_price:
		GameManager.reward_obtained.emit("金币不足！无法刷新")
		return

	# 扣除金币
	GameManager.add_coins(-refresh_price)

	# 刷新商品
	if _current_shop_npc != null:
		_current_shop_npc.refresh_shop()

	GameManager.reward_obtained.emit("商店已刷新！")

## 关闭按钮按下
func _on_close_button_pressed() -> void:
	visible = false
