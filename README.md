# Richman - Godot 4.x 2D 俯视角生存游戏

## 项目概述

一个基于 Godot 4.6 的 2D 俯视角生存游戏。玩家选择角色后在关卡中收集金币、占领据点、击败敌人，通过撤离点进入休息区购买道具、选择下一张地图，逐步推进天数和难度。

---

## 快速开始

### 运行项目
```bash
Godot_v4.6.1-stable_win64_console.exe --path .
```

### 主入口
- **主场景**: `scenes/ui/menus/StartScreen.tscn`
- **全局单例**: `GameManager`（在 `project.godot` 中注册为 AutoLoad）

### 游戏流程
```
StartScreen → CharacterSelect → GameRoot.tscn
                                   ↓
                              MainLevel（战斗关卡）
                                   ↓ (撤离)
                              RestAreaLevel（休息区：商店/地图选择）
                                   ↓ (出口NPC)
                              MainLevel（新地图，难度提升）
```

---

## 项目结构

```
richman/
├── project.godot              # 项目配置、AutoLoad、输入映射
├── scenes/                    # 所有场景文件
│   ├── GameRoot.tscn          # 游戏根场景（常驻 Player + 关卡容器）
│   ├── Player.tscn            # 玩家角色
│   ├── Enemy.tscn             # 敌人
│   ├── Coin.tscn              # 金币
│   ├── Chest.tscn             # 宝箱
│   ├── LevelExitNPC.tscn      # 关卡出口NPC
│   ├── CapturePoint.tscn      # 占领点
│   ├── areas/                 # 区域类场景
│   │   ├── BaseArea.tscn
│   │   ├── CaptureArea.tscn
│   │   ├── EvacuationArea.tscn
│   │   ├── area_capture_point.tscn
│   │   └── area_evacuation_point.tscn
│   ├── collectibles/          # 收集品场景（数据驱动版）
│   │   ├── BaseCollectible.tscn
│   │   ├── collection_coin.tscn
│   │   └── collection_chest.tscn
│   ├── events/                # 事件场景
│   │   ├── coin_rain_event.tscn
│   │   └── enemy_rush_event.tscn
│   ├── levels/                # 关卡场景
│   │   ├── MainLevel.tscn     # 主战斗关卡
│   │   ├── RestAreaLevel.tscn # 休息区关卡
│   │   └── RiverLevel.tscn    # 河流关卡（复用 MainLevel.gd）
│   ├── shop/                  # 商店场景
│   │   ├── ShopNPC.tscn
│   │   └── ShopPanel.tscn
│   ├── spawn/                 # 生成区域场景
│   │   └── SpawnZone.tscn
│   ├── stations/              # 站点场景
│   │   └── Stele.tscn
│   └── ui/                    # UI 场景
│       ├── DirectionArrow.tscn
│       └── menus/
│           ├── StartScreen.tscn
│           ├── CharacterSelect.tscn
│           ├── SettingsScreen.tscn
│           └── PauseMenu.tscn
├── scripts/                   # 所有 GDScript 脚本
│   ├── GameManager.gd         # 全局游戏状态管理（AutoLoad 单例）
│   ├── GameRoot.gd            # 游戏根节点：常驻 Player + 关卡切换
│   ├── Player.gd              # 玩家移动、血量、交互
│   ├── Enemy.gd               # 敌人 AI
│   ├── Coin.gd                # 金币（旧版独立脚本）
│   ├── Chest.gd               # 宝箱（旧版独立脚本）
│   ├── Interactable.gd        # 可交互物体基类
│   ├── LevelExitNPC.gd        # 关卡出口 NPC
│   ├── DayNightCycleManager.gd# 昼夜循环管理
│   ├── SpawnManager.gd        # 数据驱动的刷新管理器
│   ├── abilities/
│   │   └── CharacterAbility.gd# 角色能力 Resource
│   ├── areas/
│   │   ├── BaseArea.gd        # 区域基类
│   │   ├── CaptureArea.gd     # 占领区域
│   │   └── EvacuationArea.gd  # 撤离区域
│   ├── collectibles/
│   │   └── base_collectible.gd# 数据驱动收集品基类
│   ├── events/
│   │   ├── BaseEventHandler.gd# 事件处理器基类
│   │   ├── CoinRainEventHandler.gd
│   │   └── EnemyRushEventHandler.gd
│   ├── levels/
│   │   ├── BaseLevel.gd       # 关卡基类
│   │   ├── MainLevel.gd       # 主战斗关卡逻辑
│   │   └── RestAreaLevel.gd   # 休息区关卡逻辑
│   ├── shop/
│   │   ├── ItemData.gd        # 商品数据 Resource
│   │   ├── PurchaseData.gd    # 购买数据 Resource
│   │   ├── PurchaseNPC.gd     # 购买NPC 基类
│   │   ├── ShopNPC.gd         # 商店 NPC
│   │   └── ShopSystem.gd      # 商店 UI 管理
│   ├── spawn/
│   │   └── SpawnZone.gd       # 刷新区域定义
│   ├── stations/
│   │   └── Stele.gd           # 石碑交互
│   └── ui/
│       ├── DirectionArrow.gd  # 方向箭头
│       ├── DirectionIndicator.gd # 方向指引管理
│       ├── FocusStyleHelper.gd# UI 焦点样式
│       ├── UIManager.gd       # UI 管理器
│       └── menus/
│           ├── StartScreen.gd
│           ├── CharacterSelect.gd
│           ├── SettingsScreen.gd
│           └── PauseMenu.gd
├── resources/                 # 所有 .tres 数据资源
│   ├── abilities/             # 角色能力
│   ├── characters/            # 角色数据 + 精灵帧
│   ├── collectibles/          # 收集品数据
│   ├── items/                 # 商店物品数据
│   └── spawn/                 # 刷新系统配置
│       ├── configs/           # 地图配置 + 昼夜进阶配置
│       ├── entries/           # 刷新条目（敌人/金币/宝箱等）
│       ├── events/            # 特殊事件配置
│       ├── phases/            # 刷新阶段
│       └── tiers/             # 难度档位
├── addons/                    # GUT 测试框架
└── tests/                     # 单元测试
```

