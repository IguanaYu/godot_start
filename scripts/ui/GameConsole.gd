## 游戏内控制台（GameConsole.gd）
## 功能：捕获并显示游戏日志信息，支持按级别过滤
## 使用方式：在 Project Settings -> AutoLoad 中设置为单例（排在 GameManager 之前）
## 快捷键：F12 切换显示，不暂停游戏

extends CanvasLayer

## ========== 枚举与常量 ==========

enum LogLevel { INFO, WARN, ERROR }

const MAX_LOG_ENTRIES := 500
const INFO_COLOR := Color(0.85, 0.85, 0.85)
const WARN_COLOR := Color(1.0, 0.85, 0.3)
const ERROR_COLOR := Color(1.0, 0.35, 0.35)
const ACTIVE_TAB_COLOR := Color(0.4, 0.65, 0.95)
const INACTIVE_TAB_COLOR := Color(0.5, 0.5, 0.5)

## ========== 状态 ==========

var _log_buffer: Array = []
var _is_open := false
var _current_filter: int = -1  # -1 = ALL
var _auto_scroll := true
var _is_logging := false  # 防递归保护
var _pending_entries: Array = []

## ========== UI引用 ==========

var _main_panel: PanelContainer
var _log_display: RichTextLabel
var _scroll: ScrollContainer
var _count_label: Label
var _auto_scroll_btn: Button
var _filter_btns: Array[Button] = []

## ========== 生命周期 ==========

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	visible = false

## ========== 公共日志 API ==========

func info(text: String) -> void:
	_add_log(LogLevel.INFO, text)

func warn(text: String) -> void:
	_add_log(LogLevel.WARN, text)

func error(text: String) -> void:
	_add_log(LogLevel.ERROR, text)

## ========== 日志核心 ==========

func _add_log(level: int, text: String) -> void:
	if _is_logging:
		return

	# 双通道：同时输出到 Godot 后台
	_is_logging = true
	match level:
		LogLevel.INFO:
			print(text)
		LogLevel.WARN:
			push_warning(text)
		LogLevel.ERROR:
			push_error(text)
	_is_logging = false

	# 存入缓冲区
	_log_buffer.append({
		"level": level,
		"text": text,
		"timestamp": Time.get_ticks_msec(),
	})
	if _log_buffer.size() > MAX_LOG_ENTRIES:
		_log_buffer.pop_front()

	_pending_entries.append(_log_buffer[-1])

## ========== UI构建 ==========

func _build_ui() -> void:
	# 主面板（底部40%，覆盖整个宽度）
	_main_panel = PanelContainer.new()
	_main_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_main_panel.anchor_top = 0.6
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	panel_style.border_color = Color(0.35, 0.35, 0.45, 0.5)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(6)
	panel_style.set_content_margin_all(10)
	_main_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_main_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	_main_panel.add_child(vbox)

	# 标题栏
	var header := HBoxContainer.new()
	vbox.add_child(header)

	var title := Label.new()
	title.text = "Console"
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "x"
	close_btn.flat = true
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	close_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	close_btn.pressed.connect(close)
	header.add_child(close_btn)

	# 过滤栏
	var filter_bar := HBoxContainer.new()
	filter_bar.add_theme_constant_override("separation", 6)
	vbox.add_child(filter_bar)

	var filter_names := ["ALL", "INFO", "WARN", "ERROR"]
	var filter_values := [-1, LogLevel.INFO, LogLevel.WARN, LogLevel.ERROR]
	for i in filter_names.size():
		var btn := Button.new()
		btn.text = filter_names[i]
		btn.flat = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 12)
		btn.add_theme_color_override("font_color", ACTIVE_TAB_COLOR if i == 0 else INACTIVE_TAB_COLOR)
		btn.add_theme_color_override("font_hover_color", Color.WHITE)
		btn.pressed.connect(_on_filter_pressed.bind(filter_values[i]))
		filter_bar.add_child(btn)
		_filter_btns.append(btn)

	_count_label = Label.new()
	_count_label.text = "0"
	_count_label.add_theme_font_size_override("font_size", 11)
	_count_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	_count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	filter_bar.add_child(_count_label)

	# 日志显示区 — ScrollContainer + RichTextLabel
	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(_scroll)

	_log_display = RichTextLabel.new()
	_log_display.bbcode_enabled = true
	_log_display.fit_content = true
	_log_display.scroll_active = false
	_log_display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_display.add_theme_font_size_override("normal_font_size", 12)
	_log_display.add_theme_color_override("default_color", INFO_COLOR)
	_scroll.add_child(_log_display)

	# 底部栏
	var footer := HBoxContainer.new()
	vbox.add_child(footer)

	var clear_btn := Button.new()
	clear_btn.text = "清空"
	clear_btn.flat = true
	clear_btn.focus_mode = Control.FOCUS_NONE
	clear_btn.add_theme_font_size_override("font_size", 11)
	clear_btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	clear_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	clear_btn.pressed.connect(_on_clear_pressed)
	footer.add_child(clear_btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)

	_auto_scroll_btn = Button.new()
	_auto_scroll_btn.text = "自动滚动: ON"
	_auto_scroll_btn.flat = true
	_auto_scroll_btn.focus_mode = Control.FOCUS_NONE
	_auto_scroll_btn.add_theme_font_size_override("font_size", 11)
	_auto_scroll_btn.add_theme_color_override("font_color", ACTIVE_TAB_COLOR)
	_auto_scroll_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	_auto_scroll_btn.pressed.connect(_on_auto_scroll_toggled)
	footer.add_child(_auto_scroll_btn)

	# 等进入场景树后连接滚动条信号
	call_deferred("_connect_scroll_signal")

