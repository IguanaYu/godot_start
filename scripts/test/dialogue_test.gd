extends Node2D
## 对话系统测试场景。程序化构建对话图，验证所有节点类型和功能。

## 对话节点类型常量（与 DialogueNodeData.NodeType 对应）
const N_START := 0
const N_DIALOGUE := 1
const N_CHOICE := 2
const N_CONDITION := 3
const N_ACTION := 4
const N_SUB_DIALOGUE := 5
const N_END := 6

# 动作类型常量
const A_SET_FLAG := 0
const A_GIVE_COINS := 2
const A_START_QUEST := 7

# 条件类型常量
const C_FLAG_SET := 0

# 节点引用
@onready var player: CharacterBody2D = $Player
@onready var npc_basic: Area2D = $TestNPCs/NPC_Basic
@onready var npc_branch: Area2D = $TestNPCs/NPC_Branch
@onready var npc_condition: Area2D = $TestNPCs/NPC_Condition
@onready var npc_sub: Area2D = $TestNPCs/NPC_Sub
@onready var npc_unlock: Area2D = $TestNPCs/NPC_Unlock
@onready var dialogue_ui: Control = $UI/DialogueUI
@onready var status_label: Label = $UI/TestPanel/VBox/StatusLabel
@onready var flag_label: Label = $UI/TestPanel/VBox/FlagLabel


func _ready() -> void:
	# 连接 DialogueUI 到 DialogueRunner
	DialogueRunner.dialogue_ui = dialogue_ui
	dialogue_ui.advance_requested.connect(_on_dialogue_advance)
	dialogue_ui.choice_made.connect(_on_dialogue_choice)
	dialogue_ui.visible = false

	# 连接 DialogueRunner 信号用于状态更新
	DialogueRunner.dialogue_ended.connect(_on_dialogue_ended)

	# 注册所有测试对话图
	_register_all_dialogues()

	# 连接测试面板按钮
	_connect_buttons()

	# 禁止测试面板按钮获取键盘焦点
	for btn in $UI/TestPanel/VBox.get_children():
		if btn is Button:
			btn.focus_mode = Control.FOCUS_NONE

	# 设置 Player 的输入
	player.set_process(true)

	_update_status()


# ==================== 工具函数 ====================

## 创建一个对话节点
func _make_node(node_id: String, node_type: int, text: String = "", speaker: String = "npc") -> Resource:
	var node = DialogueNodeData.new()
	node.node_id = node_id
	node.node_type = node_type
	node.text_key = text
	node.speaker = speaker
	return node


## 创建一个选择选项
func _make_choice(text: String, target_node_id: String = "") -> Resource:
	var choice = ChoiceData.new()
	choice.text_key = text
	choice.target_node_id = target_node_id
	return choice


## 创建一个动作
func _make_action(action_type: int, params: Dictionary) -> Resource:
	var action = ActionData.new()
	action.action_type = action_type
	action.params = params
	return action


## 创建一个条件
func _make_condition(cond_type: int, params: Dictionary, negated: bool = false) -> Resource:
	var cond = ConditionData.new()
	cond.condition_type = cond_type
	cond.params = params
	cond.negated = negated
	return cond


## 创建一个连接
func _make_conn(from: String, from_port: int, to: String) -> Resource:
	var conn = DialogueConnection.new()
	conn.from_node = from
	conn.from_port = from_port
	conn.to_node = to
	return conn


## 创建对话图并注册
func _make_graph(graph_id: String, npc_id: String, nodes: Array, connections: Array,
		prereq_graphs: Array = [], completion_flags: Array = [], repeatable: bool = false) -> Resource:
	var graph = DialogueGraph.new()
	graph.graph_id = graph_id
	graph.npc_id = npc_id
	graph.nodes.assign(nodes)
	graph.connections.assign(connections)
	graph.prerequisite_graph_ids.assign(prereq_graphs)
	graph.completion_flags_set.assign(completion_flags)
	graph.repeatable = repeatable
	DialogueManager.register_graph(graph)
	return graph


# ==================== 注册所有测试对话 =================

func _register_all_dialogues() -> void:
	_register_basic()
	_register_branch()
	_register_condition()
	_register_sub()
	_register_sub_inner()
	_register_unlock_1()
	_register_unlock_2()


## 对话1: 基础多段对话
func _register_basic() -> void:
	_make_graph("test_basic", "test_basic",
		[
			_make_node("start", N_START),
			_make_node("greet", N_DIALOGUE, "欢迎来到对话系统测试场景！", "npc"),
			_make_node("intro", N_DIALOGUE, "这里可以测试对话系统的各种功能。走近一个 NPC 然后按 E 开始对话。", "npc"),
			_make_node("tip", N_DIALOGUE, "这个对话可以重复触发，每次都能看到。", "npc"),
			_make_node("end", N_END),
		],
		[
			_make_conn("start", 0, "greet"),
			_make_conn("greet", 0, "intro"),
			_make_conn("intro", 0, "tip"),
			_make_conn("tip", 0, "end"),
		],
		[], [], true  # repeatable
	)


