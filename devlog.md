# 开发日志

> 当前改为“阶段里程碑”记录方式：优先保留仍能解释项目现状的结果、主要影响文件和验证方式；已被后续实现覆盖的中间修补过程不再逐条展开。

## 2026-05-19

### 战斗时间轴加入手牌悬停预览与出牌缓动反馈
- 做了什么：为战斗手牌补上“预览时间推进”链路。现在悬停或拖拽手牌时，底部时间轴会用半透明高亮标出该牌预计经过的时间区间，并用目标落点标记提示会推进到哪里；若途中会撞上敌人行动，也会一并标亮。真正出牌后，时间轴滚动改为缓动推进，并对本次经过的时间区间和途经行动点做一次短暂强调，帮助玩家看清“这张牌让时间发生了什么”。后续又去掉了时间轴上方额外的黄色 `预计 Xt` 文案，只保留路径与落点，避免信息冗余。
- 影响文件：`scripts/ui/card_view.gd`、`scripts/ui/hand_view.gd`、`scripts/runtime/battle_rules.gd`、`scripts/ui/battle_scene.gd`
- 如何验证：进入战斗后，将鼠标悬停到不同耗时的手牌上，确认时间轴会出现“预计前进到 Xt”的落点与路径高亮；悬停会跨过敌人行动点的牌时，确认对应行动点会被预警标出；移开鼠标或取消拖拽后，预览应消失。实际打出一张 `2t` 或以上的牌，确认时间轴不再瞬移，而是缓动滚动到新位置，并对本次推进区间做一次短暂强调。

### 项目列表图标改为主角角色图标
- 做了什么：将项目管理器中使用的项目图标从默认 `icon.svg` 改为新的 `icon_character.png`。新图标基于现有主角待机帧生成，保留深色圆角底板，并把角色主体裁成更适合小尺寸项目卡片显示的方形构图。
- 影响文件：`project.godot`、`icon_character.png`
- 如何验证：关闭并重新打开 Godot Project Manager，确认 `food_cleaner` 项目卡片左侧图标已变成主角形象；若未立即刷新，可重启 Godot 或重新扫描项目目录。

### 探索地图接入游乐场素材并替换起点/补给房
- 做了什么：将 `start_room` 与 `chest_room` 切换到 `res://sprites/map/游乐场地图/` 套装，并移除这两间房前景层沿用自森林地图时期的黄绿色半透明染色，恢复为素材原始颜色显示。当前探索地图分配为：游乐场用于起点与补给房，森林/小镇/喷泉分别用于其余怪物房与 Boss 路线房间。
- 影响文件：`scenes/rooms/start_room.tscn`、`scenes/rooms/chest_room.tscn`
- 如何验证：在编辑器中打开上述两个房间，确认背景与前景引用已切换到 `游乐场地图`，且前景层不再带森林地图时期的 `self_modulate` 染色；运行项目进入入口前厅和补给角落，确认显示的是游乐场素材原色。

### 探索玩家改为基于碰撞的移动边界
- 做了什么：探索层不再依赖脚本硬 `clamp` 坐标，而是改为 `CharacterBody2D + CollisionShape2D + BoundaryWalls` 的直接碰撞方案。玩家使用 `move_and_slide()` 与四周静态边界墙交互，可活动范围改为由场景碰撞直接决定。
- 影响文件：`scripts/explore/player_actor.gd`、`scripts/explore/explore_scene.gd`、`scenes/explore/explore_scene.tscn`
- 如何验证：打开 `res://scenes/explore/explore_scene.tscn`，确认 `RoomCanvas/PlayerActor` 为 `CharacterBody2D` 且 `BoundaryWalls` 下存在四面边界墙；运行探索后，确认玩家会被场景边界碰撞挡住。