---

## 核心系统详解

### 1. GameManager（全局状态单例）

**文件**: `scripts/GameManager.gd`

所有场景都可以直接访问 `GameManager.xxx`，它是全局数据的核心：

| 状态 | 说明 |
|------|------|
| `coins` | 当前金币数 |
| `health` / `max_health` | 当前/最大生命值 |
| `player` | Player 节点引用 |
| `main_scene` | 当前关卡引用 |
| `selected_character_data` | 选中的角色 CharacterData |
| `current_day_number` | 当前天数 |
| `current_map_config` | 当前地图 MapConfig |
| `inventory_items` | 背包物品列表 |
| `red_keys_collected` / `red_keys_required` | 红钥匙收集进度 |

**关键信号**（用于 UI 更新和系统联动）:
- `coins_changed(int)` — 金币变化
- `health_changed(int)` — 血量变化
- `player_died()` — 玩家死亡
- `reward_obtained(String)` — 获得奖励提示
- `red_key_collected(int, int)` — 红钥匙进度
- `all_red_keys_collected()` — 红钥匙全部收集

---

### 2. GameRoot（关卡管理）

**文件**: `scripts/GameRoot.gd`

GameRoot 是游戏运行时的根容器，常驻 Player 实例，通过 `LevelContainer` 动态加载/卸载关卡：

```
GameRoot (Node2D)
├── Player (常驻，跨关卡不销毁)
├── LevelContainer (动态加载关卡实例)
├── GlobalUI (HPBar + CoinLabel + DirectionIndicator)
├── Background
└── PauseMenu
```

**关卡切换流程**:
1. `load_level(path)` → 卸载当前关卡 → 加载新关卡 → 调用 `initialize_level(game_root)`
2. `switch_to_main_level()` — 切到战斗关卡
3. `switch_to_rest_area()` — 切到休息区
4. `restart_current_level()` — 重启当前关卡

---

### 3. 玩家系统

**文件**: `scripts/Player.gd` | **场景**: `scenes/Player.tscn`

- **移动**: WASD/方向键，平滑加速减速（基于 `CharacterBody2D`）
- **属性**: 速度、加速度、摩擦力、最大生命值 — 均由 `CharacterData` 配置
- **受伤无敌帧**: 受伤后 1.5 秒无敌，视觉闪烁
- **交互**: E 键与附近 Interactable 物体交互（检测半径 80px）
- **角色数据应用**: `_apply_character_data()` 从 `GameManager.selected_character_data` 读取并应用属性

---

### 4. 昼夜循环系统

