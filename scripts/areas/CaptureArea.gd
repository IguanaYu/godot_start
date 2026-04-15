## 占领区域脚本（CaptureArea.gd）
## 功能：站区域累计进度占领，完成后获得金币奖励
## 节点结构：Area2D (根节点)
##   ├── AreaSprite (范围指示器)
##   ├── Sprite2D (图标)
##   ├── CollisionShape2D (碰撞体)
##   ├── ProgressBar (进度条)
##   └── Label (标签)

extends Area2D

class_name CaptureArea

## ========== 信号定义 ==========

## 占领完成时发出（向后兼容）
signal capture_completed()

## ========== 可配置变量 ==========

## 占领完成金币奖励
@export var bonus_coins: int = 10
## 玩家在区域内时每秒获得的积分
@export var score_per_second: float = 1.0
## 积分计分间隔（秒）
@export var score_interval: float = 1.0

## ========== 私有变量 ==========

## 进度占领组件
var _capture: ProgressCapture
## 积分计时器
var _score_timer: float = 0.0

## ========== 节点引用 ==========

@onready var area_sprite: Sprite2D = $AreaSprite if has_node("AreaSprite") else null
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

## ========== Godot 生命周期函数 ==========

func _ready() -> void:
	# 创建并挂载 ProgressCapture 组件
	_capture = ProgressCapture.new()
	_capture.name = "ProgressCapture"
	_capture.set_progress_bar($ProgressBar if has_node("ProgressBar") else null)
	add_child(_capture)
	_capture.completed.connect(_on_capture_done)

	# 注册到 GameManager
	GameManager.register_capture_point(self)

func _process(delta: float) -> void:
	if _capture.is_completed():
		return

	# 处理积分计时器
	if _capture.is_player_inside():
		_score_timer += delta
		if _score_timer >= score_interval:
			_score_timer = 0.0
			GameManager.add_coins(int(score_per_second))

## ========== 占领完成 ==========

func _on_capture_done() -> void:
	# 发放占领奖励
	GameManager.add_coins(bonus_coins)
	GameManager.reward_obtained.emit("占领成功！获得 %d 金币" % bonus_coins)

	# 发出向后兼容信号
	capture_completed.emit()

	# 延迟后销毁
	await get_tree().create_timer(0.5).timeout
	queue_free()

## ========== 清理 ==========

func _exit_tree() -> void:
	GameManager.unregister_capture_point(self)
