# Resource 驱动的刷新管理系统 — 分步可验证实施计划

## Context

当前 `Spawner.gd` 硬编码所有刷新配置（6种实体各自独立计时器），`MainLevel.gd` 用单一 `_game_timer` 管理流程。需要重构为 Resource 驱动的架构，支持昼夜循环、天数递进、多地图、特殊事件等。

**核心原则**：每一步完成后都能独立验证，不依赖后续步骤。游戏在任意步骤之后都应该能正常运行。

**验证手段**：
- GUT 单元测试（`tests/unit/` 目录，已有 5 个测试文件）
- 启动游戏运行（`"E:\godot\Godot_v4.6.1-stable_win64_console.exe" --path "F:\godot_game\run_game\richman"`）
- Godot 编辑器 Inspector 检查 .tres 文件

---

## 步骤 1：Resource 脚本 + GUT 单元测试

**目标**：创建所有数据类型的 Resource 脚本，用 GUT 测试验证属性和校验逻辑。

**新建文件**：

| 文件 | 说明 |
|------|------|
| `resources/spawn/spawn_zone_type.gd` | SpawnZoneType 枚举（PLAYER_RELATIVE / AREA_RANDOM / SEMI_RANDOM / FIXED） |
| `resources/spawn/spawn_entry.gd` | SpawnEntry Resource — 单个可刷新实体定义 |
| `resources/spawn/spawn_phase.gd` | SpawnPhase Resource — 一组 SpawnEntry 组成一个刷新阶段 |
| `resources/spawn/day_night_tier.gd` | DayNightTier Resource — 一个昼夜挡位（白天/黑夜时长 + 难度倍率） |
| `resources/spawn/special_event.gd` | SpecialEvent Resource — 特殊事件定义 |
| `resources/spawn/day_progression_config.gd` | DayProgressionConfig Resource — 天数递进规则 |
| `resources/spawn/map_config.gd` | MapConfig Resource — 地图配置（顶层，聚合所有其他 Resource） |
| `tests/unit/test_spawn_resources.gd` | GUT 测试：所有 7 个 Resource 的 is_valid()、默认值、边界情况 |

**设计要点**（沿用项目现有模式，参考 `resources/collectibles/collectible_data.gd`）：
- 每个 Resource 都有 `class_name`、`@export` 字段、`is_valid()` 方法
- SpawnEntry 引用 `CollectibleData` 或 `PackedScene`，引用 SpawnZone（通过 zone_id 字符串）
- SpawnPhase 有 `period` 枚举（DAY / NIGHT），用于昼夜过滤
- DayNightTier 包含 day_duration、night_duration、difficulty_multiplier
- MapConfig 聚合 duration_tiers、spawn_entries、phases、event_pool
- DayProgressionConfig 包含 tier_curve（Curve）+ difficulty_per_day

**验证**：
```
运行 GUT 测试 → tests/unit/test_spawn_resources.gd 全部通过
启动游戏 → 现有功能不受影响（这些脚本未被引用）
```

---

## 步骤 2：SpawnZone 节点 + 位置计算测试

**目标**：创建 SpawnZone 场景节点，支持 4 种定位模式，替换 Spawner 中的硬编码位置计算。

**新建文件**：

| 文件 | 说明 |
|------|------|
| `scripts/spawn/SpawnZone.gd` | SpawnZone 节点脚本（extends Marker2D） |
| `scenes/spawn/SpawnZone.tscn` | SpawnZone 场景模板 |
| `tests/unit/test_spawn_zone.gd` | GUT 测试：4 种模式的位置计算 |

**SpawnZone 设计**：
```
@export var zone_id: String           # "player_near", "lighthouse_area"...
@export var zone_mode: SpawnZoneType  # 4 种模式

# PLAYER_RELATIVE：围绕玩家随机偏移（复刻现有 _get_random_spawn_position）
# AREA_RANDOM：在 zone_rect 范围内随机
# SEMI_RANDOM：70% 偏向玩家 + 30% 区域随机
# FIXED：从子节点 Marker2D 中随机选一个
```

**验证**：
```
GUT 测试 → test_spawn_zone.gd 通过（各模式返回合理范围内的坐标）
启动游戏 → 现有功能不受影响（SpawnZone 未被 MainLevel 引用）
```

