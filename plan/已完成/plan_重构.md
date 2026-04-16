# 收集物系统重构：子类继承 + Resource 继承

## Context

当前 `BaseCollectible` 是一个"万能类"——通过 `CollectibleType` 枚举 + `match` 分发所有类型的行为。所有参数（金币价值、敌人移动速度、占领时间等）都塞在一个 `CollectibleData` 里。配置金币时要忽略巨型变体概率，配置敌人时要忽略占领时间，体验不好。

**目标**：将 BaseCollectible 拆成子类继承体系，每种类型有自己的脚本和 Resource，编辑器中只看到该类型相关的参数。

**碰撞机制**（无需修改）：
- BaseCollectible（`collision_layer=2`, `collision_mask=1`）→ `_on_body_entered` 能检测到 Player（`layer=1`）
- Player 的 HurtArea（`collision_mask=2`）也能检测到 BaseCollectible（`layer=2`）
- 伤害逻辑全部在子类的 `_on_contact()` 中处理，Player 侧 pass

## 架构设计

```
Resource 继承：                          脚本继承：

CollectibleData                         BaseCollectible (Area2D)
├── ItemData                            ├── ItemCollectible
│   (金币、钥匙)                         │   (碰触消失，给奖励)
├── EnemyData                           ├── EnemyCollectible
│   (敌人)                               │   (碰触不消失，扣血，可移动)
└── AreaData                            └── AreaCollectible
    (占领据点)                               (需停留占领，有进度条)
```

---

## Step 1: 拆分 CollectibleData → Resource 继承体系

### 1.1 精简基类 CollectibleData

**文件**: `resources/collectibles/collectible_data.gd`

**删除**：`CollectibleType` 枚举、`collectible_type` 字段、`coin_value`、`health_value`、`reward_text`、`custom_effect`、`capture_time`、`capture_bonus_coins`

**保留**（所有类型通用的字段）：
```gdscript
extends Resource
class_name CollectibleData

## 基础信息
@export var display_name: String = ""
@export_multiline var description: String = ""

## 视觉配置
@export var sprite_texture: Texture2D = null
@export var modulate_color: Color = Color.WHITE
@export var scale: Vector2 = Vector2.ONE
@export var z_index: int = 0

## 碰撞配置
@export var collision_shape_type: String = "circle"
@export var collision_shape_size: Vector2 = Vector2(32, 32)

## 生命周期（0=永久）
@export var lifetime: float = 0.0

## 动画配置
@export var enable_rotation: bool = false
@export var rotation_speed: float = 180.0
@export var enable_float: bool = false
@export var float_amplitude: float = 10.0
@export var float_frequency: float = 2.0

## 方向指引
@export var show_direction_arrow: bool = false
@export var arrow_color: Color = Color.YELLOW
@export var arrow_show_distance: float = 200.0
@export var arrow_hide_distance: float = 150.0
@export var arrow_priority: int = 0

func is_valid() -> bool:
	return display_name != ""
```

### 1.2 新建 ItemData

**新建**: `resources/collectibles/item_data.gd`

```gdscript
extends CollectibleData
class_name ItemData

@export var coin_value: int = 0
@export var health_value: int = 0
@export var reward_text: String = ""
@export var custom_effect: String = ""
```

### 1.3 新建 EnemyData

**新建**: `resources/collectibles/enemy_data.gd`

```gdscript
extends CollectibleData
class_name EnemyData

@export var damage_value: int = 1
@export var interaction_cooldown: float = 0.5
@export var can_be_killed_by_star: bool = true
@export var move_speed: float = 50.0
@export var move_distance: float = 100.0
@export var static_chance: float = 0.5
@export var giant_variant_chance: float = 0.2
@export var giant_scale_multiplier: float = 2.0
```

### 1.4 新建 AreaData

**新建**: `resources/collectibles/area_data.gd`

```gdscript
extends CollectibleData
class_name AreaData

@export var capture_time: float = 5.0
@export var capture_bonus_coins: int = 0
```

---

## Step 2: 拆分 BaseCollectible → 脚本继承体系

### 2.1 精简 BaseCollectible 基类

**文件**: `scripts/collectibles/base_collectible.gd`

基类只保留通用逻辑，定义虚方法 `_on_contact(player)` 供子类覆盖。

