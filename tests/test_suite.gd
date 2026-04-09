## 测试套件配置
## 用于配置GUT测试运行器的全局设置
extends GutTest

## ========== 测试套件级别的初始化 ==========

## 所有测试开始前执行一次
func before_all():
	print("=== 开始运行测试套件 ===")
	print("测试时间: ", Time.get_datetime_string_from_system())
	print("")

## 所有测试结束后执行一次
func after_all():
	print("")
	print("=== 测试套件运行完成 ===")
	print("结束时间: ", Time.get_datetime_string_from_system())

## ========== 全局测试设置 ==========

## 每个测试脚本开始前执行
func setup():
	# 确保每个测试脚本都有干净的状态
	GameManager.reset_game()
	GameManager.reset_coins()
	GameManager.reset_health()

## 每个测试脚本结束后执行
func teardown():
	# 清理工作（如果需要）
	pass

## ========== 辅助方法 ==========

## 打印分隔线（用于测试输出）
func print_separator(text: String = ""):
	print("================================")
	if not text.is_empty():
		print(text)
	print("================================")
