# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

food_cleaner 是一个 Godot 4.6 项目（GDScript），玩法为地图探索 + 卡牌战斗。玩家在房间间移动，遭遇"污染食物"怪物后进入回合制卡牌战斗（类似杀戮尖塔）。核心机制包括时间轴行动系统、胃容量/消化系统、五种净化类型。

## 运行与验证

- **引擎**: Godot 4.6.x（直接用编辑器打开 project.godot）
- **语言**: GDScript
- **主场景**: `res://scenes/main/main.tscn`
- **脚本验证**: 在 Godot 编辑器中运行检查语法错误
- **运行测试**: 在 Godot 编辑器中运行游戏，检查运行时错误
- **无自动化测试框架**，验证依赖编辑器运行和手动检查
- **不使用 Godot MCP**，直接读写文件进行修改

## 架构

### 场景流转

```
main.tscn (RunController)
  ├── ExploreScene (探索模式，房间导航)
  ├── BattleScene (卡牌战斗)
  └── ShopScreen (商店)
```

`RunController` 是顶层编排节点，动态实例化和切换上述三个主场景。`SceneTransitionOverlay`（CanvasLayer 100）处理转场动画。

### 数据流

- **静态定义** → `CardCatalog`（从 CSV 加载）、`MonsterCatalog`（代码定义）
- **数据类**（RefCounted）→ `CardData`, `EnemyData`, `FoodBlockData`, `BattleDefinition`
- **运行时实例** → `CardInstance`, `FoodBlockInstance`, `EnemyRuntime`, `PlayerItemInstance`
- **状态容器** → `RunState`（跨战斗持久）、`BattleState`（单场战斗）

### 战斗系统（纯逻辑分离）

- `BattleRules` — 静态类，所有规则判定为纯函数
- `BattleState` — 可变状态容器
- `BattleController`（Node）— 调用 Rules、发射信号
- `BattleScene`（Control）— UI 表现层，监听 Controller 信号

### 地图系统

- `MapGenerator` 生成固定拓扑的房间图，随机分配怪物
- `RoomRuntimeData` 保存每个房间的运行时状态
- 房间场景使用 `RoomAnchor`（tool script）标记生成点
- `ExploreInteractable` 节点处理玩家交互

### 通信方式

不使用 Autoload。系统间通过信号通信：
- `ExploreScene` → `battle_requested`, `room_change_requested`, `restart_requested`
- `BattleScene` → `battle_resolved`
- `ShopScreen` → `exit_requested`
- `BattleController` → `state_changed`, `log_added`, `battle_finished`

## 编码约定

- 文件名: `snake_case`
- 类名: `PascalCase`，使用 `class_name` 注册
- 注释只写规则语义、状态变化、副作用和边界条件，不写低信息量注释
- 优先沿用项目已有模式，不引入新架构或大范围重构
- UI/文本注意中英文长度差异和分辨率适配

## 协作规则（摘自 AGENTS.md）

- 改文件前先说明准备改什么、为什么改
- 不修改与当前任务无关的文件
- 机制/流程变化时同步更新 `devlog.md`（中文记录，含：做了什么、影响文件、如何验证）
- 不执行版本控制操作除非用户明确要求
- 发现更深层问题先说明判断和建议，再决定是否扩大修改

## 关键目录

- `scenes/` — 按功能分：main、battle、explore、rooms、ui
- `scripts/` — 按系统分：core、content、data、explore、map、run、runtime、ui
- `data/` — CSV 数据文件（卡牌、物品）和翻译文件
- `sprites/` — 帧动画 PNG（中文命名目录），运行时从目录加载
- `shaders/` — 自定义着色器（轮廓线等）

## 输入映射

- WASD: 移动（`move_up/down/left/right`）
- E: 交互（`interact`）
- 卡牌操作: 拖拽释放打出，右键取消
