## 购买类NPC基类（PurchaseNPC.gd）
## 功能：提供通用的购买系统逻辑
## 继承：Interactable → PurchaseNPC → 具体NPC（ShopNPC等）

extends "res://scripts/Interactable.gd"

class_name PurchaseNPC

## ========== 信号定义 ==========

## 购买完成时发出（参数：购买数据）
signal purchase_completed(data: PurchaseData)

## ========== 可配置变量 ==========

## NPC类型名称
@export var npc_name: String = "NPC"
## UI面板引用（由场景设置）
var ui_panel: Panel = null

## ========== 私有变量 ==========

## 购买数据数组
var _current_options: Array = []

## ========== Godot生命周期函数 ==========

func _ready() -> void:
	# 调用父类_ready
	super._ready()

	# 设置交互提示
	set_interaction_prompt("打开%s" % npc_name)

## ========== 交互逻辑 ==========

## 重写交互方法
func interact() -> void:
	if ui_panel == null:
		GameConsole.warn("%s: UI面板未设置！" % name)
		return

	# 打开UI
	ui_panel.visible = true

	# 设置UI数据
	_setup_ui()

## ========== 虚方法（子类重写） ==========

## 设置UI（子类重写以定制UI）
func _setup_ui() -> void:
	GameConsole.warn("PurchaseNPC._setup_ui() 需要被子类重写！")

## 购买选项（子类重写具体逻辑）
func _purchase_option(data: PurchaseData) -> void:
	GameConsole.warn("PurchaseNPC._purchase_option() 需要被子类重写！")

## ========== 公共方法 ==========

## 检查是否买得起
func _can_afford(price: int) -> bool:
	return GameManager.get_coins() >= price

## 扣除金币
func _deduct_gold(amount: int) -> void:
	GameManager.add_coins(-amount)

## 检查选项是否可购买
func _is_option_purchasable(data: PurchaseData) -> bool:
	if data == null:
		return false
	if not data.is_purchasable():
		return false
	if not _can_afford(data.price):
		return false
	return true

## 购买按钮回调（由UI调用）
func _on_purchase_button_pressed(index: int) -> void:
	if index < 0 or index >= _current_options.size():
		return

	var data: PurchaseData = _current_options[index]

	# 检查是否可购买
	if not data.is_purchasable():
		GameManager.reward_obtained.emit("该选项不可购买")
		return

	# 检查金币
	if not _can_afford(data.price):
		GameManager.reward_obtained.emit("金币不足！需要 %d 金币" % data.price)
		return

	# 扣款
	_deduct_gold(data.price)

	# 执行购买逻辑
	_purchase_option(data)

	# 更新状态
	data.mark_purchased()

	# 发出信号
	purchase_completed.emit(data)

	# 刷新UI
	_setup_ui()

## 获取NPC名称
func get_npc_name() -> String:
	return npc_name