**删除**：所有类型分支判断（`_handle_interaction`、`_on_collected`、`_on_trigger`、`_process_area_capture`、`_on_capture_completed`、`_handle_custom_effect`）、`capture_area_completed` 信号、`_capture_progress` 变量

**保留**：节点引用、`_initial_y`、`_float_timer`、`_player_in_range`、`trigger_activated` 信号

核心变更：
```gdscript
extends Area2D
class_name BaseCollectible

@export var collectible_data: CollectibleData = null

# 节点引用保持不变
# 私有变量精简为：_initial_y, _float_timer, _player_in_range
# 信号保留：trigger_activated

func _ready() -> void:
	_apply_collectible_data()    # 保持不变
	_setup_collision()           # 保持不变
	_setup_visuals()             # 改为空方法，子类可覆盖
	_register_direction_indicator()  # 保持不变
	_connect_signals()           # 保持不变

func _physics_process(delta: float) -> void:
	if collectible_data == null: return
	if collectible_data.enable_rotation:
		rotation_degrees += collectible_data.rotation_speed * delta
	if collectible_data.enable_float:
		_float_timer += delta
		var offset = sin(_float_timer * collectible_data.float_frequency * TAU) * collectible_data.float_amplitude
		global_position.y = _initial_y + offset

# 碰撞处理 - 调用虚方法
func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_in_range = true
		_on_contact(body)

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_in_range = false

# 虚方法 - 子类覆盖
func _on_contact(_player: Player) -> void:
	pass

func _setup_visuals() -> void:
	pass

# 公共方法
func destroy() -> void:
	_unregister_direction_indicator()
	queue_free()

# _apply_collectible_data 保持不变（第73-112行）
# _setup_collision 保持不变（第114-117行）
# _connect_signals 保持不变（第132-136行）
# _register_direction_indicator 保持不变（第140-158行）
# _unregister_direction_indicator 保持不变（第160-164行）
# _on_lifetime_timeout 调用 destroy()
```

### 2.2 新建 ItemCollectible

**新建**: `scripts/collectibles/item_collectible.gd`

```gdscript
extends BaseCollectible
class_name ItemCollectible

func _on_contact(_player: Player) -> void:
	var data: ItemData = collectible_data as ItemData
	if data == null: return

	if data.coin_value > 0:
		GameManager.add_coins(data.coin_value)
	if data.health_value > 0:
		GameManager.heal_player(data.health_value)
	if not data.reward_text.is_empty():
		GameManager.reward_obtained.emit(data.reward_text)
	if data.custom_effect == "red_key":
		GameManager.on_red_key_collected()

	_unregister_direction_indicator()
	queue_free()
```

### 2.3 新建 EnemyCollectible

**新建**: `scripts/collectibles/enemy_collectible.gd`

```gdscript
extends BaseCollectible
class_name EnemyCollectible

var _behavior_type: int = 0
var _target_position: Vector2
var _is_moving: bool = false
var _wait_timer: float = 0.0
var _is_giant: bool = false
var _cooldown_timer: float = 0.0

func _ready() -> void:
	super._ready()
	_initialize_enemy()

func _initialize_enemy() -> void:
	var data: EnemyData = collectible_data as EnemyData
	if data == null: return

	_is_giant = randf() < data.giant_variant_chance
	if _is_giant:
		scale *= data.giant_scale_multiplier
		if sprite != null:
			sprite.modulate = Color.RED

	if randf() < data.static_chance:
		_behavior_type = 0
	else:
		_behavior_type = 1
		_pick_random_target_position()

	GameManager.register_enemy(self)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	var data: EnemyData = collectible_data as EnemyData
	if data == null: return

	if _behavior_type == 1:
		_process_random_move(delta)
	if _cooldown_timer > 0:
		_cooldown_timer -= delta

func _on_contact(_player: Player) -> void:
	var data: EnemyData = collectible_data as EnemyData
	if data == null: return
	if _cooldown_timer > 0: return

	if _player.is_star_invincible() and data.can_be_killed_by_star:
		destroy()
		return

	if not _player.is_invincible():
		_player.take_damage(data.damage_value)
	_cooldown_timer = data.interaction_cooldown

func _pick_random_target_position() -> void:
	var data: EnemyData = collectible_data as EnemyData
	if data == null: return
	var angle = randf() * TAU
	var dist = randf() * data.move_distance
	_target_position = global_position + Vector2.from_angle(angle) * dist
	_is_moving = true

func _process_random_move(delta: float) -> void:
	var data: EnemyData = collectible_data as EnemyData
	if data == null: return
	if _is_moving:
		var dir = (_target_position - global_position).normalized()
		global_position += dir * data.move_speed * delta
		if global_position.distance_to(_target_position) < 5.0:
			_is_moving = false
			_wait_timer = randf_range(1.0, 3.0)
	else:
		_wait_timer -= delta
		if _wait_timer <= 0:
			_pick_random_target_position()

func destroy() -> void:
	GameManager.unregister_enemy(self)
	super.destroy()

func is_giant() -> bool:
	return _is_giant
```

