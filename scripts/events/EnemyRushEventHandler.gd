## 敌人突袭事件处理器（EnemyRushEventHandler.gd）
## 功能：短时间内大量刷新敌人
extends "res://scripts/events/BaseEventHandler.gd"

## ========== 可配置变量 ==========

## 突袭敌人数
@export var rush_enemy_count: int = 10
## 每波刷新数量
@export var enemies_per_wave: int = 3
## 波次间隔（秒）
@export var wave_interval: float = 1.0

## ========== 私有变量 ==========

var _spawned_count: int = 0
var _wave_timer: float = 0.0

## ========== 生命周期方法 ==========

func _on_event_started() -> void:
	_spawned_count = 0
	_wave_timer = 0.0
	set_process(true)
	GameConsole.info("[Event] 敌人突袭开始！预计 %d 个敌人" % rush_enemy_count)

func _process(delta: float) -> void:
	if _spawned_count >= rush_enemy_count:
		set_process(false)
		_complete_event()
		return

	_wave_timer -= delta
	if _wave_timer <= 0:
		var remaining = rush_enemy_count - _spawned_count
		var wave = mini(enemies_per_wave, remaining)
		if spawn_manager != null:
			spawn_manager.spawn_enemy_immediate(wave)
		_spawned_count += wave
		_wave_timer = wave_interval

func _on_event_cleanup() -> void:
	set_process(false)