## 对话2: 分支选择
func _register_branch() -> void:
	_make_graph("test_branch", "test_branch",
		[
			_make_node("start", N_START),
			_make_node("ask", N_DIALOGUE, "你想了解什么？请选择一个选项：", "npc"),
			_make_node("choice", N_CHOICE, "", ""),
			_make_node("talk_combat", N_DIALOGUE, "战斗的核心是保持移动！不要停下来挨打。", "npc"),
			_make_node("talk_shop", N_DIALOGUE, "商店每天会刷新商品，记得常来看看。", "npc"),
			_make_node("talk_secret", N_DIALOGUE, "其实...地图上有些隐藏的宝藏，仔细找找看。", "npc"),
			_make_node("talk_bye", N_DIALOGUE, "好的，下次再见！", "npc"),
			_make_node("end", N_END),
		],
		[
			_make_conn("start", 0, "ask"),
			_make_conn("ask", 0, "choice"),
			# choice: port 1=第一个选项, port 2=第二个选项, port 3=第三个选项
			_make_conn("choice", 1, "talk_combat"),
			_make_conn("choice", 2, "talk_shop"),
			_make_conn("choice", 3, "talk_secret"),
			_make_conn("talk_combat", 0, "talk_bye"),
			_make_conn("talk_shop", 0, "talk_bye"),
			_make_conn("talk_secret", 0, "talk_bye"),
			_make_conn("talk_bye", 0, "end"),
		],
		[], [], true  # repeatable
	)
	# 设置选项
	var graph = DialogueManager.get_graph("test_branch")
	for node in graph.nodes:
		if node.node_id == "choice":
			node.choices.assign([
				_make_choice("战斗技巧"),
				_make_choice("商店系统"),
				_make_choice("告诉我一个秘密"),
			])


## 对话3: 条件分支
func _register_condition() -> void:
	_make_graph("test_condition", "test_condition",
		[
			_make_node("start", N_START),
			_make_node("check", N_CONDITION, "", ""),
			_make_node("has_flag", N_DIALOGUE, "你身上有标记 X！看来你已经用面板设置过了。这是一个条件解锁的特殊对话！", "npc"),
			_make_node("no_flag", N_DIALOGUE, "你还没有标记 X。试试左上角面板上的「设置标记X」按钮，然后再来跟我说话！", "npc"),
			_make_node("end", N_END),
		],
		[
			_make_conn("start", 0, "check"),
			_make_conn("check", 0, "has_flag"),   # true → port 0
			_make_conn("check", 1, "no_flag"),     # false → port 1
			_make_conn("has_flag", 0, "end"),
			_make_conn("no_flag", 0, "end"),
		],
		[], [], true  # repeatable
	)
	# 设置条件
	var graph = DialogueManager.get_graph("test_condition")
	for node in graph.nodes:
		if node.node_id == "check":
			node.condition = _make_condition(C_FLAG_SET, {"flag_name": "test_x"})


## 对话4a: 子对话（主对话）
func _register_sub() -> void:
	_make_graph("test_sub", "test_sub",
		[
			_make_node("start", N_START),
			_make_node("intro", N_DIALOGUE, "我要给你讲一个故事，准备好了吗？", "npc"),
			_make_node("sub_call", N_SUB_DIALOGUE, "", ""),
			_make_node("after", N_DIALOGUE, "故事讲完了。这就是子对话的效果——中间插入了一段独立的对话，然后回到主对话继续。", "npc"),
			_make_node("end", N_END),
		],
		[
			_make_conn("start", 0, "intro"),
			_make_conn("intro", 0, "sub_call"),
			_make_conn("sub_call", 0, "after"),
			_make_conn("after", 0, "end"),
		],
		[], [], true  # repeatable
	)
	var graph = DialogueManager.get_graph("test_sub")
	for node in graph.nodes:
		if node.node_id == "sub_call":
			node.target_graph_id = "test_sub_inner"


## 对话4b: 子对话（内部对话）
func _register_sub_inner() -> void:
	_make_graph("test_sub_inner", "",  # 空 npc_id，不直接触发
		[
			_make_node("start", N_START),
			_make_node("p1", N_DIALOGUE, "什么样的故事？", "player"),
			_make_node("n1", N_DIALOGUE, "很久以前，在这片大陆上...", "npc"),
			_make_node("n2", N_DIALOGUE, "有一个勇敢的旅行者，他不畏艰险，勇往直前。", "npc"),
			_make_node("end", N_END),
		],
		[
			_make_conn("start", 0, "p1"),
			_make_conn("p1", 0, "n1"),
			_make_conn("n1", 0, "n2"),
			_make_conn("n2", 0, "end"),
		],
		[], [], false
	)


