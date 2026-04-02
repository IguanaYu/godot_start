## 占领区域脚本（CaptureArea.gd）
## 功能：占领后获得金币奖励，持续获得积分
## 继承自 BaseArea

extends BaseArea

class_name CaptureArea

## ========== 信号定义 ==========

## 占领完成时发出（向后兼容）
signal capture_completed()

## ========== 可配置变量 ==========

## 玩家在区域内时每秒获得的积分
@export var score_per_second: float = 1.0
## 进度计分计时器（秒）
@export var score_interval: float = 1.0

## ========== 私有变量 ==========

## 积分计时器
var _score_timer: float = 0.0

## ========== Godot 生命周期函数 ==========

func _ready() -> void:
	super._ready()

	# 注册到 GameManager
	GameManager.register_capture_point(self)

	# 连接占领完成信号
	capture_area_completed.connect(_on_base_capture_completed)

func _process(delta: float) -> void:
	super._process(delta)

	if _is_completed:
		return

	# 处理积分计时器
	if _player_inside:
		_score_timer += delta
		if _score_timer >= score_interval:
			_score_timer = 0.0
			_grant_in_zone_score()

## ========== 虚函数重写 ==========

## 初始化外观 - 设置蓝色主题
func _initialize_appearance() -> void:
	if area_sprite != null:
		area_sprite.modulate = Color(0.3, 0.5, 0.8, 0.3)
	if sprite != null:
		sprite.modulate = Color.BLUE

## 占领完成后的行为
func _on_capture_completed() -> void:
	# 发放占领奖励
	_grant_capture_bonus()

## ========== 私有方法 ==========

## 基础占领完成回调
func _on_base_capture_completed() -> void:
	# 发出向后兼容信号
	capture_completed.emit()

	# 延迟后销毁
	await get_tree().create_timer(0.5).timeout
	queue_free()

## 发放区域内积分奖励
func _grant_in_zone_score() -> void:
	GameManager.add_coins(int(score_per_second))

## 发放占领完成奖励
func _grant_capture_bonus() -> void:
	# 增加金币和积分
	GameManager.add_coins(capture_bonus_coins)
	GameManager.reward_obtained.emit("占领成功！获得 %d 金币" % capture_bonus_coins)

## ========== 清理 ==========

func _exit_tree() -> void:
	# 从 GameManager 中移除
	GameManager.unregister_capture_point(self)