### 战斗界面补齐当前主显示信息
- 做了什么：战斗界面补齐了当前主要展示层，包括：玩家胃袋/敌人掉落顺序显示、独立食物槽叠层、顶部净化进度底板、卡组阅览覆盖层、胜利结算覆盖层，并移除了底部旧占位角色图标。当前战斗结束后会先进入胜利结算层，再决定继续探索或结束本局。
- 影响文件：`scenes/battle/battle_scene.tscn`、`scenes/ui/battle_victory_overlay.tscn`、`scenes/ui/deck_view_overlay.tscn`、`scripts/ui/battle_scene.gd`、`scripts/ui/battle_victory_overlay.gd`、`scripts/ui/deck_view_overlay.gd`、`scripts/ui/food_queue_view.gd`、`scripts/run/run_controller.gd`
- 如何验证：进入战斗后，确认界面可同时看到玩家胃袋与敌人掉落顺序、顶部净化任务区和可打开的卡组覆盖层；取得胜利后，确认会先弹出结算层而不是立刻切回探索。

### 敌方 `CORRUPT_BLOCK` 行为接入真实效果
- 做了什么：将敌方动作 `CORRUPT_BLOCK` 从占位逻辑补成真实战斗效果。敌人触发后会优先污染自己队列前方仍可视为“好”的食物块，使其变为带有负面效果和额外消化惩罚的“变质”食物。
- 影响文件：`scripts/runtime/food_block_instance.gd`、`scripts/runtime/battle_rules.gd`、`scripts/content/sample_battle_factory.gd`、`scripts/content/monster_catalog.gd`
- 如何验证：进入演示战斗或遭遇草莓怪物，推进时间直到其触发 `腐坏扩散`，确认敌方前排好食物块会被改名并附加额外负面效果；之后再吃下这些变质块，确认会带来额外惩罚。

## 2026-05-15

### 探索/战斗/商店切换统一接入顶层转场
- 做了什么：新增独立 `SceneTransitionOverlay` 顶层转场层，并将探索房间切换、探索进战斗、战斗回探索、探索进商店、商店返回探索统一接入同一套全屏转场流程。当前转场层使用独立 `CanvasLayer`，始终压在最上方，并保持“播放到中点再切场、转场期间不可操作”的规则。
- 影响文件：`scenes/ui/scene_transition_overlay.tscn`、`scripts/ui/scene_transition_overlay.gd`、`scripts/run/run_controller.gd`、`scripts/explore/explore_scene.gd`、`scenes/main/main.gd`
- 如何验证：运行游戏并触发任意换房、进战斗、回探索或进出商店，确认都会先播放全屏转场动画，且动画中途才真正切换场景，动画期间不可继续移动或点击界面。

### 探索怪物与房间路线扩展到五种普通怪 + 鱼 Boss
- 做了什么：探索怪物系统稳定为独立 `MonsterCatalog/MonsterDefinition + MonsterEncounter` 结构，现支持棉花糖、糖豆人、蛋糕、面包、草莓和鱼 Boss；各怪物房与战斗表现已打通。地图结构改为固定拓扑下的随机房间分配：起点到 Boss 的整体路线不变，但中段怪物房内容会在开局时随机落位。
- 影响文件：`scripts/content/monster_catalog.gd`、`scripts/content/monster_definition.gd`、`scripts/explore/monster_encounter.gd`、`scripts/map/map_generator.gd`、`scripts/run/battle_definition_builder.gd`、`scripts/ui/battle_enemy_sprite.gd`、`scenes/rooms/*.tscn`
- 如何验证：多次重新开始 run，确认起点之后的怪物房内容会变化，但整体路线结构不变；进入任一怪物房后，确认探索中的怪物动画、交互与战斗中的敌人表现一致。

### 探索地图切换为多套场景主题并补齐前景层
- 做了什么：探索房间已从单一森林底图扩展为森林、小镇、喷泉、游乐场多套地图主题，并统一采用“背景 + 多层前景”叠加方案。不同房间会根据所属主题挂载对应整套前景资源，角色和怪物被夹在背景与前景之间显示。
- 影响文件：`scenes/rooms/start_room.tscn`、`scenes/rooms/chest_room.tscn`、`scenes/rooms/marshmallow_room.tscn`、`scenes/rooms/candy_bean_room.tscn`、`scenes/rooms/cake_room.tscn`、`scenes/rooms/bread_room.tscn`、`scenes/rooms/strawberry_room.tscn`、`scenes/rooms/fish_boss_room.tscn`
- 如何验证：分别进入不同怪物房和功能房，确认不同房间会使用不同地图主题，且前景会显示在主角、怪物和交互物之前。

