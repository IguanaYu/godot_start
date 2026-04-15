## 石碑脚本（Stele.gd）
## 功能：站区域累计进度占领，完成后解锁新的 SpawnEntry
## 节点结构：Area2D (根节点)
##   ├── AreaSprite (范围指示器)
##   ├── Sprite2D (图标)
##   ├── CollisionShape2D (碰撞体)
##   ├── ProgressBar (进度条)
##   └── Label (标签)

extends Area2D

## ========== 可配置变量 ==========

## 解锁的 SpawnEntry ID
@export var unlock_entry_id: String = ""
## 解锁后显示的提示文本
@export var unlock_message: String = "解锁了新的刷新条目！"

## ========== 私有变量 ==========

## 进度占领组件
var _capture: ProgressCapture

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

## ========== 占领完成 ==========

func _on_capture_done() -> void:
	if unlock_entry_id == "":
		push_warning("Stele: unlock_entry_id 为空")
		return

	# 完成后变金色
	if area_sprite:
		area_sprite.modulate = Color.GOLD
	if sprite:
		sprite.modulate = Color.GOLD

	# 通过 GameManager.main_scene 获取 SpawnManager 并解锁
	var main_scene = GameManager.main_scene
	if main_scene != null and main_scene.has_method("get_spawner"):
		var spawn_mgr = main_scene.get_spawner()
		if spawn_mgr != null and spawn_mgr.has_method("unlock_entry"):
			spawn_mgr.unlock_entry(unlock_entry_id)
			print("[Stele] 解锁 SpawnEntry: %s" % unlock_entry_id)

	# 显示提示
	GameManager.reward_obtained.emit(unlock_message)

	# 延迟 1 秒后消失（让玩家看到金色完成效果）
	await get_tree().create_timer(1.0).timeout
	queue_free()