---

## 步骤 3：SpawnManager 新建（并行于 Spawner）+ 示例 .tres

**目标**：新建 SpawnManager，从 SpawnEntry Resource 读取配置驱动刷新。保留旧 Spawner 不动，零回归风险。

**新建文件**：

| 文件 | 说明 |
|------|------|
| `scripts/SpawnManager.gd` | 数据驱动的刷新管理器 |
| `resources/spawn/entries/coin_entry.tres` | 金币 SpawnEntry（对应现有 coin 刷新逻辑） |
| `resources/spawn/entries/enemy_entry.tres` | 敌人 SpawnEntry（对应现有 enemy 刷新逻辑） |
| `resources/spawn/entries/capture_entry.tres` | 占领点 SpawnEntry |
| `resources/spawn/entries/chest_entry.tres` | 宝箱 SpawnEntry |
| `resources/spawn/entries/giant_coin_entry.tres` | 巨型金币 SpawnEntry |
| `resources/spawn/entries/red_key_entry.tres` | 红钥匙 SpawnEntry |
| `resources/spawn/phases/default_day_phase.tres` | 默认白天阶段（包含上述 entries） |
| `resources/spawn/phases/default_night_phase.tres` | 默认黑夜阶段 |
| `tests/unit/test_spawn_manager.gd` | GUT 测试 |

**SpawnManager 设计**：
- 公共 API 兼容 Spawner（`pause_spawning()`、`resume_spawning()`、`increase_difficulty()`、`spawn_coin_immediate()` 等）
- 内部从 `SpawnPhase.get_enabled_entries()` 遍历，每个 Entry 独立计时
- 通过 SpawnZone 计算位置，fallback 复刻现有 `_get_random_spawn_position` 逻辑
- `configure(phase: SpawnPhase, zone: SpawnZone)` 初始化
- `set_active_phase(phase_id: String)` 切换阶段

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
| `scripts/DayNightCycleManager.gd` | 昼夜循环管理器（Autoload 单例） |
| `resources/spawn/tiers/default_tiers.tres` | 默认 7 档昼夜配置 |
| `tests/unit/test_day_night_cycle_manager.gd` | GUT 测试 |

**修改文件**：

| 文件 | 变更 |
|------|------|
| `project.godot` | 添加 DayNightCycleManager autoload |
| `scripts/levels/MainLevel.gd` | initialize_level 中调用 DayNightCycleManager.start_cycle()，监听 tier_changed 信号更新 Background 颜色 |

**DayNightCycleManager 设计**：
- `start_cycle(config: DayProgressionConfig, map: MapConfig)` → 根据 config 和 day_number 计算当前挡位
- `_process(delta)` 推进时间，检测昼夜切换
- `tier_changed(old_tier, new_tier)` 信号
- `get_current_period() -> DAY/NIGHT`
- `get_difficulty_multiplier() -> float`
- 不活跃时（rest area）完全不处理

**验证**：
```
GUT 测试 → tier 切换时机、difficulty_multiplier 计算
启动游戏 → MainLevel 背景色随时间渐变，控制台打印 "[DayNight] 切换到黑夜/白天"
现有刷新行为不变（Spawner 仍工作，DayNightCycleManager 只影响视觉）
```

---

## 步骤 5：切换到 SpawnManager

**目标**：MainLevel 从 Spawner 切换到 SpawnManager，行为保持一致。

**修改文件**：

| 文件 | 变更 |
|------|------|
| `scripts/levels/MainLevel.gd` | 将 `spawner: Spawner` 替换为 `spawn_manager: SpawnManager`；initialize_level 中 load default_map.tres → configure SpawnManager |
| `scenes/levels/MainLevel.tscn` | Spawner 节点替换为 SpawnManager + SpawnZone 子节点 |

**关键**：不删除 Spawner.gd（留作参考），MainLevel 不再引用它。

**验证**：
```
启动游戏 → 完整游玩一局：
  - 敌人正常刷新、可击杀
  - 金币正常刷新、可拾取、计数正确
  - 占领点 5 秒后出现，宝箱正常刷新
  - 巨型金币 60 秒出现，红钥匙 90 秒出现
  - 20 秒撤离点出现，难度翻倍
  - 玩家死亡可重开
行为与切换前完全一致，控制台无报错
```