## 对话5a: 解锁链 - 第一段
func _register_unlock_1() -> void:
	_make_graph("test_unlock_1", "test_unlock",
		[
			_make_node("start", N_START),
			_make_node("greet", N_DIALOGUE, "你好旅行者！这是我们的第一次见面。", "npc"),
			_make_node("give", N_ACTION, "", ""),
			_make_node("after_give", N_DIALOGUE, "我给了你 50 金币作为见面礼！下次再来找我，我有新的事情要告诉你。", "npc"),
			_make_node("end", N_END),
		],
		[
			_make_conn("start", 0, "greet"),
			_make_conn("greet", 0, "give"),
			_make_conn("give", 0, "after_give"),
			_make_conn("after_give", 0, "end"),
		],
		[],  # 无前置条件
		["met_test_npc"]  # 完成后设置标记
	)
	# 设置动作：给 50 金币
	var graph = DialogueManager.get_graph("test_unlock_1")
	for node in graph.nodes:
		if node.node_id == "give":
			node.actions.assign([
				_make_action(A_SET_FLAG, {"flag_name": "met_test_npc"}),
				_make_action(A_GIVE_COINS, {"amount": 50}),
			])


## 对话5b: 解锁链 - 第二段
func _register_unlock_2() -> void:
	_make_graph("test_unlock_2", "test_unlock",
		[
			_make_node("start", N_START),
			_make_node("meet_again", N_DIALOGUE, "我们又见面了！上次给你的金币用得怎么样？", "npc"),
			_make_node("quest_action", N_ACTION, "", ""),
			_make_node("after_quest", N_DIALOGUE, "我给你安排了一个新任务！虽然任务系统还是个壳子，但对话解锁链已经验证成功了。", "npc"),
			_make_node("player_respond", N_DIALOGUE, "明白了，我会去完成的。", "player"),
			_make_node("end", N_END),
		],
		[
			_make_conn("start", 0, "meet_again"),
			_make_conn("meet_again", 0, "quest_action"),
			_make_conn("quest_action", 0, "after_quest"),
			_make_conn("after_quest", 0, "player_respond"),
			_make_conn("player_respond", 0, "end"),
		],
		["test_unlock_1"],  # 前置条件：完成第一段对话
		[]
	)
	# 设置动作：启动任务
	var graph = DialogueManager.get_graph("test_unlock_2")
	for node in graph.nodes:
		if node.node_id == "quest_action":
			node.actions.assign([
				_make_action(A_START_QUEST, {"quest_id": "test_quest_1"}),
			])


# ==================== UI 和事件 ==================

func _connect_buttons() -> void:
	$UI/TestPanel/VBox/BtnSetFlag.pressed.connect(func():
		DialogueManager.set_flag("test_x")
		_update_status()
	)
	$UI/TestPanel/VBox/BtnClearFlag.pressed.connect(func():
		DialogueManager.clear_flag("test_x")
		_update_status()
	)
	$UI/TestPanel/VBox/BtnReset.pressed.connect(func():
		DialogueManager.clear_flag("test_x")
		DialogueManager.clear_flag("met_test_npc")
		GameManager.add_coins(-GameManager._coins)
		_update_status()
		# 重新注册所有对话图
		DialogueManager._graph_definitions.clear()
		DialogueManager._completed_graphs.clear()
		DialogueManager._unlocked_graphs.clear()
		_register_all_dialogues()
		_update_status()
	)
	$UI/TestPanel/VBox/BtnBack.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/ui/menus/StartScreen.tscn")
	)


func _on_dialogue_advance() -> void:
	DialogueRunner.advance()


func _on_dialogue_choice(index: int) -> void:
	DialogueRunner.advance(index)


func _on_dialogue_ended(_graph_id: String) -> void:
	_update_status()


func _update_status() -> void:
	var flags_text := "标记: "
	if DialogueManager.has_flag("test_x"):
		flags_text += "[test_x] "
	if DialogueManager.has_flag("met_test_npc"):
		flags_text += "[met_test_npc] "
	if flags_text == "标记: ":
		flags_text += "(无)"
	flag_label.text = flags_text

	var status := "金币: %d | 解锁对话数: %d | 完成对话数: %d" % [
		GameManager._coins,
		DialogueManager._unlocked_graphs.size(),
		DialogueManager._completed_graphs.size(),
	]
	status_label.text = status


func _process(_delta: float) -> void:
	_update_status()