**文件**: `scripts/DayNightCycleManager.gd`

管理白天/黑夜的切换、难度递增、特殊事件触发：

| 概念 | 说明 |
|------|------|
| Period | `DAY` / `NIGHT`，交替运行 |
| DayNightTier | 难度档位，控制昼夜时长和难度倍率 |
| DayProgressionConfig | 每 N 天升一档，难度递增 |
| SpecialEvent | 在特定时段/概率触发的特殊事件（金币雨、敌人狂潮等） |

**信号**:
- `period_changed(Period)` — 白天/黑夜切换
- `tier_changed(old, new)` — 难度档位变化
- `time_updated(Period, remaining, total)` — 每帧时间更新

---

### 5. 刷新系统（数据驱动）

这是整个游戏的核心内容生成系统，通过 `.tres` 资源配置驱动，无需改代码即可调整生成内容。

**数据层级**:
```
MapConfig（地图配置）
├── DayProgressionConfig（天数进阶）
├── DayNightTier[]（难度档位列表）
├── SpawnPhase[]（刷新阶段列表）
│   └── SpawnEntry[]（刷新条目）
├── SpecialEvent[]（特殊事件池）
└── level_scene（关卡场景引用）
```

#### 5.1 SpawnEntry（刷新条目）

**文件**: `resources/spawn/spawn_entry.gd`

每个 SpawnEntry 定义一种实体的刷新规则：

| 属性 | 说明 |
|------|------|
| `entry_id` | 唯一标识，如 "enemy_basic" |
| `entity_type` | 实体类型：`"enemy"`, `"coin"`, `"capture_point"`, `"chest"`, `"giant_coin"`, `"red_key"` |
| `scene` | 直接使用场景（敌人、宝箱） |
| `collectible_data` | 使用 CollectibleData（金币、占领点等） |
| `spawn_interval` | 刷新间隔（秒） |
| `max_in_scene` | 场景中最大数量 |
| `spawn_count_min/max` | 每次刷新的数量范围 |
| `min_offset / max_offset` | 生成位置偏移范围 |
| `zone_id` | 指定 SpawnZone（空 = 玩家相对位置） |
| `is_cumulative_timer` | 正计时（累计触发）vs 倒计时 |
| `enabled` | 是否启用 |

**示例 .tres 文件**:
```
# resources/spawn/entries/coin_entry.tres
entry_id = "coin_basic"
entity_type = "coin"
collectible_data = preload("res://resources/collectibles/coin.tres")
spawn_interval = 2.0
max_in_scene = 30
spawn_count_min = 1
spawn_count_max = 3
```

#### 5.2 SpawnPhase（刷新阶段）

**文件**: `resources/spawn/spawn_phase.gd`

将多个 SpawnEntry 按白天/黑夜分组：
- `phase_id`: 阶段标识
- `period`: `DAY` 或 `NIGHT`
- `entries`: SpawnEntry 数组

#### 5.3 SpawnZone（刷新区域）

**文件**: `scripts/spawn/SpawnZone.gd`

定义实体的生成位置计算方式：

| 模式 | 说明 |
|------|------|
| `PLAYER_RELATIVE` | 在玩家周围随机偏移 |
| `AREA_RANDOM` | 在 zone_rect 矩形区域内随机 |
| `SEMI_RANDOM` | 混合模式，按概率选择以上两种 |
| `FIXED` | 从子 Marker2D 节点列表中选择 |

#### 5.4 SpawnManager

**文件**: `scripts/SpawnManager.gd`

运行时管理器，挂载在关卡场景中：
1. 读取 MapConfig → 获取当前阶段的 SpawnPhase
2. 遍历 SpawnEntry，初始化计时器
3. 每帧检查计时器 → 触发刷新 → 在 SpawnZone 区域内生成实体
4. 支持 `start_coin_rain()`、`unlock_entry()` 等运行时操作

---

### 6. 收集品系统

#### 6.1 CollectibleData（收集品数据）

**文件**: `resources/collectibles/collectible_data.gd`

| 类型 | 说明 | 示例 |
|------|------|------|
| `COLLECTIBLE` | 碰到即拾取 | 金币、红钥匙 |
| `AREA_STAY` | 碰到并停留一段时间 | 占领点 |
| `AREA_INTERACT` | 需按键交互 | 宝箱 |
| `TRIGGER` | 触发型 | 撤离点 |

