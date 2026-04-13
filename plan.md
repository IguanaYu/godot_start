# Resource 驱动的刷新管理系统 — 分步可验证实施计划

## Context

当前 `Spawner.gd` 硬编码所有刷新配置（6种实体各自独立计时器），`MainLevel.gd` 用单一 `_game_timer` 管理流程。需要重构为 Resource 驱动的架构，支持昼夜循环、天数递进、多地图、特殊事件等。

**核心原则**：每一步完成后都能独立验证，不依赖后续步骤。游戏在任意步骤之后都应该能正常运行。

**关键决策**：
- DayNightCycleManager → 普通节点（非 Autoload），加入 MainLevel 场景树
- 金币雨逻辑 → 从 GameManager 迁移到 SpawnManager
- 多地图 → 单 MainLevel 场景 + 不同 MapConfig .tres
- SpecialEvent / MapConfig / DayProgressionConfig → 延后到对应步骤创建
- SpawnZoneType 枚举 → 合并到 SpawnZone.gd 内

**验证手段**：
- GUT 单元测试（`tests/unit/` 目录，已有 5 个测试文件）
- 启动游戏运行（`"E:\godot\Godot_v4.6.1-stable_win64_console.exe" --path "F:\godot_game\run_game\richman"`）
- Godot 编辑器 Inspector 检查 .tres 文件

---

## 步骤 1：核心 Resource 脚本 + GUT 测试

**目标**：创建步骤 2-5 需要的 Resource 脚本，用 GUT 测试验证。

**新建文件**：

| 文件 | 说明 |
|------|------|
| `resources/spawn/spawn_entry.gd` | SpawnEntry Resource — 单个可刷新实体定义 |
| `resources/spawn/spawn_phase.gd` | SpawnPhase Resource — 一组 SpawnEntry 组成一个刷新阶段 |
| `resources/spawn/day_night_tier.gd` | DayNightTier Resource — 一个昼夜挡位 |
| `tests/unit/test_spawn_resources.gd` | GUT 测试：3 个 Resource 的 is_valid()、默认值、边界情况 |

**SpawnEntry 设计**（沿用 `resources/collectibles/collectible_data.gd` 模式）：
```gdscript
class_name SpawnEntry
extends Resource

@export var entry_id: String = ""
@export var entity_type: String = ""  # "enemy", "coin", "capture_point", "chest", "giant_coin", "red_key"
@export var scene: PackedScene = null  # 实体场景
@export var collectible_data: CollectibleData = null  # 收集品数据（可选）
@export var spawn_interval: float = 5.0
@export var max_in_scene: int = 30
@export var spawn_count_min: int = 1
@export var spawn_count_max: int = 5
@export var min_offset: float = 50.0
@export var max_offset: float = 300.0
@export var zone_id: String = ""  # 空=默认玩家相对位置
@export var enabled: bool = true
@export var start_delay: float = 0.0  # 首次生成延迟
@export var is_cumulative_timer: bool = false  # true=正计时(巨型金币/红钥匙), false=倒计时

func is_valid() -> bool:
    return entry_id != "" and entity_type != "" and (scene != null or collectible_data != null)
```

**SpawnPhase 设计**：
```gdscript
class_name SpawnPhase
extends Resource

enum Period { DAY, NIGHT }
@export var phase_id: String = ""
@export var period: Period = Period.DAY
@export var entries: Array[SpawnEntry] = []

func get_enabled_entries() -> Array[SpawnEntry]:
    return entries.filter(func(e): return e.enabled and e.is_valid())
func is_valid() -> bool:
    return phase_id != "" and entries.size() > 0
```

**DayNightTier 设计**：
```gdscript
class_name DayNightTier
extends Resource

@export var tier_index: int = 0
@export var day_duration: float = 40.0
@export var night_duration: float = 20.0
@export var difficulty_multiplier: float = 1.0

func is_valid() -> bool:
    return day_duration > 0 and night_duration > 0
```

