# Godot 4 2D 俯视角生存游戏 - 项目设置文档

## 项目概述

这是一个完整的 Godot 4.x 2D 俯视角生存游戏，包含玩家控制、敌人AI、金币收集、占领据点和随机宝箱等完整游戏机制。

---

## 项目文件夹结构

```
run_game/
├── scripts/              # 所有 GDScript 脚本
│   ├── GameManager.gd    # 全局管理器（AutoLoad 单例）
│   ├── Player.gd         # 玩家控制脚本
│   ├── Enemy.gd          # 敌人 AI 脚本
│   ├── Coin.gd           # 金币脚本
│   ├── Chest.gd          # 宝箱脚本
│   ├── CapturePoint.gd   # 占领据点脚本
│   ├── Spawner.gd        # 生成器脚本
│   └── Main.gd           # 主场景控制器
│
├── scenes/               # 所有场景文件
│   ├── Player.tscn       # 玩家场景
│   ├── Enemy.tscn        # 敌人场景
│   ├── Coin.tscn         # 金币场景
│   ├── Chest.tscn        # 宝箱场景
│   ├── CapturePoint.tscn # 占领据点场景
│   └── Main.tscn         # 主场景
│
└── project.godot         # Godot 项目配置文件
```

---

## 场景节点树结构详解

### 1. Player.tscn（玩家场景）

```
Player (CharacterBody2D) - 脚本: Player.gd
├── Sprite2D              # 玩家精灵（可使用玩家角色贴图）
├── CollisionShape2D      # 碰撞体（圆形或矩形）
└── HurtArea (Area2D)     # 伤害检测区域
    ├── CollisionShape2D  # 伤害检测碰撞体（比身体稍大）
    └── InvincibilityTimer (Timer)  # 无敌帧计时器
```

**碰撞层设置**：
- Player: Layer = 1, Mask = 0
- HurtArea: Layer = 0, Mask = 2（敌人层）

---

### 2. Enemy.tscn（敌人场景）

```
Enemy (Area2D) - 脚本: Enemy.gd
├── Sprite2D              # 敌人精灵
├── CollisionShape2D      # 碰撞体
└── LifetimeTimer (Timer) # 生命周期计时器（One Shot = true）
```

**碰撞层设置**：
- Enemy: Layer = 2, Mask = 1（玩家层）

---

### 3. Coin.tscn（金币场景）

```
Coin (Area2D) - 脚本: Coin.gd
├── Sprite2D              # 金币精灵（圆形金币）
├── CollisionShape2D      # 碰撞体（圆形）
└── LifetimeTimer (Timer) # 生命周期计时器（One Shot = true）
```

**碰撞层设置**：
- Coin: Layer = 3, Mask = 1（玩家层）

---

### 4. Chest.tscn（宝箱场景）

```
Chest (Area2D) - 脚本: Chest.gd
├── Sprite2D              # 宝箱精灵
├── CollisionShape2D      # 碰撞体
└── AnimationPlayer       # 开箱动画（可选）
```

**碰撞层设置**：
- Chest: Layer = 4, Mask = 1（玩家层）

---

### 5. CapturePoint.tscn（占领据点场景）

```
CapturePoint (Area2D) - 脚本: CapturePoint.gd
├── Sprite2D              # 据点视觉区域（半透明圆形）
├── CollisionShape2D      # 碰撞体（圆形）
├── ProgressBar (ProgressBar)  # 占领进度条（可选）
└── ColorRect (ColorRect)      # 进度条背景（可选）
```

**碰撞层设置**：
- CapturePoint: Layer = 5, Mask = 1（玩家层）

---

### 6. Main.tscn（主场景）

```
Main (Node2D) - 脚本: Main.gd
├── Player (CharacterBody2D)    # 玩家实例
├── Spawner (Node2D)            # 生成器实例
├── Camera2D                    # 摄像机
├── Background (ColorRect)      # 背景颜色
└── UI (CanvasLayer)            # UI 层
    ├── HPBar (TextureProgressBar)  # 血量条
    ├── CoinLabel (Label)           # 金币显示
    └── RewardPopup (Label)         # 奖励提示
```

**Camera2D 设置**：
- Enabled: true
- Position Smoothing Enabled: true
- Position Smoothing Speed: 5.0
- Limit: Smoothed: true

---

## Godot 项目设置

### 1. 输入映射（Input Map）

在 **Project Settings -> Input Map** 中添加以下操作：

| 动作名称 | 键盘按键 | 说明 |
|---------|---------|------|
| `move_up` | W | 向上移动 |
| `move_down` | S | 向下移动 |
| `move_left` | A | 向左移动 |
| `move_right` | D | 向右移动 |
| `ui_restart` | R | 重新开始游戏 |
| `ui_cancel` | ESC | 暂停/恢复游戏 |

### 2. AutoLoad 设置

在 **Project Settings -> AutoLoad** 中添加 GameManager：

1. 路径: `res://scripts/GameManager.gd`
2. Node Name: `GameManager`
3. 勾选 `Enable`
4. 勾选 `Singleton`

---

## 场景创建步骤指南

### 创建 Player.tscn

1. 创建新场景，根节点选择 `CharacterBody2D`
2. 重命名根节点为 "Player"
3. 添加子节点：
   - 添加 `Sprite2D`，拖入玩家角色贴图
   - 添加 `CollisionShape2D`，设置形状为 CircleShape2D，半径 16
   - 添加 `Area2D`，命名为 "HurtArea"
     - 在 HurtArea 下添加 `CollisionShape2D`，半径 20
     - 在 HurtArea 下添加 `Timer`，命名为 "InvincibilityTimer"
