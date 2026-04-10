## 收集品数据Resource类
## 功能：定义游戏中的各种收集品属性和效果
extends Resource
class_name CollectibleData

## ========== 收集品类型枚举 ==========

enum CollectibleType {
	COLLECTIBLE,        # 碰到即拾取（金币、钥匙）
	AREA_STAY,          # 碰到并停留（占领区域）
	AREA_INTERACT,      # 需要按键交互（宝箱、NPC）
	TRIGGER             # 触发型（撤离点）
}

## ========== 收集品基础信息 ==========

## 收集品显示名称
@export var display_name: String = ""
## 收集品描述
@export_multiline var description: String = ""
## 收集品类型
@export var collectible_type: CollectibleType = CollectibleType.COLLECTIBLE

## ========== 视觉配置 ==========

## 精灵贴图
@export var sprite_texture: Texture2D = null
## 调制颜色
@export var modulate_color: Color = Color.WHITE
## 缩放
@export var scale: Vector2 = Vector2.ONE
## Z轴索引
@export var z_index: int = 0

## ========== 碰撞配置 ==========

## 碰撞形状类型（"circle" 或 "rectangle"）
@export var collision_shape_type: String = "circle"
## 碰撞形状尺寸
@export var collision_shape_size: Vector2 = Vector2(32, 32)

## ========== 行为配置 ==========

## 金币价值
@export var coin_value: int = 0
## 生命值恢复
@export var health_value: int = 0
## 生命周期（0=永久）
@export var lifetime: float = 0.0
## 获得时的提示文本
@export var reward_text: String = ""
## 自定义效果标识
@export var custom_effect: String = ""

## ========== 区域配置（AREA_STAY类型） ==========

## 占领所需时间
@export var capture_time: float = 5.0
## 占领完成金币奖励
@export var capture_bonus_coins: int = 0

## ========== 方向指引配置 ==========

## 是否显示方向箭头
@export var show_direction_arrow: bool = false
## 箭头颜色
@export var arrow_color: Color = Color.YELLOW
## 显示箭头的距离阈值
@export var arrow_show_distance: float = 200.0
## 隐藏箭头的距离阈值
@export var arrow_hide_distance: float = 150.0
## 箭头优先级（多个时排序）
@export var arrow_priority: int = 0

## ========== 动画配置 ==========

## 启用旋转
@export var enable_rotation: bool = false
## 旋转速度（度/秒）
@export var rotation_speed: float = 180.0
## 启用浮动
@export var enable_float: bool = false
## 浮动幅度
@export var float_amplitude: float = 10.0
## 浮动频率
@export var float_frequency: float = 2.0

## ========== 辅助方法 ==========

## 验证数据完整性
func is_valid() -> bool:
	return display_name != ""