**验证**：
```
运行 GUT 测试 → tests/unit/test_spawn_resources.gd 全部通过
启动游戏 → 现有功能不受影响（这些脚本未被引用）
```

---

## 步骤 2：SpawnZone 节点 + 位置计算测试

**目标**：创建 SpawnZone 节点，支持 4 种定位模式，替换 Spawner 中的硬编码位置计算。

**新建文件**：

| 文件 | 说明 |
|------|------|
| `scripts/spawn/SpawnZone.gd` | SpawnZone 节点脚本（extends Marker2D），含 ZoneType 枚举 |
| `scenes/spawn/SpawnZone.tscn` | SpawnZone 场景模板 |
| `tests/unit/test_spawn_zone.gd` | GUT 测试：4 种模式的位置计算 |

**SpawnZone 设计**：
```gdscript
class_name SpawnZone
extends Marker2D

enum ZoneType { PLAYER_RELATIVE, AREA_RANDOM, SEMI_RANDOM, FIXED }

@export var zone_id: String = ""
@export var zone_mode: ZoneType = ZoneType.PLAYER_RELATIVE
@export var zone_rect: Rect2 = Rect2(-500, -500, 1000, 1000)  # AREA_RANDOM 用
@export var player_bias: float = 0.7  # SEMI_RANDOM 用

func get_spawn_position(min_offset: float, max_offset: float) -> Vector2:
    match zone_mode:
        ZoneType.PLAYER_RELATIVE: return _player_relative(min_offset, max_offset)
        ZoneType.AREA_RANDOM: return _area_random()
        ZoneType.SEMI_RANDOM: return _semi_random(min_offset, max_offset)
        ZoneType.FIXED: return _fixed()
    return global_position

# PLAYER_RELATIVE 复刻现有 Spawner._get_random_spawn_position()
func _player_relative(min_off, max_off) -> Vector2:
    var player_pos = Vector2.ZERO
    if GameManager.player and is_instance_valid(GameManager.player):
        player_pos = GameManager.player.global_position
    var angle = randf() * TAU
    var dist = randf_range(min_off, max_off)
    return player_pos + Vector2.from_angle(angle) * dist

func _area_random() -> Vector2:
    return Vector2(
        randf_range(zone_rect.position.x, zone_rect.end.x),
        randf_range(zone_rect.position.y, zone_rect.end.y)
    )

func _semi_random(min_off, max_off) -> Vector2:
    if randf() < player_bias:
        return _player_relative(min_off, max_off)
    return _area_random()

func _fixed() -> Vector2:
    var markers = get_children().filter(func(c): return c is Marker2D)
    if markers.is_empty(): return global_position
    return markers[randi() % markers.size()].global_position
```

**验证**：
```
GUT 测试 → test_spawn_zone.gd 通过（各模式返回合理范围内的坐标）
启动游戏 → 现有功能不受影响
```

---

## 步骤 3：SpawnManager 新建（并行于 Spawner）+ 示例 .tres

**目标**：新建 SpawnManager，从 SpawnEntry Resource 读取配置驱动刷新。保留旧 Spawner 不动。

**新建文件**：

| 文件 | 说明 |
|------|------|
| `scripts/SpawnManager.gd` | 数据驱动的刷新管理器 |
| `resources/spawn/entries/coin_entry.tres` | 金币 SpawnEntry |
| `resources/spawn/entries/enemy_entry.tres` | 敌人 SpawnEntry |
| `resources/spawn/entries/capture_entry.tres` | 占领点 SpawnEntry |
| `resources/spawn/entries/chest_entry.tres` | 宝箱 SpawnEntry |
| `resources/spawn/entries/giant_coin_entry.tres` | 巨型金币 SpawnEntry |
| `resources/spawn/entries/red_key_entry.tres` | 红钥匙 SpawnEntry |
| `resources/spawn/phases/default_day_phase.tres` | 默认白天阶段 |
| `resources/spawn/phases/default_night_phase.tres` | 默认黑夜阶段 |
| `tests/unit/test_spawn_manager.gd` | GUT 测试 |

