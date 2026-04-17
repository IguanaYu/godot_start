extends Control
## 对话 UI。显示对话文本、头像和选项按钮。

signal advance_requested()
signal choice_made(index: int)

## 打字机速度（每秒字符数）
@export var typewriter_speed: float = 30.0

@onready var dim_overlay: ColorRect = $DimOverlay
@onready var dialogue_box: PanelContainer = $DialogueBox
@onready var speaker_label: Label = $DialogueBox/MarginContainer/VBoxContainer/SpeakerLabel
@onready var portrait_rect: TextureRect = $DialogueBox/MarginContainer/VBoxContainer/HBoxContainer/PortraitRect
@onready var text_label: RichTextLabel = $DialogueBox/MarginContainer/VBoxContainer/HBoxContainer/TextLabel
@onready var continue_indicator: Label = $DialogueBox/MarginContainer/VBoxContainer/ContinueIndicator
@onready var choice_container: VBoxContainer = $ChoiceContainer

var _is_typing: bool = false
var _full_text: String = ""
var _current_char: int = 0
var _type_timer: float = 0.0
var _choices_visible: bool = false


func _ready() -> void:
	hide_dialogue()
	# 连接选项按钮信号
	for i in range(choice_container.get_child_count()):
		var btn: Button = choice_container.get_child(i)
		btn.pressed.connect(_on_choice_button_pressed.bind(i))
		btn.visible = false


func _process(delta: float) -> void:
	if not visible:
		return

	if _is_typing:
		_type_timer += delta
		var chars_to_add := int(_type_timer * typewriter_speed)
		if chars_to_add > 0:
			_type_timer -= float(chars_to_add) / typewriter_speed
			_current_char = mini(_current_char + chars_to_add, _full_text.length())
			text_label.text = _full_text.substr(0, _current_char)
			if _current_char >= _full_text.length():
				_finish_typing()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if _choices_visible:
		# 选项显示时，不处理 advance
		return

	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		if _is_typing:
			_skip_typing()
		else:
			advance_requested.emit()


func show_dialogue(speaker: String, text: String, portrait_texture: Texture2D = null) -> void:
	_choices_visible = false
	choice_container.visible = false

	# 说话人
	if speaker == "":
		speaker_label.visible = false
	else:
		speaker_label.visible = true
		speaker_label.text = speaker

	# 头像
	if portrait_texture != null:
		portrait_rect.texture = portrait_texture
		portrait_rect.visible = true
	else:
		portrait_rect.visible = false

	# 文本（启动打字机）
	dialogue_box.visible = true
	continue_indicator.visible = false
	_start_typewriter(text)


func show_choices(choices: Array) -> void:
	"""显示选项列表。choices 是 Array[ChoiceData] 或 Array[String]。"""
	_choices_visible = true
	dialogue_box.visible = false
	choice_container.visible = true

	for i in range(choice_container.get_child_count()):
		var btn: Button = choice_container.get_child(i)
		if i < choices.size():
			btn.visible = true
			var choice = choices[i]
			if choice is String:
				btn.text = choice
			elif choice is ChoiceData:
				btn.text = DialogueRunner._get_text(choice.text_key) if DialogueRunner else choice.text_key
			else:
				btn.text = str(choice)
		else:
			btn.visible = false

	# 自动聚焦第一个选项
	if choices.size() > 0:
		var first_btn: Button = choice_container.get_child(0)
		first_btn.grab_focus()


func hide_choices() -> void:
	_choices_visible = false
	choice_container.visible = false
	for child in choice_container.get_children():
		child.visible = false


func hide_dialogue() -> void:
	_is_typing = false
	_full_text = ""
	_current_char = 0
	_type_timer = 0.0
	_choices_visible = false
	dialogue_box.visible = false
	choice_container.visible = false
	visible = false


func _start_typewriter(text: String) -> void:
	_full_text = text
	_current_char = 0
	_type_timer = 0.0
	_is_typing = true
	text_label.text = ""
	continue_indicator.visible = false


func _finish_typing() -> void:
	_is_typing = false
	text_label.text = _full_text
	continue_indicator.visible = true


func _skip_typing() -> void:
	_finish_typing()


func _on_choice_button_pressed(index: int) -> void:
	choice_made.emit(index)