### 2.4 新建 AreaCollectible

**新建**: `scripts/collectibles/area_collectible.gd`

```gdscript
extends BaseCollectible
class_name AreaCollectible

signal capture_completed()

var _capture_progress: float = 0.0

func _setup_visuals() -> void:
	var data: AreaData = collectible_data as AreaData
	if data == null: return
	if area_sprite != null:
		area_sprite.visible = true
		area_sprite.color = data.modulate_color
		area_sprite.color.a = 0.3
		area_sprite.size = data.collision_shape_size
		area_sprite.position = -data.collision_shape_size / 2.0

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	var data: AreaData = collectible_data as AreaData
	if data == null: return
	if not _player_in_range: return

	_capture_progress += delta
	if progress_bar != null:
		progress_bar.visible = true
		progress_bar.value = (_capture_progress / data.capture_time) * 100.0
	if _capture_progress >= data.capture_time:
		if data.capture_bonus_coins > 0:
			GameManager.add_coins(data.capture_bonus_coins)
		_unregister_direction_indicator()
		capture_completed.emit()
		queue_free()

func _on_contact(_player: Player) -> void:
	pass  # 占领在 _physics_process 中处理

func _on_body_exited(body: Node2D) -> void:
	super._on_body_exited(body)
	_capture_progress = 0.0
	if progress_bar != null:
		progress_bar.value = 0.0
```

---

## Step 3: 创建新场景文件

每种子类需要自己的 .tscn（节点结构与 BaseCollectible.tscn 相同，脚本路径不同）。

### 3.1 ItemCollectible.tscn

**新建**: `scenes/collectibles/ItemCollectible.tscn`

- 基于 BaseCollectible.tscn 复制
- `script` 改为 `res://scripts/collectibles/item_collectible.gd`
- 节点名改为 `ItemCollectible`
- 移除 AreaSprite 和 ProgressBar（物品不需要）

### 3.2 EnemyCollectible.tscn

**新建**: `scenes/collectibles/EnemyCollectible.tscn`

- 基于 BaseCollectible.tscn 复制
- `script` 改为 `res://scripts/collectibles/enemy_collectible.gd`
- 节点名改为 `EnemyCollectible`
- 移除 AreaSprite 和 ProgressBar（敌人不需要）

### 3.3 AreaCollectible.tscn

**新建**: `scenes/collectibles/AreaCollectible.tscn`

- 基于 BaseCollectible.tscn 复制
- `script` 改为 `res://scripts/collectibles/area_collectible.gd`
- 节点名改为 `AreaCollectible`
- 保留 AreaSprite 和 ProgressBar（区域需要）

---

## Step 4: 更新资源文件

### 4.1 金币/钥匙改用 ItemData

修改现有 .tres 文件，将 `script` 从 `CollectibleData` 改为 `ItemData`：
- `resources/collectibles/coin.tres`
- `resources/collectibles/giant_coin.tres`
- `resources/collectibles/red_key.tres`

### 4.2 新建敌人资源

**新建**: `resources/collectibles/enemy.tres`

使用 EnemyData 脚本，配置敌人专属参数。

### 4.3 占领据点改用 AreaData

- `resources/collectibles/capture_area.tres` → script 改为 AreaData

---

## Step 5: 修改 Spawner

**文件**: `scripts/Spawner.gd`