**SpawnManager 核心设计**：
```gdscript
class_name SpawnManager
extends Node2D

signal coin_rain_started(duration: float)
signal coin_rain_ended()

# 公共 API 兼容 Spawner
func pause_spawning() -> void: set_process(false)
func resume_spawning() -> void: set_process(true)
func spawn_coin_immediate(count: int = 1) -> void
func spawn_enemy_immediate(count: int = 1) -> void
func spawn_capture_point_immediate() -> void
func spawn_chest_immediate() -> void
func increase_difficulty(multiplier: float = 2.0) -> void

# 新 API
func configure(phase: SpawnPhase, zone: SpawnZone = null) -> void
func set_active_phase(phase: SpawnPhase) -> void
func unlock_entry(entry_id: String) -> void
```

**关键实现细节**（复刻现有 Spawner 行为）：
- 首次 spawn 前随机化计时器（复刻 Spawner.gd:103-108）
- 实体通过 `get_parent().add_child()` 添加到 MainLevel（复刻 Spawner.gd:160）
- 金币加入 "coins" 组（复刻 Spawner.gd:187）
- 宝箱加入 "chests" 组（复刻 Spawner.gd:231）
- 巨型金币/红钥匙用正计时器（is_cumulative_timer=true，复刻 Spawner.gd:294-325）
- `increase_difficulty()` 只影响 entity_type="enemy" 的 interval（复刻 Spawner.gd:289-290）
- 通过 SpawnZone 计算位置，无 zone 时 fallback 为 PLAYER_RELATIVE 模式

**金币雨迁移**：从 GameManager 迁移到 SpawnManager：
- `start_coin_rain()` 方法移入 SpawnManager
- 使用 SpawnManager 的 spawn_coin_immediate() 实现
- GameManager 保留 `start_coin_rain()` 作为代理调用 `main_scene.spawn_manager.start_coin_rain()`

**验证**：
```
GUT 测试 → test_spawn_manager.gd 通过
启动游戏 → 现有游戏仍用旧 Spawner，完全不受影响
```

---

## 步骤 4：DayNightCycleManager + 视觉过渡

**目标**：创建昼夜循环管理器，实现背景色渐变过渡。仅添加视觉效果，不改变刷新行为。

**新建文件**：

| 文件 | 说明 |
|------|------|
| `scripts/DayNightCycleManager.gd` | 昼夜循环管理器（普通节点，extends Node） |
| `resources/spawn/tiers/default_tiers.tres` | 默认昼夜配置 |
| `tests/unit/test_day_night_cycle_manager.gd` | GUT 测试 |

**修改文件**：

| 文件 | 变更 |
|------|------|
| `scenes/levels/MainLevel.tscn` | 添加 DayNightCycleManager 子节点 |
| `scripts/levels/MainLevel.gd` | initialize_level 中调用 day_night_cycle_manager.start_cycle()，监听 tier_changed 信号更新 Background 颜色 |

**DayNightCycleManager 设计**（普通节点，非 Autoload）：
```gdscript
class_name DayNightCycleManager
extends Node

signal period_changed(period: SpawnPhase.Period)
signal tier_changed(old_tier: DayNightTier, new_tier: DayNightTier)

var _current_period: SpawnPhase.Period = SpawnPhase.Period.DAY
var _current_tier: DayNightTier = null
var _period_time: float = 0.0

func start_cycle(tier: DayNightTier) -> void
func _process(delta) -> void  # 推进时间，检测昼夜切换
func get_current_period() -> SpawnPhase.Period
func get_difficulty_multiplier() -> float
```

**验证**：
```
GUT 测试 → tier 切换时机、difficulty_multiplier 计算
启动游戏 → MainLevel 背景色随时间渐变，控制台打印 "[DayNight] 切换到黑夜/白天"
现有刷新行为不变
```

---

## 步骤 5：切换到 SpawnManager