可配置属性包括：视觉（贴图/颜色/缩放）、碰撞、行为（金币价值/回血/生命周期）、方向箭头指示器、动画（旋转/浮动）。

#### 6.2 BaseCollectible（数据驱动收集品）

**文件**: `scripts/collectibles/base_collectible.gd`

根据 `CollectibleData` 自动配置外观和行为：
- 自动注册/注销方向箭头指示器
- 碰撞检测触发收集
- 支持生命周期自动销毁

---

### 7. 角色与能力系统

#### 7.1 CharacterData（角色数据）

**文件**: `resources/character_data.gd`

| 属性 | 说明 |
|------|------|
| `character_name` | 显示名称 |
| `description` | 角色描述 |
| `max_health` | 最大生命值 |
| `starting_health` | 初始生命（-1 = 使用 max_health） |
| `speed` / `acceleration` / `friction` | 移动属性 |
| `sprite_frames` | SpriteFrames 动画资源 |
| `starting_coins` | 初始金币 |
| `abilities` | CharacterAbility 数组 |

#### 7.2 CharacterAbility（角色能力）

**文件**: `scripts/abilities/CharacterAbility.gd`

**触发类型**:
| 类型 | 说明 |
|------|------|
| `ON_COIN_COLLECT` | 每收集 N 个金币触发 |
| `ON_COIN_THRESHOLD` | 金币总数达到 N 的倍数触发 |
| `ON_HEALTH_LOW` | 血量低于 N% 触发 |
| `ON_DAMAGE_TAKEN` | 每受伤 N 次触发 |
| `ON_KILL_ENEMY` | 每击杀 N 个敌人触发 |
| `ON_LEVEL_START` | 关卡开始时触发 |

**效果类型**: `heal`（回血）、`coins`（加金币）、`speed`（加速）、`invincibility`（无敌）、`clear_enemies`（清怪）、`max_health_up`（加血上限）

---

### 8. 商店系统

**继承链**: `Interactable` → `PurchaseNPC` → `ShopNPC`

#### 8.1 ShopNPC
**文件**: `scripts/shop/ShopNPC.gd`
- 随机生成商品列表
- 支持刷新商品（花费金币）
- 购买后应用效果到玩家

#### 8.2 ItemData（商品数据）

**文件**: `scripts/shop/ItemData.gd`

| 类型 | 效果 |
|------|------|
| `SPEED_BOOST_PERCENT` | 永久增加速度百分比 |
| `HEALTH_RESTORE` | 恢复生命值 |
| `MAX_HEALTH_UP` | 增加血量上限 |
| `COIN_SPAWN_RATE_UP` | 金币刷新几率提升 |
| `ENEMY_SPAWN_RATE_DOWN` | 敌人刷新减少 |
| `DIAMOND_SPAWN_RATE_UP` | 钻石刷新几率提升 |

---

### 9. 区域系统

#### CaptureArea（占领区域）
**文件**: `scripts/areas/CaptureArea.gd`
- 玩家进入后开始占领计时
- 占领完成后给予金币奖励
- 有进度条 UI 显示

#### EvacuationArea（撤离区域）
**文件**: `scripts/areas/EvacuationArea.gd`
- 玩家进入并停留一段时间触发撤离
- 自动切换到 RestAreaLevel
- 撤离进度条 UI

---

### 10. UI 系统

| 组件 | 文件 | 说明 |
|------|------|------|
| StartScreen | `scripts/ui/menus/StartScreen.gd` | 开始界面：开始/设置/退出 |
| CharacterSelect | `scripts/ui/menus/CharacterSelect.gd` | 角色选择：WASD + 空格 |
| PauseMenu | `scripts/ui/menus/PauseMenu.gd` | 暂停菜单：继续/设置/返回/退出 |
| SettingsScreen | `scripts/ui/menus/SettingsScreen.gd` | 设置：主/音效/音乐音量 |
| FocusStyleHelper | `scripts/ui/FocusStyleHelper.gd` | 统一焦点样式（金色边框暗色主题） |
| DirectionIndicator | `scripts/ui/DirectionIndicator.gd` | 屏幕外目标方向箭头 |
| UIManager | `scripts/ui/UIManager.gd` | HUD 管理（血条/金币/奖励提示） |

---

## 操作指南：如何添加新内容

### 添加新角色

