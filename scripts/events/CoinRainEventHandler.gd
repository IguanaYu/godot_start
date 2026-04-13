## 金币雨事件处理器（CoinRainEventHandler.gd）
## 功能：金币雨事件，大量刷新金币
extends "res://scripts/events/BaseEventHandler.gd"

## ========== 可配置变量 ==========

## 金币雨总数量
@export var total_coins: int = 30
## 每次刷新数量
@export var coins_per_batch: int = 5
## 刷新间隔（秒）
@export var batch_interval: float = 0.5

## ========== 私有变量 ==========

var _spawned_count: int = 0
var _batch_timer: float = 0.0

## ========== 生命周期方法 ==========

func _on_event_started() -> void:
	_spawned_count = 0
	_batch_timer = 0.0
	set_process(true)
	print("[Event] 金币雨开始！预计 %d 个金币" % total_coins)

func _process(delta: float) -> void:
	if _spawned_count >= total_coins:
		set_process(false)
		_complete_event()
		return

	_batch_timer -= delta
	if _batch_timer <= 0:
		var remaining = total_coins - _spawned_count
		var batch = mini(coins_per_batch, remaining)
		if spawn_manager != null:
			spawn_manager.spawn_coin_immediate(batch)
		_spawned_count += batch
		_batch_timer = batch_interval

func _on_event_cleanup() -> void:
	set_process(false)