### 商店作为独立界面场景接入 run
- 做了什么：新增 `shop_screen.tscn` 与 `ShopScreen` 逻辑，商店不再作为可走动探索房，而是作为独立界面场景从宝箱房入口切入，并复用统一转场系统。当前 `exit` 已可正常返回探索，`confirm/cancel` 仍保留为后续扩展入口。
- 影响文件：`scenes/ui/shop_screen.tscn`、`scripts/ui/shop_screen.gd`、`scripts/run/run_state.gd`、`scripts/run/run_factory.gd`、`scripts/run/run_controller.gd`、`scripts/map/map_generator.gd`、`scenes/rooms/chest_room.tscn`
- 如何验证：运行项目进入补给角落，确认可通过出口进入商店；点击 `exit` 后确认会播放转场并返回进入商店前的探索房间。

### 卡组预览覆盖层完成独立界面化
- 做了什么：卡组阅览不再只是文本占位，已稳定为独立覆盖层，支持查看整个卡组、抽牌堆、弃牌堆，并使用项目现有手绘框体与分类按钮素材。首次打开时的单列布局问题也已修正。
- 影响文件：`scenes/ui/deck_view_overlay.tscn`、`scenes/ui/deck_card_tile.tscn`、`scripts/ui/deck_view_overlay.gd`、`scripts/ui/deck_card_tile.gd`
- 如何验证：进入战斗后分别从“查看卡组”“抽牌堆”“弃牌堆”入口打开覆盖层，确认卡牌按多列网格显示，切换标签和关闭覆盖层都正常。

## 2026-05-14

### 卡牌界面改为沿素材轮廓高亮
- 做了什么：`CardView` 已切换到透明原始卡面素材，并将状态高亮从矩形边框改为基于贴图 alpha 边缘的轮廓描边；同时补了时钟区域边缘裁切与颜色表现优化。
- 影响文件：`scenes/ui/card_view.tscn`、`scripts/ui/card_view.gd`
- 如何验证：进入战斗后悬停、拖拽或移动卡牌到可出牌区域，确认高亮沿卡牌与左上角时间素材边缘显示，不再是完整矩形框。

### 时间轴加入卡牌生效标记与悬停预览
- 做了什么：战斗时间轴现在会记录卡牌生效历史，并在对应时间点显示标记；悬停标记时可弹出预览，查看该时间点生效过的卡牌与效果摘要。标记素材已改为透明小图，避免与回合标记重叠。
- 影响文件：`scripts/runtime/card_effect_record.gd`、`scripts/runtime/battle_state.gd`、`scripts/runtime/battle_rules.gd`、`scripts/ui/card_effect_timeline_marker.gd`、`scripts/ui/card_effect_preview_popup.gd`、`scripts/ui/battle_scene.gd`、`sprites/时间轴/卡牌生效卡牌标记.png`
- 如何验证：进入战斗并打出卡牌，确认时间轴会出现对应标记；悬停标记后，确认可看到卡牌名称、耗时与效果摘要。

### 战斗手牌区与日志区布局重调
- 做了什么：手牌整体上移、日志区压缩，给底部时间轴与手牌交互留出更多空间，减少遮挡和拥挤感。
- 影响文件：`scripts/ui/hand_view.gd`、`scenes/battle/battle_scene.tscn`
- 如何验证：进入战斗，确认手牌比旧版更靠上，日志区更紧凑，但拖拽出牌和日志滚动仍正常。

## 2026-05-13

### 探索主角完成场景化、四向动画与描边表现
- 做了什么：探索主角已拆成独立 `player_actor.tscn`，底层实现切换为 `CharacterBody2D + AnimatedSprite2D`，并接入前/后/侧向动画、最近邻缩放后的帧图资源和可调描边 shader。当前主角在探索中可根据移动方向显示对应待机/行走动画，并保留编辑器内直接查看和调节碰撞、交互范围的能力。
- 影响文件：`scenes/explore/player_actor.tscn`、`scripts/explore/player_actor.gd`、`shaders/player_outline.gdshader`、`tools/resize_player_sprites.py`、`sprites/主角动画_256x144/`
- 如何验证：进入探索后，确认主角会根据上下左右方向切换动画，向上移动可显示背面动画；在编辑器中打开 `res://scenes/explore/player_actor.tscn`，确认能直接看到节点树、碰撞与交互区域。

