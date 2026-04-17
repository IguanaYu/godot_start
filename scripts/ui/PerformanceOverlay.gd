## 性能显示面板（PerformanceOverlay.gd）
## 功能：在屏幕右上角实时显示 FPS、帧时间、内存占用等性能数据
extends PanelContainer

## 刷新间隔（秒）
var _update_interval: float = 0.25
## 上次刷新时间
var _last_update_time: float = 0.0

## 节点引用
@onready var _fps_label: Label = $VBoxContainer/FPSLabel
@onready var _frame_time_label: Label = $VBoxContainer/FrameTimeLabel
@onready var _memory_label: Label = $VBoxContainer/MemoryLabel
@onready var _nodes_label: Label = $VBoxContainer/NodesLabel
@onready var _objects_label: Label = $VBoxContainer/ObjectsLabel

func _process(delta: float) -> void:
	_last_update_time += delta
	if _last_update_time < _update_interval:
		return
	_last_update_time = 0.0

	var fps: float = Performance.get_monitor(Performance.TIME_FPS)
	var frame_time: float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var memory_mb: float = Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	var node_count: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	var object_count: int = int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))

	_fps_label.text = "FPS: %d" % fps
	_frame_time_label.text = "帧时间: %.1fms" % frame_time
	_memory_label.text = "内存: %.1fMB" % memory_mb
	_nodes_label.text = "节点数: %d" % node_count
	_objects_label.text = "对象数: %d" % object_count

	# FPS 低时变红警告
	if fps < 30:
		_fps_label.add_theme_color_override("font_color", Color.RED)
	elif fps < 50:
		_fps_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		_fps_label.add_theme_color_override("font_color", Color.GREEN)
