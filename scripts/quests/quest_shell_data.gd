class_name QuestShellData
extends Resource
## 任务壳子数据。只记录任务的元信息，不包含具体逻辑。
## 未来扩展时再添加 objectives、rewards 等字段。

@export var quest_id: String = ""
@export var quest_name_key: String = ""
@export var quest_desc_key: String = ""
@export var category: String = "side"  ## "main" / "side" / "daily"
@export var hidden: bool = false       ## 是否隐藏（直到解锁才显示）