**目标**：MainLevel 从 Spawner 切换到 SpawnManager，行为保持一致。

**修改文件**：

| 文件 | 变更 |
|------|------|
| `scripts/levels/MainLevel.gd` | `spawner: Spawner` → `spawn_manager: SpawnManager`；initialize_level 中 configure SpawnManager |
| `scripts/levels/BaseLevel.gd` | `get_spawner() -> Spawner` → `get_spawner() -> SpawnManager`（或改为返回 Node2D） |
| `scripts/GameRoot.gd` | `_initialize_loaded_level()` 中的 `get_spawner()` 调用适配 |
| `scripts/GameManager.gd` | 金币雨逻辑改为代理到 SpawnManager |
| `scenes/levels/MainLevel.tscn` | Spawner 节点替换为 SpawnManager + SpawnZone 子节点 |

**关键**：不删除 Spawner.gd（留作参考），MainLevel 不再引用它。

**行为逐项验证清单**：

| # | 行为 | 对应现有代码 | 验证方法 |
|---|------|-------------|---------|
| 1 | 首次 spawn 前随机延迟 | Spawner.gd:103-108 | 开局不会所有实体同时出现 |
| 2 | 实体添加到 MainLevel 而非 SpawnManager 自身 | Spawner.gd:160 | 实体在场景树正确位置 |
| 3 | 金币加入 "coins" 组 | Spawner.gd:187 | `get_tree().get_nodes_in_group("coins")` 计数正确 |
| 4 | 宝箱加入 "chests" 组 | Spawner.gd:231 | 宝箱计数正确 |
| 5 | increase_difficulty 只影响敌人间隔 | Spawner.gd:289-290 | 难度翻倍后敌人刷新加快，金币不变 |
| 6 | 巨型金币/红钥匙用正计时器 | Spawner.gd:294-325 | 60s 巨型金币出现，90s 红钥匙出现 |
| 7 | 敌人最多 20 个 | Spawner.gd:20 | 达到上限后停止刷新 |
| 8 | 金币最多 30 个 | Spawner.gd:34 | 达到上限后停止刷新 |
| 9 | 占领点 5 秒时生成 | MainLevel.gd:123-126 | 初始占领点正确出现 |
| 10 | 撤离点 20 秒时生成 + 难度翻倍 | MainLevel.gd:129-136 | 倒计时正确，撤离点出现 |
| 11 | 玩家死亡暂停刷新 | MainLevel.gd:91-92 | 死后不再生成新实体 |
| 12 | 金币雨正常触发 | GameManager.gd:218-270 | 特殊效果正确执行 |

**验证**：
```
启动游戏 → 完整游玩一局，逐项检查上述 12 个行为
行为与切换前完全一致，控制台无报错
```

---

## 步骤 6：昼夜影响刷新

**目标**：SpawnManager 响应昼夜切换，白天/黑夜使用不同 SpawnPhase。

**修改文件**：

| 文件 | 变更 |
|------|------|
| `scripts/SpawnManager.gd` | 添加 `set_active_period(period)` 方法 |
| `scripts/levels/MainLevel.gd` | 监听 DayNightCycleManager.period_changed，调用 SpawnManager.set_active_period() |
| `resources/spawn/phases/default_night_phase.tres` | 黑夜阶段：敌人间隔更短、数量上限更高 |

**验证**：
```
启动游戏 → 观察控制台日志：
  - 白天日志 "[SpawnManager] 切换到白天阶段"
  - 黑夜日志 "[SpawnManager] 切换到黑夜阶段"
  - 黑夜敌人明显刷新更频繁
```

---

## 步骤 7：MapConfig + 天数递进

**目标**：GameManager 追踪天数；不同天数使用不同昼夜挡位；MainLevel 从 MapConfig 加载配置。

**新建文件**：