### 战斗主角接入 AnimatedSprite2D 表现与攻击动画
- 做了什么：战斗场景新增独立 `BattlePlayerSprite` 展示节点，默认循环播放待机动画，并在玩家成功打出攻击牌时触发完整攻击动画。
- 影响文件：`scenes/battle/battle_scene.tscn`、`scripts/ui/battle_player_sprite.gd`、`scripts/ui/battle_scene.gd`
- 如何验证：进入战斗，确认场景中可见主角动画；打出攻击牌后，确认主角会播放一次攻击动作再回到待机。

### 标题界面完成独立场景化与开场表现
- 做了什么：标题界面已独立为 `title_screen.tscn`，按封面图层组合显示，并加入一次性开场动画、过场动画接续播放以及眼球跟随鼠标偏移效果。
- 影响文件：`scenes/ui/title_screen.tscn`、`scripts/ui/title_screen.gd`
- 如何验证：运行或预览 `res://scenes/ui/title_screen.tscn`，确认会先播放开场动画，再进入正式封面；移动鼠标时，眼球图层会产生小范围跟随偏移。

### 探索基础结构改为房间模板 + 场景内交互点
- 做了什么：探索层已从“运行时纯代码拼房间”转为“房间模板场景 + 运行时房间数据”结构；房间内出口、怪物、宝箱、提示牌改为直接下沉到房间 scene 中作为 `Node2D + Area2D` 交互点管理，玩家交互也已切换为真正的 `Area2D` 检测。
- 影响文件：`scripts/map/room_runtime_data.gd`、`scripts/explore/room_scene.gd`、`scripts/explore/room_anchor.gd`、`scripts/explore/explore_interactable.gd`、`scripts/explore/explore_scene.gd`、`scenes/rooms/*.tscn`
- 如何验证：打开任一房间 scene，确认能直接看到并编辑交互点；运行探索后，确认靠近出口、怪物、宝箱时会高亮并响应 `E` 交互。

### 入口与补给角落出口位置修正
- 做了什么：调整了 `start_room` 与 `chest_room` 之间的出口摆位，避免热区被障碍物卡住，减少“看不见出口”或“进得去回不来”的情况。
- 影响文件：`scenes/rooms/start_room.tscn`、`scenes/rooms/chest_room.tscn`
- 如何验证：运行项目后从入口前厅进入补给角落，再从补给角落返回入口前厅，确认双向出口都能顺利靠近并按 `E` 触发。

### 净化牌在无对应任务时也允许打出
- 做了什么：移除了净化牌必须先匹配当前净化任务才能打出的前置拦截。现在无对应任务时也可正常出牌，只是不会产生净化收益。
- 影响文件：`scripts/runtime/battle_rules.gd`
- 如何验证：在当前敌人没有对应净化步骤时打出相关净化牌，确认卡牌仍能正常打出并进入弃牌堆，日志会提示没有匹配任务。

## 2026-05-12

### CardView 文字布局改为按卡面素材锚定
- 做了什么：`CardView` 的费用、牌名、图案占位和描述区改为按卡面美术区域锚定，而不是简单纵向排布，使当前卡面素材下的版式更稳定。
- 影响文件：`scenes/ui/card_view.tscn`
- 如何验证：打开 `res://scenes/ui/card_view.tscn` 或进入战斗，确认卡面文字位置与当前素材布局匹配。

### 清理 battle_scene 旧隐藏节点并补上净化区场景预览
- 做了什么：移除了 `battle_scene.tscn` 中已无实际用途的旧隐藏节点，同时给净化任务区补上可见预览结构，方便在不运行脚本时直接查看场景排布。
- 影响文件：`scenes/battle/battle_scene.tscn`、`scripts/ui/battle_scene.gd`
- 如何验证：打开 `res://scenes/battle/battle_scene.tscn`，确认旧占位节点已不存在，净化任务区在场景预览中可直接看到基础结构。
