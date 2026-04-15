# Richman - AI 开发者参考

> 本文件面向 AI 助手（如 Claude），帮助快速理解项目架构、定位代码、理解数据流转，以便高效进行代码修改和功能开发。

---

## 项目一句话概括

Godot 4.6 的 2D 俯视角生存游戏。数据驱动设计，游戏内容（角色/收集品/刷新规则/商店物品）全部通过 `.tres` Resource 配置，核心逻辑集中在 GDScript 中。

---

## 快速定位指南

### "我要改 X，应该看哪里？"

| 需求 | 关键文件 |
|------|----------|
| 改角色属性 | `resources/characters/*.tres` + `resources/character_data.gd` |
| 改角色能力 | `resources/abilities/*.tres` + `scripts/abilities/CharacterAbility.gd` |
| 改金币/收集品 | `resources/collectibles/*.tres` + `resources/collectibles/collectible_data.gd` |
| 改刷新规则 | `resources/spawn/entries/*.tres` + `resources/spawn/spawn_entry.gd` |
| 改昼夜/难度 | `resources/spawn/tiers/*.tres` + `resources/spawn/configs/*.tres` |
| 改商店物品 | `resources/items/*.tres` + `scripts/shop/ItemData.gd` |
| 改关卡逻辑 | `scripts/levels/MainLevel.gd` 或 `scripts/levels/RestAreaLevel.gd` |
| 改玩家行为 | `scripts/Player.gd` |
| 改敌人 AI | `scripts/Enemy.gd` |
| 改全局状态 | `scripts/GameManager.gd`（AutoLoad 单例） |
| 改关卡切换 | `scripts/GameRoot.gd` |
| 改 UI 菜单 | `scripts/ui/menus/*.gd` |
| 改刷新系统核心 | `scripts/SpawnManager.gd` + `scripts/spawn/SpawnZone.gd` |
| 改交互系统 | `scripts/Interactable.gd`（基类）→ `scripts/shop/PurchaseNPC.gd`（购买） |
| 改占领/撤离 | `scripts/areas/CaptureArea.gd` / `scripts/areas/EvacuationArea.gd` |
| 添加新地图 | 复制 `scenes/levels/MainLevel.tscn`，创建新 `MapConfig` .tres |

---

## 架构总览

### 场景加载链

```
project.godot (main_scene) → StartScreen.tscn
  → [Start] → CharacterSelect.tscn
    → [选择角色] → GameRoot.tscn  ← 游戏从这里开始运行
                    ├── Player (常驻，跨关卡不销毁)
                    ├── LevelContainer
                    │   └── [动态加载] MainLevel.tscn / RestAreaLevel.tscn / RiverLevel.tscn
                    ├── GlobalUI (CanvasLayer: HPBar + CoinLabel + DirectionIndicator)
                    ├── Background
                    └── PauseMenu.tscn
```

**关键点**:
- Player 是 GameRoot 的子节点，不是关卡的子节点。关卡通过 `game_root.player` 获取引用
- 关卡切换通过 `GameRoot.load_level(path)` 完成，先 queue_free 旧关卡，再 instantiate 新关卡
- 关卡必须实现 `get_player_spawn_point()` 和 `initialize_level(game_root)` 接口

### 全局单例

**只有 `GameManager`** 注册为 AutoLoad：
- `scripts/GameManager.gd`
- 通过 `GameManager.xxx` 从任何脚本直接访问
- 持有全局状态：coins、health、player、selected_character_data、current_map_config 等
- 关键信号：`coins_changed`、`health_changed`、`player_died`、`reward_obtained`

### 继承体系