| 文件 | 说明 |
|------|------|
| `resources/spawn/map_config.gd` | MapConfig Resource 脚本 |
| `resources/spawn/day_progression_config.gd` | DayProgressionConfig Resource 脚本 |
| `resources/spawn/special_event.gd` | SpecialEvent Resource 脚本（为步骤 8 准备） |
| `resources/spawn/configs/forest_map.tres` | 森林地图完整 MapConfig |
| `resources/spawn/configs/river_map.tres` | 河流地图 MapConfig |

**修改文件**：

| 文件 | 变更 |
|------|------|
| `scripts/GameManager.gd` | 添加 `current_day_number`、`current_map_config`、`advance_day()` |
| `scripts/levels/MainLevel.gd` | 从 MapConfig 加载配置（单场景 + 不同配置） |
| `scripts/levels/RestAreaLevel.gd` | 添加地图选择按钮列表 |
| `scripts/DayNightCycleManager.gd` | 根据 day_number 计算当前挡位 |

**单场景多地图方案**：
- MainLevel 场景保持唯一
- MapConfig.tres 定义：tier 列表、spawn entries、phases、spawn zone 配置
- 休息区选择地图 = 选择不同的 MapConfig.tres
- 地图差异（障碍物布局等）通过在 MapConfig 中引用不同的静态场景子节点实现

**验证**：
```
完整流程：
  1. 休息区 → 2 个地图选择按钮
  2. 选择森林 → 进入主关卡，加载 forest_map.tres 配置
  3. 控制台打印 "[DayNight] 第1天, 挡位0"
  4. 撤离 → 天数变为 2
  5. 再次进入 → 控制台打印 "[DayNight] 第2天, 挡位1"
```

---

## 步骤 8：事件系统（BaseEventHandler + 事件调度）

**目标**：创建事件处理器接口，DayNightCycleManager 在预定时间触发事件。

**新建文件**：

| 文件 | 说明 |
|------|------|
| `scripts/events/BaseEventHandler.gd` | 事件处理器基类（start_event / cleanup / event_completed 信号） |
| `scripts/events/CoinRainEventHandler.gd` | 金币雨事件处理器 |
| `scripts/events/EnemyRushEventHandler.gd` | 敌人突袭事件处理器 |
| `scenes/events/coin_rain_event.tscn` | 金币雨事件场景 |
| `scenes/events/enemy_rush_event.tscn` | 敌人突袭事件场景 |
| `resources/spawn/events/coin_rain.tres` | 金币雨 SpecialEvent .tres |
| `resources/spawn/events/enemy_rush.tres` | 敌人突袭 SpecialEvent .tres |
| `tests/unit/test_event_system.gd` | GUT 测试 |

**修改文件**：

| 文件 | 变更 |
|------|------|
| `scripts/DayNightCycleManager.gd` | 添加事件调度：从 event_pool 抽取、分配触发时间、到时间实例化 handler |
| `resources/spawn/configs/forest_map.tres` | event_pool 添加事件引用 |

**CoinRainEventHandler 复用**：调用 SpawnManager.spawn_coin_immediate() 实现，与 GameManager 的金币雨统一。

**验证**：
```
启动游戏 → 控制台显示 "[Event] 事件已调度: 金币雨"
等待触发 → 大量金币刷新
GUT 测试 → BaseEventHandler 生命周期、事件抽取逻辑
```

---

## 步骤 9a：石碑解锁

**目标**：石碑占领解锁新 SpawnEntry。

**新建文件**：

| 文件 | 说明 |
|------|------|
| `scripts/stations/Stele.gd` | 石碑脚本（extends BaseArea，复用占领机制） |
| `scenes/stations/Stele.tscn` | 石碑场景 |
| `resources/spawn/events/stele_unlock.tres` | 石碑解锁事件 .tres |
| `tests/unit/test_stele.gd` | GUT 测试 |

**修改文件**：

| 文件 | 变更 |
|------|------|
| `scripts/SpawnManager.gd` | 添加 `unlock_entry(entry_id)` 方法 |

**验证**：
```
事件触发 → 石碑出现在固定位置
占领石碑 → 控制台打印 "[Stele] 解锁 SpawnEntry: xxx"
对应实体开始刷新
```

