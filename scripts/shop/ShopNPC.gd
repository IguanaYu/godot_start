## 商店NPC脚本（ShopNPC.gd）
## 功能：处理商店交互，打开商店界面，刷新商品
## 继承：Interactable → PurchaseNPC → ShopNPC

extends "res://scripts/shop/PurchaseNPC.gd"

class_name ShopNPC

## ========== 信号定义 ==========

## 商品购买时发出（参数：物品数据）
signal item_purchased(item: ItemData)

## ========== 可配置变量 ==========

## 商店UI面板引用（直接存储，带setter同步ui_panel）
var shop_panel: Panel = null:
	set(value):
		shop_panel = value
		ui_panel = value  # 同步到父类使用的变量

## 商店名称
@export var shop_name: String = "神秘商店"
## 刷新价格
@export var refresh_cost: int = 10
## 商品栏位数量
@export var max_items: int = 3

## ========== 私有变量 ==========

## 当前商品列表（ItemData数组）
var _shop_items: Array = []
## 所有可选商品池（ItemData数组）
var _all_possible_items: Array = []

## ========== Godot 生命周期函数 ==========

func _ready() -> void:
	# 调用父类_ready
	super._ready()

	# 设置NPC名称
	npc_name = shop_name

	# 加载物品池
	_load_item_pool()

	# 生成初始商品
	refresh_shop()

## ========== 商店逻辑 ==========

## 加载物品池
func _load_item_pool() -> void:
	var items_dir = "res://resources/items/"
	var dir = DirAccess.open(items_dir)
	if dir != null:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var item_path = items_dir + file_name
				var item = load(item_path)
				if item != null and item.is_valid():
					_all_possible_items.append(item)
			file_name = dir.get_next()

	# 如果没有找到物品文件，创建默认物品（临时方案）
	if _all_possible_items.is_empty():
		_create_default_items()

## 创建默认物品（用于测试）
func _create_default_items() -> void:
	push_warning("未找到物品资源文件，使用临时物品")

## 刷新商店商品
func refresh_shop() -> void:
	_shop_items.clear()

	# 随机选择商品
	for i in range(max_items):
		if _all_possible_items.is_empty():
			break
		var random_index = randi() % _all_possible_items.size()
		var item = _all_possible_items[random_index]
		_shop_items.append(item)

	# 同步填充父类的_current_options数组
	_current_options.clear()
	for item in _shop_items:
		_current_options.append(item.to_purchase_data())

	# 更新UI
	_update_shop_ui()

## 购买商品（保留供外部调用）
func buy_item(index: int) -> void:
	if index < 0 or index >= _shop_items.size():
		return

	# 调用基类购买逻辑（_current_options已在refresh_shop中填充）
	_on_purchase_button_pressed(index)

## 更新商店UI
func _update_shop_ui() -> void:
	if shop_panel == null:
		return

	# shop_panel本身就是ShopSystem，直接调用
	if shop_panel.has_method("set_items"):
		shop_panel.set_items(_shop_items)

## ========== 重写PurchaseNPC虚方法 ==========

## 设置UI
func _setup_ui() -> void:
	# 设置ShopSystem的npc引用
	if shop_panel.has_method("set_shop_npc"):
		shop_panel.set_shop_npc(self)

	# 设置商品列表
	if shop_panel.has_method("set_items"):
		shop_panel.set_items(_shop_items)

## 购买选项
func _purchase_option(data: PurchaseData) -> void:
	# 从PurchaseData中提取ItemData
	var item: ItemData = ItemData.from_purchase_data(data)
	if item == null:
		push_error("无法从PurchaseData提取ItemData")
		return

	# 应用物品效果
	item.apply_to_player()

	# 永久物品添加到背包作为记录，消耗品不保留
	if item.is_permanent():
		GameManager.add_item_to_inventory(item)

	# 从商店移除该商品（_shop_items和_current_options同步移除）
	var idx = _shop_items.find(item)
	if idx >= 0:
		_shop_items.remove_at(idx)
		if idx < _current_options.size():
			_current_options.remove_at(idx)

	# 发出信号
	item_purchased.emit(item)

	# 提示消息
	GameManager.reward_obtained.emit("购买了: %s" % item.item_name)