**预加载替换**：
```gdscript
# 旧
var base_collectible_scene = preload("res://scenes/collectibles/BaseCollectible.tscn")
var coin_data: CollectibleData = preload(...)

# 新
var item_collectible_scene = preload("res://scenes/collectibles/ItemCollectible.tscn")
var enemy_collectible_scene = preload("res://scenes/collectibles/EnemyCollectible.tscn")
var area_collectible_scene = preload("res://scenes/collectibles/AreaCollectible.tscn")

var coin_data: ItemData = preload("res://resources/collectibles/coin.tres")
var giant_coin_data: ItemData = preload("res://resources/collectibles/giant_coin.tres")
var red_key_data: ItemData = preload("res://resources/collectibles/red_key.tres")
var capture_area_data: AreaData = preload("res://resources/collectibles/capture_area.tres")
var enemy_data: EnemyData = preload("res://resources/collectibles/enemy.tres")

@export var use_new_enemy_system: bool = false
```

**生成方法修改**：所有 `_spawn_*` 使用对应场景和数据类型实例化。`_spawn_enemy()` 根据 `use_new_enemy_system` 选择旧 `Enemy` 或新 `EnemyCollectible`。

---

## Step 6: 修改 Player 碰撞检测

**文件**: `scripts/Player.gd` 第276-286行

```gdscript
func _on_hurt_area_body_entered(body: Node2D) -> void:
	if body is Enemy:
		var enemy: Enemy = body as Enemy
		if _is_star_invincible:
			enemy.destroy()
		else:
			take_damage(1)
	elif body is EnemyCollectible:
		pass  # 伤害逻辑已在 EnemyCollectible._on_contact 中处理
```

> 双重检测说明：EnemyCollectible 的 `collision_mask=1`（继承自 BaseCollectible）能直接检测到 Player。同时 Player 的 HurtArea 也会检测到 EnemyCollectible。伤害全部在 EnemyCollectible 侧处理，Player 侧 pass。

---

## Step 7: GameManager 无需修改

`clear_all_enemies()` 对 `_active_enemies` 数组中的每个元素调用 `destroy()`。新 `EnemyCollectible` 注册到同一个数组，且有自己的 `destroy()` 方法（调用 `unregister_enemy` + `queue_free`），无需改动 GameManager。

---

## 文件清单

| 操作 | 文件 | 说明 |
|------|------|------|
| 修改 | `resources/collectibles/collectible_data.gd` | 精简为基类 |
| 新建 | `resources/collectibles/item_data.gd` | 物品 Resource |
| 新建 | `resources/collectibles/enemy_data.gd` | 敌人 Resource |
| 新建 | `resources/collectibles/area_data.gd` | 区域 Resource |
| 修改 | `scripts/collectibles/base_collectible.gd` | 精简为基类 + 虚方法 |
| 新建 | `scripts/collectibles/item_collectible.gd` | 物品脚本 |
| 新建 | `scripts/collectibles/enemy_collectible.gd` | 敌人脚本 |
| 新建 | `scripts/collectibles/area_collectible.gd` | 区域脚本 |
| 新建 | `scenes/collectibles/ItemCollectible.tscn` | 物品场景 |
| 新建 | `scenes/collectibles/EnemyCollectible.tscn` | 敌人场景 |
| 新建 | `scenes/collectibles/AreaCollectible.tscn` | 区域场景 |
| 修改 | `resources/collectibles/coin.tres` | script→ItemData |
| 修改 | `resources/collectibles/giant_coin.tres` | script→ItemData |
| 修改 | `resources/collectibles/red_key.tres` | script→ItemData |
| 修改 | `resources/collectibles/capture_area.tres` | script→AreaData |
| 新建 | `resources/collectibles/enemy.tres` | 敌人资源 |
| 修改 | `scripts/Spawner.gd` | 使用新场景和数据类型 |
| 修改 | `scripts/Player.gd` | 添加 EnemyCollectible 检测 |
| 不变 | `scripts/Enemy.gd` | 渐进式迁移，暂保留 |

---

## Verification

1. 编译检查，确保无语法错误
2. 金币：碰触消失 + 加钱，旋转浮动动画正常
3. 敌人（`use_new_enemy_system=true`）：碰触扣血不消失，冷却正常，无敌星秒杀，随机移动，巨型变体
4. 占领据点：站住进度条增长，完成后给奖励消失
5. 旧系统兼容：`use_new_enemy_system=false` 时旧敌人正常
6. `clear_all_enemies()` 能清除新旧两种敌人

运行命令：
```
"E:\godot\Godot_v4.6.1-stable_win64_console.exe" --path "F:\godot_game\run_game\richman"
```