---

## 步骤 9b：任务商店

**目标**：休息区任务商店让玩家选择额外事件/任务。

**新建文件**：

| 文件 | 说明 |
|------|------|
| `scripts/shop/MissionShop.gd` | 任务商店逻辑（参考 ShopNPC 模式） |
| `scenes/shop/MissionShopNPC.tscn` | 任务商人 NPC 场景 |

**修改文件**：

| 文件 | 变更 |
|------|------|
| `scripts/levels/RestAreaLevel.gd` | 添加任务商人 NPC |
| `scripts/GameManager.gd` | 添加 `accept_mission()` / `clear_accepted_missions()` / `accepted_missions` |
| `scripts/DayNightCycleManager.gd` | 当天事件列表合并 accepted_missions |

**验证**：
```
完整端到端流程：
  1. 休息区 → 任务商人显示可选任务
  2. 接受任务 → GameManager.accepted_missions 包含该事件
  3. 选择地图进入 → 事件已调度
  4. 撤离 → accepted_missions 清空，天数 +1
```

---

## 文件总览

### 新建文件（约 30 个）

**Resource 脚本（6）**：spawn_entry.gd、spawn_phase.gd、day_night_tier.gd、map_config.gd、day_progression_config.gd、special_event.gd
**.tres 配置（约 12）**：entries、phases、tiers、events、configs
**脚本（7）**：SpawnManager、DayNightCycleManager、SpawnZone、Stele、MissionShop、BaseEventHandler + 2 个具体 handler
**场景（约 5）**：SpawnZone、Stele、MissionShopNPC、CoinRainEvent、EnemyRushEvent
**GUT 测试（7）**：每个步骤对应的测试文件

### 修改文件（7 个）

| 文件 | 步骤 | 变更 |
|------|------|------|
| `scripts/levels/BaseLevel.gd` | 5 | get_spawner() 返回类型改为 SpawnManager |
| `scripts/levels/MainLevel.gd` | 4,5,6,7 | 集成 DayNightCycleManager + SpawnManager + MapConfig |
| `scripts/levels/RestAreaLevel.gd` | 7,9b | 地图选择 + 任务商店 |
| `scripts/GameManager.gd` | 3,5,7,9b | 金币雨迁移、天数、任务管理 |
| `scripts/GameRoot.gd` | 5 | get_spawner() 适配 |
| `scripts/SpawnManager.gd` | 6,9a | 昼夜阶段切换 + unlock_entry |
| `scripts/DayNightCycleManager.gd` | 7,8,9b | 挡位计算 + 事件调度 + 任务合并 |

### 保留不动的文件

- `scripts/Spawner.gd` — 不删除，作为参考
- `scripts/areas/BaseArea.gd` — Stele 复用其占领机制
- `scripts/shop/ShopNPC.gd` — MissionShop 参考其模式
- `resources/collectibles/collectible_data.gd` — SpawnEntry 引用它
- `scenes/levels/MainLevel.tscn` — 不复制，单场景复用

---

## 依赖关系

```
步骤 1 (核心 Resource) ←── 所有后续步骤的基础
  ├── 步骤 2 (SpawnZone) ←── 独立可做
  ├── 步骤 3 (SpawnManager) ←── 依赖 1, 2
  │     └── 步骤 5 (切换 SpawnManager) ←── 依赖 3, 4
  │           └── 步骤 6 (昼夜影响刷新) ←── 依赖 5
  │                 └── 步骤 7 (MapConfig + 天数) ←── 依赖 6
  │                       └── 步骤 8 (事件系统) ←── 依赖 7
  │                             ├── 步骤 9a (石碑) ←── 依赖 8
  │                             └── 步骤 9b (任务商店) ←── 依赖 9a
  └── 步骤 4 (DayNightCycle) ←── 依赖 1
```

步骤 2 和步骤 4 可以并行（都只依赖步骤 1）。