```
Node2D
├── BaseLevel (scripts/levels/BaseLevel.gd)
│   ├── MainLevel (scripts/levels/MainLevel.gd)
│   └── RestAreaLevel (scripts/levels/RestAreaLevel.gd)
├── SpawnManager (scripts/SpawnManager.gd)
└── SpawnZone (scripts/spawn/SpawnZone.gd extends Marker2D)

Area2D
├── Interactable (scripts/Interactable.gd) ← 可交互基类（E键提示）
│   ├── PurchaseNPC (scripts/shop/PurchaseNPC.gd) ← 购买逻辑基类
│   │   └── ShopNPC (scripts/shop/ShopNPC.gd)
│   └── LevelExitNPC (scripts/LevelExitNPC.gd)
├── BaseArea (scripts/areas/BaseArea.gd)
│   ├── CaptureArea (scripts/areas/CaptureArea.gd)
│   └── EvacuationArea (scripts/areas/EvacuationArea.gd)
├── Enemy (scripts/Enemy.gd)
└── base_collectible (scripts/collectibles/base_collectible.gd)

CharacterBody2D
└── Player (scripts/Player.gd)

Resource
├── CharacterData (resources/character_data.gd)
├── CharacterAbility (scripts/abilities/CharacterAbility.gd)
├── CollectibleData (resources/collectibles/collectible_data.gd)
├── SpawnEntry (resources/spawn/spawn_entry.gd)
├── SpawnPhase (resources/spawn/spawn_phase.gd)
├── MapConfig (resources/spawn/map_config.gd)
├── SpecialEvent (resources/spawn/special_event.gd)
├── DayProgressionConfig (resources/spawn/day_progression_config.gd)
├── DayNightTier (resources/spawn/day_night_tier.gd)
├── ItemData (scripts/shop/ItemData.gd)
└── PurchaseData (scripts/shop/PurchaseData.gd)
```

---

## 数据流转详解

### 刷新系统数据流（核心）

```
MapConfig.tres
├── day_progression: DayProgressionConfig.tres  ← 天数→难度档位映射
├── tiers: DayNightTier[]                       ← 每档的昼夜时长和倍率
├── phases: SpawnPhase[]                        ← 白天/黑夜的刷新条目组
│   └── entries: SpawnEntry[]                   ← 单个实体的刷新规则
│       ├── scene: PackedScene                  ← 直接场景（敌人）
│       ├── collectible_data: CollectibleData   ← 数据驱动（金币等）
│       └── zone_id → SpawnZone                 ← 生成位置
└── event_pool: SpecialEvent[]                  ← 特殊事件

运行时:
MainLevel._ready()
  → DayNightCycleManager._ready() → 读取 MapConfig.tiers → 启动昼夜循环
  → SpawnManager.configure(phase, zone) → 读取 SpawnPhase.entries
  → _process() → 计时器倒计时 → _spawn_from_entry(entry)
    → 如果 entity_type 有 scene → scene.instantiate()
    → 如果有 collectible_data → BaseCollectible 场景 + 注入 data
    → SpawnZone.get_spawn_position() → 设置位置 → add_child
```

### 角色选择数据流

```
CharacterSelect._ready()
  → 遍历 character_data_paths（硬编码路径列表）
  → load(path) as CharacterData → 读取 max_health/speed/abilities 等
  → 创建角色卡片 UI → 显示属性

CharacterSelect._on_start_button_pressed()
  → GameManager.selected_character_data = 选中的 CharacterData
  → change_scene_to_file("res://scenes/GameRoot.tscn")

GameRoot._ready()
  → _initialize_player()
    → _apply_character_data_to_player()
      → Player._apply_character_data()
        → base_speed = data.speed
        → 加速度/摩擦力 = data.acceleration/friction
        → GameManager.max_health = data.max_health
        → GameManager.health = data.get_initial_health()
```

### 关卡切换数据流