4. 附加脚本 `Player.gd`
5. 保存为 `res://scenes/Player.tscn`

### 创建 Enemy.tscn

1. 创建新场景，根节点选择 `Area2D`
2. 重命名根节点为 "Enemy"
3. 添加子节点：
   - 添加 `Sprite2D`，设置敌人贴图或颜色
   - 添加 `CollisionShape2D`，设置形状为 CircleShape2D，半径 16
   - 添加 `Timer`，命名为 "LifetimeTimer"，设置 One Shot = true
4. 附加脚本 `Enemy.gd`
5. 保存为 `res://scenes/Enemy.tscn`

### 创建 Coin.tscn

1. 创建新场景，根节点选择 `Area2D`
2. 重命名根节点为 "Coin"
3. 添加子节点：
   - 添加 `Sprite2D`，设置金币颜色为黄色（`modulate = Color.GOLD`）
   - 添加 `CollisionShape2D`，设置形状为 CircleShape2D，半径 8
   - 添加 `Timer`，命名为 "LifetimeTimer"，设置 One Shot = true
4. 附加脚本 `Coin.gd`
5. 保存为 `res://scenes/Coin.tscn`

### 创建 Chest.tscn

1. 创建新场景，根节点选择 `Area2D`
2. 重命名根节点为 "Chest"
3. 添加子节点：
   - 添加 `Sprite2D`，设置宝箱颜色或贴图
   - 添加 `CollisionShape2D`，设置形状为 RectangleShape2D
   - （可选）添加 `AnimationPlayer`，创建开箱动画
4. 附加脚本 `Chest.gd`
5. 保存为 `res://scenes/Chest.tscn`

### 创建 CapturePoint.tscn

1. 创建新场景，根节点选择 `Area2D`
2. 重命名根节点为 "CapturePoint"
3. 添加子节点：
   - 添加 `Sprite2D`，设置半透明圆形（`modulate.a = 0.3`）
   - 添加 `CollisionShape2D`，设置形状为 CircleShape2D，半径 64
   - （可选）添加 `ProgressBar`，显示占领进度
   - （可选）添加 `ColorRect`，作为进度条背景
4. 附加脚本 `CapturePoint.gd`
5. 保存为 `res://scenes/CapturePoint.tscn`

### 创建 Main.tscn

1. 创建新场景，根节点选择 `Node2D`
2. 重命名根节点为 "Main"
3. 添加子节点：
   - 实例化 `Player.tscn`，位置设为 (0, 0)
   - 添加 `Node2D`，命名为 "Spawner"，附加 `Spawner.gd` 脚本
   - 添加 `Camera2D`
   - 添加 `ColorRect`，命名为 "Background"，设置全屏覆盖
   - 添加 `CanvasLayer`，命名为 "UI"
     - 添加 UI 元素（血量条、金币标签等）
4. 附加脚本 `Main.gd`
5. 保存为 `res://scenes/Main.tscn`，并设置为项目主场景

---

## 碰撞层（Collision Layers）配置

建议的碰撞层分配：

| 层 | 名称 | 说明 |
|----|------|------|
| 1 | Player | 玩家 |
| 2 | Enemy | 敌人 |
| 3 | Coin | 金币 |
| 4 | Chest | 宝箱 |
| 5 | CapturePoint | 占领据点 |

---

## 快速开始

1. 在 Godot 中导入此项目
2. 按照"输入映射"部分配置按键
3. 按照"AutoLoad 设置"配置 GameManager
4. 按照"场景创建步骤"创建所有场景
5. 运行 Main.tscn 开始游戏

---

## 游戏机制说明

### 玩家 (Player)
- 初始生命值：3 滴血
- 移动方式：WASD 八向移动
- 受伤机制：碰到敌人扣 1 滴血，有无敌时间
- 回血机制：每收集 10 金币自动恢复 1 滴血（可配置）

### 敌人 (Enemy)
- 生命周期：生成后存活一定时间后自动销毁
- 行为类型：随机为静止或随机移动
- 变异机制：有概率变成 2 倍大小

### 金币 (Coin)
- 生命周期：生成后存活一定时间后消失
- 收集效果：玩家触碰后获得金币，累计可回血

### 占领据点 (CapturePoint)
- 占领机制：玩家在范围内增加进度，离开时进度衰减
- 占领奖励：进度满 100 时获得高额积分

### 宝箱 (Chest)
- 随机奖励：6 种效果随机抽取
- 包括：移速提升、恢复生命、财富、无敌星、金币雨、圣光涌动

---

## 扩展建议

1. **美术资源**：添加角色、敌人、金币等贴图
2. **音效**：添加拾取、受伤、奖励等音效
3. **UI 美化**：创建更精美的 HUD 和进度条
4. **关卡设计**：添加不同的地图布局
5. **难度系统**：随时间增加难度（生成更多敌人）

---

## 脚本功能总结

| 脚本 | 主要功能 |
|------|----------|
| GameManager.gd | 全局状态管理，金币/血量统计，BUFF 管理，清除敌人等 |
| Player.gd | 玩家移动，受伤处理，无敌状态，BUFF 应用 |
| Enemy.gd | 生命周期管理，随机行为（静止/移动），伤害玩家 |
| Coin.gd | 金币生命周期，旋转浮动动画，拾取逻辑 |
| Chest.gd | 随机奖励系统，6 种奖励效果 |
| CapturePoint.gd | 占领进度计算，进出检测，进度衰减 |
| Spawner.gd | 定时生成敌人、金币、据点、宝箱 |
| Main.gd | 主场景控制，游戏流程管理，UI 更新 |

---

祝你开发顺利！如有任何问题，请参考 Godot 4 官方文档。
