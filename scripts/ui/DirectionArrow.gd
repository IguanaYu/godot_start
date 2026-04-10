## 方向箭头脚本
## 功能：显示指向目标的箭头
extends Control
class_name DirectionArrow

## ========== 节点引用 ==========

## 箭头纹理引用
@onready var texture_rect: TextureRect = $ArrowTextureRect

## ========== 公共方法 ==========

## 设置箭头颜色
func set_arrow_color(color: Color) -> void:
	if texture_rect != null:
		texture_rect.modulate = color