func _connect_scroll_signal() -> void:
	var sb := _scroll.get_v_scroll_bar()
	if sb != null:
		sb.value_changed.connect(_on_scroll_changed)

## ========== 开关控制 ==========

func toggle() -> void:
	if _is_open:
		close()
	else:
		open()

func open() -> void:
	_is_open = true
	visible = true
	_refresh_display()
	_auto_scroll = true
	# 下一帧滚动到底部
	call_deferred("_do_scroll_bottom")

func close() -> void:
	_is_open = false
	visible = false

## ========== 输入处理 ==========

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_console"):
		toggle()
		get_viewport().set_input_as_handled()

## ========== 每帧更新 ==========

func _process(_delta: float) -> void:
	if not _is_open:
		_pending_entries.clear()
		return

	if _pending_entries.size() > 0:
		_flush_pending()

## ========== 日志显示刷新 ==========

func _flush_pending() -> void:
	var text := ""
	for entry in _pending_entries:
		if _current_filter == -1 or entry["level"] == _current_filter:
			text += _format_bbcode(entry) + "\n"
	_pending_entries.clear()

	if text != "":
		_log_display.append_text(text)
		_update_count()
		if _auto_scroll:
			call_deferred("_do_scroll_bottom")

func _refresh_display() -> void:
	_log_display.clear()
	var text := ""
	for entry in _log_buffer:
		if _current_filter == -1 or entry["level"] == _current_filter:
			text += _format_bbcode(entry) + "\n"

	if text != "":
		_log_display.append_text(text)
	_update_count()

func _format_bbcode(entry: Dictionary) -> String:
	var time_str := _fmt_time(entry["timestamp"])
	var level_name := ""
	var color_hex := ""

	match entry["level"]:
		LogLevel.INFO:
			level_name = "INFO"
			color_hex = INFO_COLOR.to_html(false)
		LogLevel.WARN:
			level_name = "WARN"
			color_hex = WARN_COLOR.to_html(false)
		LogLevel.ERROR:
			level_name = "ERROR"
			color_hex = ERROR_COLOR.to_html(false)

	var msg: String = str(entry["text"]).replace("[", "[lb]").replace("]", "[rb]")
	return "[color=#" + color_hex + "]" + time_str + " | " + level_name + " | " + msg + "[/color]"

func _fmt_time(msec) -> String:
	var total: int = int(msec) / 1000
	var h: int = total / 3600
	var m: int = (total % 3600) / 60
	var s: int = total % 60
	return "%02d:%02d:%02d" % [h, m, s]

func _do_scroll_bottom() -> void:
	var sb := _scroll.get_v_scroll_bar()
	if sb != null:
		sb.value = sb.max_value

## ========== 事件回调 ==========

func _on_filter_pressed(filter_value: int) -> void:
	_current_filter = filter_value
	# 更新按钮样式
	var filter_values := [-1, LogLevel.INFO, LogLevel.WARN, LogLevel.ERROR]
	for i in _filter_btns.size():
		var active: bool = (filter_values[i] == _current_filter)
		_filter_btns[i].add_theme_color_override("font_color", ACTIVE_TAB_COLOR if active else INACTIVE_TAB_COLOR)
	_refresh_display()
	call_deferred("_do_scroll_bottom")

func _on_clear_pressed() -> void:
	_log_buffer.clear()
	_pending_entries.clear()
	_log_display.clear()
	_update_count()

func _on_auto_scroll_toggled() -> void:
	_auto_scroll = not _auto_scroll
	_auto_scroll_btn.text = "自动滚动: ON" if _auto_scroll else "自动滚动: OFF"
	_auto_scroll_btn.add_theme_color_override("font_color", ACTIVE_TAB_COLOR if _auto_scroll else INACTIVE_TAB_COLOR)
	if _auto_scroll:
		call_deferred("_do_scroll_bottom")

func _on_scroll_changed(value: float) -> void:
	if not _auto_scroll:
		return
	var sb := _scroll.get_v_scroll_bar()
	if sb != null and value < sb.max_value - sb.page - 10:
		_auto_scroll = false
		_auto_scroll_btn.text = "自动滚动: OFF"
		_auto_scroll_btn.add_theme_color_override("font_color", INACTIVE_TAB_COLOR)

func _update_count() -> void:
	var total := _log_buffer.size()
	if _current_filter == -1:
		_count_label.text = "%d 条" % total
	else:
		var n := 0
		for entry in _log_buffer:
			if entry["level"] == _current_filter:
				n += 1
		_count_label.text = "%d / %d 条" % [n, total]
