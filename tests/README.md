# Richman游戏测试框架使用指南

## 🎯 快速开始

### 第一次使用（必需步骤）

1. **启用GUT插件**
   - 打开Godot编辑器，加载项目
   - 进入 `Project -> Project Settings -> Plugins`
   - 找到"GUT"或"GutTester"插件
   - 点击"Enable"启用插件
   - 重启编辑器或刷新项目

2. **运行测试**
   - 打开 `tests/TestRunner.tscn` 场景
   - 按 `F6` 运行当前场景
   - 或点击编辑器右上角的"运行当前场景"按钮
   - 等待测试完成，查看测试结果

## 📂 测试目录结构

```
tests/
├── TestRunner.tscn          # 测试运行场景（从这里运行测试）
├── test_suite.gd            # 测试套件全局配置
├── unit/                    # 单元测试
│   ├── test_game_manager.gd   # GameManager测试（金币、生命值、音量等）
│   └── test_item_data.gd      # ItemData测试（物品数据、效果等）
└── test_resources/          # 测试用资源文件
```

## 🚀 运行测试的3种方式

### 方式1：在Godot编辑器中运行（推荐）

1. 打开 `tests/TestRunner.tscn`
2. 按 `F6` 或点击"运行当前场景"
3. 查看GUT控制面板的测试结果

### 方式2：通过命令行运行

```bash
"E:\godot\Godot_v4.6.1-stable_win64_console.exe" --path "F:\godot_game\run_game\richman" --script addons/gut/gut_cmdln.gd -gdir=res://tests/unit
```

### 方式3：使用GUT面板（需要在编辑器中配置）

1. 在编辑器顶部菜单找到 `编辑器` 或 `Editor`
2. 选择 `GUT` 或 `测试`
3. 点击 `Run All` 运行所有测试

## ✅ 当前已实现的测试

### GameManager核心功能测试 (test_game_manager.gd)

- ✅ 金币管理（增加、重置、负数保护）
- ✅ 生命值管理（受伤、恢复、上限检查）
- ✅ 音量管理（主音量、音效、音乐，含限制测试）
- ✅ 背包管理（添加、移除、清空）
- ✅ 统计信息获取

**测试数量：约20个**

### ItemData物品系统测试 (test_item_data.gd)

- ✅ 物品验证（名称、价格有效性）
- ✅ 物品类型识别（永久物品、消耗品）
- ✅ 物品效果应用（回血、生命上限、速度等）
- ✅ 描述文本生成
- ✅ PurchaseData转换

**测试数量：约20个**

## 📊 测试统计

- **总测试用例数**：约40个
- **预计执行时间**：1-3秒
- **测试覆盖率**：GameManager和ItemData核心功能

## 🛠️ 编写新测试

### 创建新的测试文件

1. 在 `tests/unit/` 目录下创建新文件，命名格式：`test_<模块名>.gd`

2. 继承 `GutTest` 类：

```gdscript
extends GutTest

var test_object

# 每个测试前执行
func before_each():
	test_object = MyClass.new()

# 每个测试后执行
func after_each():
	test_object.free()

# 测试示例
func test_something():
	assert_eq(test_object.get_value(), 42, "值应该是42")
```

### 常用的断言方法

```gdscript
# 相等性断言
assert_eq(actual, expected, "错误信息")
assert_ne(actual, unexpected, "不应该相等")

# 布尔断言
assert_true(condition, "应该为真")
assert_false(condition,应该为假")

# 空值断言
assert_null(value, "应该为null")
assert_not_null(value, "不应该为null")

# 数值断言
assert_almost_eq(actual, expected, tolerance, "数值应该接近")

# 字符串断言
assert_str_contains(text, substring, "应该包含子字符串")
```

## 🔧 故障排查

### 问题1：插件未启用

**症状**：运行测试时提示找不到GutTest类

**解决**：
1. 进入 `Project -> Project Settings -> Plugins`
2. 启用GUT插件
3. 重启编辑器

### 问题2：测试文件未找到

**症状**：GUT显示"No tests found"

**解决**：
- 确保测试文件以 `test_` 开头
- 确保测试文件继承自 `GutTest`
- 确保测试文件位于 `tests/` 目录下

### 问题3：测试失败

**症状**：某些测试显示红色失败

**解决**：
- 查看测试失败信息
- 检查被测试的代码是否有bug
- 检查测试用例是否正确（边界条件、初始值等）

## 📈 后续扩展计划

### 第二批测试（可选）
- [ ] CharacterAbility能力系统测试
- [ ] Player移动和无敌逻辑测试
- [ ] 商店购买系统测试

### 集成测试（可选）
- [ ] 关卡流程测试
- [ ] 玩家与敌人交互测试
- [ ] 区域占领和撤离测试

## 📚 参考资源

- **GUT文档**：https://github.com/bitwes/Gut/blob/master/README.md
- **Godot测试最佳实践**：https://docs.godotengine.org/en/stable/tutorials/scripting/unit_testing.html

## 💡 提示

1. **频繁运行测试**：每次修改代码后都运行测试，确保没有引入回归bug
2. **测试应该快速**：单元测试应该在几秒内完成，避免使用耗时的操作
3. **测试应该独立**：每个测试应该独立运行，不依赖其他测试的状态
4. **使用有意义的断言消息**：当测试失败时，清晰的消息能帮助快速定位问题

---

**维护者备注**：
- 本测试框架使用GUT (GDScript Unit Test)
- 创建时间：2026-04-09
- 最后更新：2026-04-09