1. **创建 SpriteFrames 资源**
   - 在 `resources/characters/` 下新建 `角色名_sprites.tres`
   - 添加 `idle` 和 `run` 动画帧

2. **创建 CharacterData 资源**
   - 在 `resources/characters/` 下新建 `角色名.tres`（类型：CharacterData）
   - 配置名称、描述、生命值、速度、加速度、摩擦力、精灵帧、初始金币
   - （可选）添加 abilities 数组

3. **创建能力（可选）**
   - 在 `resources/abilities/` 下新建 `.tres`（类型：CharacterAbility）
   - 配置触发类型、阈值、效果类型和数值
   - 将 .tres 拖入角色的 abilities 数组

4. **注册角色**
   - 打开 `scenes/ui/menus/CharacterSelect.tscn`
   - 在 CharacterSelect 脚本的 `character_data_paths` 中添加新角色 .tres 的路径

### 添加新收集品（金币/钥匙等）

1. **创建 CollectibleData 资源**
   - 在 `resources/collectibles/` 下新建 `.tres`（类型：CollectibleData）
   - 配置类型（COLLECTIBLE/AREA_STAY 等）、视觉、碰撞、行为属性
   - 如需方向箭头，设置 `show_direction_arrow = true`

2. **创建 SpawnEntry**
   - 在 `resources/spawn/entries/` 下新建 `.tres`（类型：SpawnEntry）
   - 设置 `entity_type`、`collectible_data` 指向你的 CollectibleData
   - 配置刷新间隔、最大数量、位置偏移等

3. **将 SpawnEntry 加入 SpawnPhase**
   - 打开对应的 phase .tres（如 `resources/spawn/phases/default_day_phase.tres`）
   - 将新 SpawnEntry 加入 entries 数组

### 添加新敌人

1. **（使用现有 Enemy.tscn）** — 直接在 SpawnEntry 中引用 `scenes/Enemy.tscn`
2. **（自定义敌人）** — 新建场景，挂载自定义脚本，在 SpawnEntry 的 `scene` 中引用

### 添加新地图

1. **创建关卡场景**
   - 在 `scenes/levels/` 下新建 `.tscn`
   - 继承 `BaseLevel.gd`（或直接复用 `MainLevel.gd`）
   - 添加 PlayerSpawn (Marker2D)、SpawnManager、DayNightCycleManager 等节点

2. **创建 MapConfig**
   - 在 `resources/spawn/configs/` 下新建 `.tres`（类型：MapConfig）
   - 设置地图名称、关卡场景引用、SpawnPhase、Tier 配置、事件池

3. **注册地图**
   - 在 RestAreaLevel 的地图选择面板中添加新地图选项

### 添加新商店物品

1. **创建 ItemData 资源**
   - 在 `resources/items/` 下新建 `.tres`（类型：ItemData）
   - 配置名称、描述、类型、效果数值、价格

2. ShopNPC 会自动从所有 ItemData 资源中随机生成商品

### 添加新特殊事件

1. **创建事件处理器场景**
   - 在 `scenes/events/` 下新建 `.tscn`
   - 脚本继承 `BaseEventHandler.gd`，实现 `trigger_event()` 和 `cleanup()`

2. **创建 SpecialEvent 资源**
   - 在 `resources/spawn/events/` 下新建 `.tres`（类型：SpecialEvent）
   - 设置触发时段、时间点、概率、关联的场景

3. **将 SpecialEvent 加入 MapConfig 的事件池**

---

## 输入映射

| 动作 | 按键 |
|------|------|
| `move_up / ui_up` | W / ↑ |
| `move_down / ui_down` | S / ↓ |
| `move_left / ui_left` | A / ← |
| `move_right / ui_right` | D / → |
| `interact` | E |
| `ui_accept` | Space / Enter |
| `ui_cancel` | Escape |
| `ui_restart` | R |

---

## 碰撞层

| 层 | 用途 |
|----|------|
| 1 | 玩家 |
| 2 | 敌人 |
| 3 | 金币/收集品 |
| 4 | NPC/宝箱/可交互 |
| 5 | 占领点/撤离点 |

---

## 场景节点分组

| 组名 | 用途 |
|------|------|
| `player` | 玩家角色 |
| `enemy` | 敌人 |
| `coins` | 金币 |
| `chests` | 宝箱 |
| `capture_points` | 占领点 |
| `capture_areas` | 占领区域 |