---

## 步骤 6：昼夜影响刷新

**目标**：SpawnManager 响应昼夜切换，白天/黑夜使用不同 SpawnPhase，敌人刷新频率在黑夜加快。

**修改文件**：

| 文件 | 变更 |
|------|------|
| `scripts/SpawnManager.gd` | 添加 `set_active_period(period)` 方法，按 DAY/NIGHT 过滤阶段 |
| `scripts/levels/MainLevel.gd` | 监听 DayNightCycleManager.tier_changed，调用 SpawnManager.set_active_period() |
| `resources/spawn/phases/default_day_phase.tres` | 调整白天阶段参数 |
| `resources/spawn/phases/default_night_phase.tres` | 黑夜阶段：敌人间隔更短、数量上限更高 |

**验证**：
```
启动游戏 → 观察控制台日志：
  - 白天阶段日志 "[SpawnManager] 切换到白天阶段, 活跃 entries: 6"
  - 进入黑夜日志 "[SpawnManager] 切换到黑夜阶段, 活跃 entries: 4"
  - 黑夜敌人明显刷新更频繁
  - 金币/宝箱等非战斗实体在黑夜仍正常刷新
```

---

## 步骤 7：MapConfig + 天数递进 + 多地图选择

**目标**：GameManager 追踪天数，不同天数使用不同昼夜挡位；休息区可选择不同地图。

**新建文件**：

| 文件 | 说明 |
|------|------|
| `resources/spawn/configs/forest_map.tres` | 森林地图完整配置 |
| `resources/spawn/configs/river_map.tres` | 河流地图完整配置（第二张图） |
| `scenes/levels/ForestMap.tscn` | 森林地图场景（从 MainLevel.tscn 复制并改名） |
| `scenes/levels/RiverMap.tscn` | 河流地图场景 |

**修改文件**：

| 文件 | 变更 |
|------|------|
| `scripts/GameManager.gd` | 添加 `current_day_number`、`current_map_config`、`advance_day()`、`accepted_missions` |
| `scripts/GameRoot.gd` | 支持从 MapConfig.map_scene_path 动态加载地图 |
| `scripts/levels/RestAreaLevel.gd` | 添加地图选择 UI（简单按钮列表） |
| `scripts/DayNightCycleManager.gd` | 根据 day_number + tier_curve 计算当前挡位 |

**验证**：
```
启动游戏 → 完整流程：
  1. 进入休息区 → 看到 2 个地图选择按钮（森林/河流），河流显示"未解锁"（如 min_unlock_day > 1）
  2. 选择森林 → 进入森林地图
  3. 控制台打印 "[DayNight] 第1天, 挡位0, 白天40s/黑夜20s"
  4. 撤离 → 回到休息区，天数变为 2
  5. 再次进入 → 控制台打印 "[DayNight] 第2天, 挡位1, 白天45s/黑夜25s"（时长变化可见）
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
| `resources/spawn/events/forest/coin_rain.tres` | 金币雨 SpecialEvent .tres |
| `resources/spawn/events/forest/enemy_rush.tres` | 敌人突袭 SpecialEvent .tres |
| `resources/spawn/events/global/all_night.tres` | 全天黑夜事件 |
| `tests/unit/test_event_system.gd` | GUT 测试 |

**修改文件**：

| 文件 | 变更 |
|------|------|
| `scripts/DayNightCycleManager.gd` | 添加事件调度逻辑：从 event_pool 抽取、分配触发时间、到时间实例化 handler_scene |
| `resources/spawn/configs/forest_map.tres` | event_pool 添加事件引用 |

**验证**：
```
启动游戏 → 进入森林地图 → 控制台日志：
  "[Event] 事件已调度: 金币雨 (白天 12s 触发)"
  "[Event] 事件已调度: 敌人突袭 (黑夜 8s 触发)"
等待触发时间 → 观察到：
  - 金币雨：地图上突然刷新大量金币，奖励提示弹出
  - 敌人突袭：大量敌人涌入
