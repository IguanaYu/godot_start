## UI 管理器脚本（UIManager.gd）
## 功能：处理游戏中所有 UI 的更新和显示
## 节点结构：CanvasLayer 下的 Control 节点

extends CanvasLayer

class_name UIManager

## ========== 节点引用 ==========

## 血量条引用
@onready var hp_bar: TextureProgressBar = $HPBar
## 金币标签引用
@onready var coin_label: Label = $CoinLabel
## 奖励提示标签引用
@onready var reward_popup: Label = $RewardPopup
## 游戏结束面板引用
@onready var game_over_panel: Panel = $GameOverPanel if has_node("GameOverPanel") else null
## 最终分数标签引用
@onready var final_score_label: Label = $GameOverPanel/FinalScoreLabel if has_node("GameOverPanel/FinalScoreLabel") else null

## ========== 私有变量 ==========

## 奖励提示显示计时器
var _reward_popup_timer: float = 0.0
## 奖励提示显示时间
var _reward_popup_duration: float = 2.0

## ========== Godot 生命周期函数 ==========

func _ready() -> void:
	# 隐藏奖励提示
	if reward_popup != null:
		reward_popup.visible = false

	# 连接 GameManager 信号
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.health_changed.connect(_on_health_changed)
	GameManager.reward_obtained.connect(_on_reward_obtained)
	GameManager.player_died.connect(_on_player_died)

	# 初始化 UI
	_update_hp_display()
	_update_coin_display()

## ========== 处理逻辑 ==========

func _process(delta: float) -> void:
	# 处理奖励提示计时器
	if _reward_popup_timer > 0:
		_reward_popup_timer -= delta
		if _reward_popup_timer <= 0 and reward_popup != null:
			reward_popup.visible = false

## ========== UI 更新函数 ==========

## 更新血量条显示
func _update_hp_display() -> void:
	if hp_bar == null:
		return

	var current_hp: int = GameManager.get_health()
	var max_hp: int = GameManager.max_health
	var hp_percentage: float = float(current_hp) / float(max_hp) * 100.0

	hp_bar.value = hp_percentage

	# 根据血量改变颜色
	if hp_percentage > 60.0:
		hp_bar.tint_progress = Color.GREEN
	elif hp_percentage > 30.0:
		hp_bar.tint_progress = Color.YELLOW
	else:
		hp_bar.tint_progress = Color.RED

## 更新金币显示
func _update_coin_display() -> void:
	if coin_label == null:
		return

	var coins: int = GameManager.get_coins()
	coin_label.text = "金币: %d" % coins

## 显示奖励提示
func _show_reward_popup(text: String) -> void:
	if reward_popup == null:
		return

	reward_popup.text = text
	reward_popup.visible = true
	_reward_popup_timer = _reward_popup_duration

## 显示游戏结束界面
func _show_game_over() -> void:
	if game_over_panel == null:
		return

	game_over_panel.visible = true

	if final_score_label != null:
		var final_coins: int = GameManager.get_coins()
		final_score_label.text = "最终得分: %d 金币" % final_coins

## ========== 信号回调 ==========

## 金币数量变化
func _on_coins_changed(new_coins: int) -> void:
	_update_coin_display()

## 生命值变化
func _on_health_changed(new_health: int) -> void:
	_update_hp_display()

## 获得奖励
func _on_reward_obtained(reward_text: String) -> void:
	_show_reward_popup(reward_text)

## 玩家死亡
func _on_player_died() -> void:
	_show_game_over()

## ========== 公共方法 ==========

## 更新所有 UI
func update_all_ui() -> void:
	_update_hp_display()
	_update_coin_display()
