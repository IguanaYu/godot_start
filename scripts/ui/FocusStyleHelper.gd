## 焦点样式辅助工具
## 为菜单按钮、滑块、面板提供统一的焦点视觉样式
class_name FocusStyleHelper

## 金色主题色
const GOLD := Color(1, 0.84, 0, 1)
## 暗色背景
const DARK_BG := Color(0.15, 0.15, 0.2, 0.9)
## 按下状态色（略暗的金色）
const PRESSED_BORDER := Color(0.85, 0.7, 0, 1)
## 禁用状态色
const DISABLED_COLOR := Color(0.5, 0.5, 0.5, 0.5)
## 选中状态色（绿色）
const SELECTED_BORDER := Color(0.2, 0.9, 0.4, 1)

## 为按钮应用统一的焦点样式
static func apply_button_style(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = DARK_BG
	normal.set_corner_radius_all(8)
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	normal.content_margin_left = 16
	normal.content_margin_right = 16

	var focused := StyleBoxFlat.new()
	focused.bg_color = DARK_BG
	focused.set_corner_radius_all(8)
	focused.border_color = GOLD
	focused.set_border_width_all(2)
	focused.content_margin_top = 8
	focused.content_margin_bottom = 8
	focused.content_margin_left = 16
	focused.content_margin_right = 16

	var hover := focused.duplicate()
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = DARK_BG
	pressed.set_corner_radius_all(8)
	pressed.border_color = PRESSED_BORDER
	pressed.set_border_width_all(2)
	pressed.content_margin_top = 8
	pressed.content_margin_bottom = 8
	pressed.content_margin_left = 16
	pressed.content_margin_right = 16

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("focused", focused)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)

## 为容器的所有子按钮应用样式
static func apply_to_all_buttons(container: Container) -> void:
	for child in container.get_children():
		if child is Button:
			apply_button_style(child)

## 为面板创建焦点样式
static func create_panel_focused_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.set_corner_radius_all(10)
	style.border_color = GOLD
	style.set_border_width_all(3)
	return style

## 为面板创建普通样式
static func create_panel_normal_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.7)
	style.set_corner_radius_all(10)
	return style

## 为面板创建选中样式
static func create_panel_selected_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.set_corner_radius_all(10)
	style.border_color = SELECTED_BORDER
	style.set_border_width_all(3)
	return style