```
MainLevel (战斗中)
  → EvacuationArea 被玩家站满
    → get_tree().current_scene.switch_to_rest_area()
      → GameRoot.load_level("res://scenes/levels/RestAreaLevel.tscn")
        → 卸载 MainLevel
        → 实例化 RestAreaLevel
        → RestAreaLevel.initialize_level(game_root)
          → player = game_root.player
          → 设置商店 NPC

RestAreaLevel (休息区)
  → ExitNPC 交互
    → game_root.switch_to_main_level()
      → 读取 GameManager.current_map_config.level_scene
      → GameRoot.load_level(path)
        → 卸载 RestAreaLevel
        → 实例化新 MainLevel
        → 新关卡读取更新后的 MapConfig
```

### 商店购买数据流

```
ShopNPC (extends PurchaseNPC extends Interactable)
  → interact() → 打开 ShopPanel
  → ShopSystem._setup_items()
    → 从 ItemData 资源列表随机选取
    → item.to_purchase_data() → 创建 PurchaseData
    → 创建 UI 按钮

  → 玩家点击购买
    → PurchaseNPC._on_purchase_button_pressed(index)
      → _can_afford() → _deduct_gold()
      → _purchase_option(data) → ShopNPC 实现 → item.apply_to_player()
      → ItemData.apply_to_player() → 修改 GameManager 属性
```

---

## 信号连接关系

### GameManager 信号 → 谁在监听

| 信号 | 监听者 |
|------|--------|
| `coins_changed(int)` | GameRoot._on_coins_changed → 更新 CoinLabel |
| `health_changed(int)` | GameRoot._on_health_changed → 更新 HPBar |
| `player_died()` | GameRoot._on_player_died → (TODO: 显示游戏结束) |
| `reward_obtained(String)` | GameRoot._on_reward_obtained → 打印日志 |

### 关卡内部信号

| 信号 | 连接 |
|------|------|
| `DayNightCycleManager.period_changed` | SpawnManager.set_active_period() → 切换白天/黑夜的 SpawnEntry |
| `DayNightCycleManager.tier_changed` | MainLevel → 调整难度 |
| `Player.player_died` | GameRoot._on_player_died |
| `PauseMenu.resume_requested` | GameRoot._on_pause_resume_requested |
| `SpawnManager.coin_rain_started` | MainLevel → 显示提示 |

---

## Export 变量速查

### Player.gd
- `base_speed: float = 200.0`
- `acceleration: float = 1000.0`
- `friction: float = 1500.0`

### Enemy.gd
- `behavior_type: BehaviorType` (STATIC / RANDOM_MOVE)
- `lifetime: float = 10.0`
- `giant_variant_chance: float = 0.2`
- `move_speed: float = 100.0`

### SpawnManager.gd
- 无直接 export，通过 `configure(phase, zone)` 方法配置

### MainLevel.gd
- `evacuation_time: float = 20.0`
- `initial_capture_points_time: float = 5.0`
- `initial_capture_points_count: int = 3`
- `difficulty_multiplier: float = 2.0`

### GameRoot.gd
- `first_level_path: String = "res://scenes/levels/MainLevel.tscn"`
- `auto_load_first_level: bool = true`
- `background_color: Color`

### SpawnZone.gd
- `zone_id: String`
- `zone_mode: ZoneMode` (PLAYER_RELATIVE / AREA_RANDOM / SEMI_RANDOM / FIXED)
- `zone_rect: Rect2`
- `player_bias: float = 0.7`
- `min_offset: float = 100.0`
- `max_offset: float = 500.0`

---

## 关键接口约定

### BaseLevel 接口（所有关卡必须实现）

```gdscript
func get_player_spawn_point() -> Marker2D    # 返回玩家出生点
func initialize_level(game_root: Node2D)      # 由 GameRoot 调用
func get_spawner() -> SpawnManager            # 返回刷新管理器
func get_enemies() -> Array                   # 返回当前敌人列表
```

### Interactable 接口

```gdscript
func interact()           # 子类重写，E 键触发
func set_interaction_prompt(text)  # 设置交互提示文本
```

### PurchaseNPC 接口

