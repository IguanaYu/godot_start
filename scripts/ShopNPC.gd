## 商店NPC脚本（ShopNPC.gd）
## 功能：处理商店交互，打开商店界面，刷新商品
## 节点结构：继承自 Interactable

extends "res://scripts/Interactable.gd"

class_name ShopNPC

## ========== 信号定义 ==========

## 商品购买时发出（参数：物品数据）
signal item_purchased(item: Resource)

## ========== 可配置变量 ==========

## 商店名称
@export var shop_name: String = "神秘商店"
## 刷新价格
@export var refresh_cost: int = 10
## 商品栏位数量
@export var max_items: int = 3

## ========== 公共变量 ==========

## 商店UI面板引用（由RestArea设置）
var shop_panel: Panel = null

## ========== 私有变量 ==========

## 当前商品列表
var _shop_items: Array = []
## 所有可选商品池
var _all_possible_items: Array = []

## ========== 节点引用 ==========

## 商店系统脚本
@onready var shop_system: Node = null

## ========== Godot 生命周期函数 ==========

func _ready() -> void:
	# 调用父类的_ready
	super._ready()

	# 设置交互提示
	set_interaction_prompt("打开商店")

	# 加载物品池
	_load_item_pool()

	# 生成初始商品
	refresh_shop()

	# 查找ShopSystem脚本
	if shop_panel != null and shop_panel.has_method("open_shop"):
		shop_system = shop_panel

## ========== 商店逻辑 ==========

## 加载物品池
func _load_item_pool() -> void:
	# 这里可以预加载所有物品资源
	# 暂时创建一些示例物品
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
	# 这里创建一些临时物品用于测试
	# 实际使用时应该从.tres文件加载
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

	# 更新UI
	_update_shop_ui()

## 购买商品
func buy_item(index: int) -> void:
	if index < 0 or index >= _shop_items.size():
		return

	var item = _shop_items[index]

	# 检查金币是否足够
	if GameManager.get_coins() < item.price:
		GameManager.reward_obtained.emit("金币不足！")
		return

	# 扣除金币
	GameManager.add_coins(-item.price)

	# 添加到背包
	GameManager.add_item_to_inventory(item)

	# 发出信号
	item_purchased.emit(item)

	# 从商店移除该商品
	_shop_items.remove_at(index)

	# 更新UI
	_update_shop_ui()

	GameManager.reward_obtained.emit("购买了: %s" % item.item_name)

## 更新商店UI
func _update_shop_ui() -> void:
	if shop_panel == null:
		return

	# 查找ShopSystem脚本并更新
	var shop_system = shop_panel.get_node_or_null("ShopSystem")
	if shop_system != null and shop_system.has_method("set_items"):
		shop_system.set_items(_shop_items)

## ========== 交互逻辑 ==========

## 重写交互方法
func interact() -> void:
	# 打开商店UI
	if shop_panel != null:
		shop_panel.visible = true
		_update_shop_ui()
	else:
		push_warning("商店面板未设置！")