GUT 测试 → BaseEventHandler 生命周期、事件抽取逻辑
```

---

## 步骤 9：石碑 + 任务商店

**目标**：石碑占领解锁新 SpawnEntry；休息区任务商店让玩家选择额外事件。

**新建文件**：

| 文件 | 说明 |
|------|------|
| `scripts/stations/Stele.gd` | 石碑脚本（extends BaseArea） |
| `scenes/stations/Stele.tscn` | 石碑场景 |
| `scripts/shop/MissionShop.gd` | 任务商店逻辑 |
| `scenes/shop/MissionShopNPC.tscn` | 任务商人 NPC 场景 |
| `resources/spawn/events/forest/stele_unlock.tres` | 石碑解锁事件 .tres |
| `tests/unit/test_stele.gd` | GUT 测试 |

**修改文件**：

| 文件 | 变更 |
|------|------|
| `scripts/SpawnManager.gd` | 添加 `unlock_entry(entry_id)` 方法 |
| `scripts/levels/RestAreaLevel.gd` | 添加任务商人 NPC，接受任务 → GameManager.accepted_missions |
| `scripts/GameManager.gd` | 添加 `accept_mission()` / `clear_accepted_missions()` |
| `scripts/DayNightCycleManager.gd` | 当天事件列表合并 accepted_missions |

**验证**：
```
完整端到端流程：
  1. 休息区 → 任务商人显示 3 个可选任务（如"史莱姆入侵"、"神秘石碑"、"护送商队"）
  2. 接受"神秘石碑" → GameManager.accepted_missions 包含该事件
  3. 选择地图进入 → 控制台打印已调度事件包含"神秘石碑"
  4. 事件触发 → 石碑出现在固定位置
  5. 占领石碑 → 控制台打印 "[Stele] 解锁 SpawnEntry: giant_coin"
  6. 巨型金币开始刷新（之前不刷，占领后解锁）
  7. 撤离 → 回到休息区，accepted_missions 清空，天数 +1
```

---

## 文件总览

### 新建文件（约 40 个）

**Resource 脚本（7）**：`resources/spawn/` 下的 .gd 文件
**.tres 配置（约 15）**：`resources/spawn/` 下的 entries、phases、tiers、events、configs
**脚本（8）**：SpawnManager、DayNightCycleManager、SpawnZone、Stele、MissionShop、BaseEventHandler + 2 个具体 handler
**场景（约 6）**：SpawnZone、Stele、MissionShopNPC、CoinRainEvent、EnemyRushEvent、新地图
**GUT 测试（7）**：每个步骤对应的测试文件

### 修改文件（6 个）

| 文件 | 步骤 | 变更 |
|------|------|------|
| `project.godot` | 4 | 添加 DayNightCycleManager autoload |
| `scripts/GameManager.gd` | 7, 9 | 添加天数、地图、任务状态管理 |
| `scripts/GameRoot.gd` | 7 | 支持动态地图加载 |
| `scripts/levels/MainLevel.gd` | 4, 5, 6 | 集成 DayNightCycleManager + SpawnManager |
| `scripts/levels/RestAreaLevel.gd` | 7, 9 | 地图选择 + 任务商店 |
| `scripts/SpawnManager.gd` | 6, 9 | 昼夜阶段切换 + unlock_entry |

### 保留不动的文件

- `scripts/Spawner.gd` — 不删除，作为参考
- `scripts/areas/BaseArea.gd` — Stele 复用其占领机制
- `scripts/shop/ShopNPC.gd` — MissionShop 参考其模式
- `resources/collectibles/collectible_data.gd` — SpawnEntry 引用它

---

## 依赖关系

```
步骤 1 (Resource 脚本) ←── 所有后续步骤的基础
  ├── 步骤 2 (SpawnZone) ←── 独立可做
  ├── 步骤 3 (SpawnManager) ←── 依赖 1, 2
  ├── 步骤 4 (DayNightCycle) ←── 依赖 1
  │     └── 步骤 5 (切换 SpawnManager) ←── 依赖 3, 4
  │           └── 步骤 6 (昼夜影响刷新) ←── 依赖 5
  │                 └── 步骤 7 (多地图 + 天数) ←── 依赖 6
  │                       └── 步骤 8 (事件系统) ←── 依赖 7
  │                             └── 步骤 9 (石碑 + 任务商店) ←── 依赖 8
```

步骤 2 和步骤 4 可以并行（都只依赖步骤 1）。