```gdscript
func _setup_ui()          # 子类重写，设置商店 UI
func _purchase_option(data)  # 子类重写，处理购买
```

### BaseEventHandler 接口

```gdscript
func trigger_event(spawn_manager)  # 触发事件
func cleanup()                     # 清理事件
```

---

## 修改模式参考

### 添加新 entity_type 到刷新系统

1. **在 SpawnManager._spawn_from_entry() 中添加新类型**（`scripts/SpawnManager.gd`）
   ```gdscript
   "new_type":
       var instance = new_type_scene.instantiate()
       # 配置 instance
       _add_to_scene(instance, entry)
   ```

2. **创建对应的 SpawnEntry .tres**（`resources/spawn/entries/`）

3. **将 .tres 加入 SpawnPhase**（`resources/spawn/phases/`）

### 添加新的能力效果类型

1. **在 CharacterAbility._apply_effect() 中添加新分支**（`scripts/abilities/CharacterAbility.gd`）
   ```gdscript
   "new_effect":
       # 执行效果逻辑
   ```

2. **创建对应的 .tres 配置**（`resources/abilities/`）

### 添加新商品类型

1. **在 ItemData.ItemType 枚举中添加**（`scripts/shop/ItemData.gd`）
2. **在 `get_display_description()` 中添加描述**
3. **在 `apply_to_player()` 中添加效果逻辑**
4. **创建 .tres 资源**（`resources/items/`）

---

## 注意事项

### 循环依赖处理
- `CharacterData.gd` 使用 `const CharacterAbility = preload(...)` 而非 `class_name` 引用，避免循环依赖
- 测试文件也使用 `const preload` 方式

### Godot 4.6 兼容性
- `Control.PRESET_MINSIZE` 已移除，使用 `set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)` 不带第二参数
- UID 不匹配会导致 WARNING 但不影响运行（Godot 自动回退到文本路径）

### 碰撞层约定
- Layer 1: 玩家
- Layer 2: 敌人
- Layer 3: 金币/收集品
- Layer 4: NPC/宝箱/可交互
- Layer 5: 占领点/撤离点

### 场景节点分组
- `player`、`enemy`、`coins`、`chests`、`capture_points`、`capture_areas`
- 代码中通过 `get_tree().get_nodes_in_group()` 获取节点

### 测试框架
- 使用 GUT（GDScript Unit Test）框架，位于 `addons/gut/`
- 测试文件在 `tests/unit/`
- 运行测试需在 Godot 编辑器中或通过命令行启动 GUT

---

## 文件依赖关系图

```
project.godot
  └── AutoLoad: GameManager.gd

GameRoot.tscn
  ├── Player.tscn → Player.gd
  ├── PauseMenu.tscn → PauseMenu.gd
  │   └── SettingsScreen.tscn → SettingsScreen.gd
  └── (动态加载) Level.tscn
      ├── MainLevel.tscn → MainLevel.gd
      │   ├── SpawnManager.gd
      │   │   └── 读取 → MapConfig.tres → SpawnPhase[] → SpawnEntry[]
      │   │       └── SpawnEntry → CollectibleData.tres / Scene
      │   └── DayNightCycleManager.gd
      │       └── 读取 → DayProgressionConfig.tres → DayNightTier[]
      └── RestAreaLevel.tscn → RestAreaLevel.gd
          ├── ShopNPC.tscn → ShopNPC.gd → PurchaseNPC.gd → Interactable.gd
          ├── ShopPanel.tscn → ShopSystem.gd
          └── LevelExitNPC.tscn → LevelExitNPC.gd → Interactable.gd

CharacterSelect.tscn → CharacterSelect.gd
  └── 读取 → CharacterData.tres
      └── abilities[] → CharacterAbility.tres

SpawnZone.gd ← 被 SpawnManager 通过 zone_id 引用
BaseCollectible.gd ← 由 SpawnManager 根据 CollectibleData 实例化
```
