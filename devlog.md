# 开发日志

## 2026-05-13

### 主角描边 shader 中将所有非零 alpha 视为实心像素
- 做了什么：调整 `player_outline.gdshader` 的 alpha 处理方式。现在主角原图中只要 `a > 0` 的像素，都会在 shader 中被当作 `alpha = 1` 的实心像素；描边采样时也同样按“非零 alpha 即实心”处理，不再保留原图边缘自带的半透明过渡。这样可以直接从 shader 层面消掉原始帧图边缘的半透明像素对主角本体和描边质量的影响。
- 影响文件：`shaders/player_outline.gdshader`、`devlog.md`
- 如何验证：进入探索后观察主角边缘，确认原本因为源图半透明边缘带来的虚边/脏边会明显减少；同时主角本体所有非透明像素区域都会以完全不透明方式显示。

### 重新以最近邻硬边方式生成主角缩小帧图
- 做了什么：重写 `tools/resize_player_sprites.py`，不再调用系统缩放工具，而是使用纯 Python 的 PNG 解码/编码流程对主角动画原图执行最近邻缩放，重新生成 `sprites/主角动画_256x144/` 下的所有缩小帧图。这样缩小时不会再引入平滑插值，边缘会保持更硬的像素风格，更适合后续描边 shader。
- 影响文件：`tools/resize_player_sprites.py`、`sprites/主角动画_256x144/`、`devlog.md`
- 如何验证：重新运行 `python3 tools/resize_player_sprites.py --clean` 后进入探索，对比主角边缘应比上一版更硬朗、不再被缩放平滑；抽查 `sprites/主角动画_256x144/主角待机动画前/Scene1_000.png` 等输出图尺寸仍为 `256x144`。

### 修复主角描边 shader 的 fragment return 报错
- 做了什么：调整 `player_outline.gdshader` 的 `fragment()` 写法。此前在 `canvas_item` shader 的 `fragment` 处理函数里直接使用了 `return` 提前退出，Godot 会报 `Using 'return' in the 'fragment' processor function is incorrect.`；现改为标准的 `if / else` 赋值结构。
- 影响文件：`shaders/player_outline.gdshader`、`devlog.md`
- 如何验证：重新进入探索场景，确认不再出现 `Using 'return' in the 'fragment' processor function is incorrect.`；主角描边仍能正常显示。

### 为探索主角增加可调白色描边 shader
- 做了什么：为探索主角新增 `canvas_item` 描边 shader，并挂到 `PlayerActor` 内部的 `AnimatedSprite2D` 上。当前使用 8 个方向采样来生成外轮廓，默认是白边；同时将描边颜色和描边厚度做成 `PlayerActor` 的导出属性，方便在编辑器中直接调整，而不需要改 shader 文件。
- 影响文件：`shaders/player_outline.gdshader`、`scripts/explore/player_actor.gd`、`devlog.md`
- 如何验证：打开探索场景并选中 `PlayerActor`，调整 `outline_color` 与 `outline_thickness` 后运行项目，确认主角外围会出现一圈描边；把厚度改大后描边会更宽，把颜色改成非白色后描边颜色会同步变化。

### 战斗场景替换背景并增加前景光效层
- 做了什么：为 `battle_scene.tscn` 新增全屏背景与前景贴图层。`res://sprites/map/战斗场景/背景.png` 作为战斗场景最底层背景，`res://sprites/map/战斗场景/光.png` 作为覆盖在战斗场景上的全屏前景层；两张图都按全屏铺满显示。当前前景层放在 `Root` UI 容器之下，因此不会遮挡现有按钮、手牌、日志和 HUD。
- 影响文件：`scenes/battle/battle_scene.tscn`、`devlog.md`
- 如何验证：打开战斗场景或进入一场战斗，确认背景已替换为 `sprites/map/战斗场景/背景.png`，并且 `光.png` 会作为一层整体覆盖显示；确认现有战斗 UI、卡牌、时间轴、按钮和数值文本仍然显示在这两层之上。

### 探索房间背景统一替换为森林地图底图
- 做了什么：将四个探索房间 scene 的背景节点从纯色 `Panel` 统一替换为直接铺满显示 `res://sprites/map/森林地图/背景.png` 的 `TextureRect`。这张背景图本身是 `1280x720`，与当前项目默认窗口尺寸一致，因此当前直接作为房间背景图使用，不额外做裁切拼接逻辑。
- 影响文件：`scenes/rooms/start_room.tscn`、`scenes/rooms/monster_room.tscn`、`scenes/rooms/chest_room.tscn`、`scenes/rooms/boss_room.tscn`、`devlog.md`
- 如何验证：打开四个房间 scene 或进入探索，确认各房间底图都不再是纯色背景，而是统一显示 `sprites/map/森林地图/背景.png`；交互点、主角和房间标题仍显示在背景上方。

### 净化牌在无对应任务时也允许打出
- 做了什么：调整战斗出牌校验逻辑。此前净化牌在出牌前会先检查当前敌人是否存在对应的净化任务，不匹配时直接禁止打出；现在移除了这条前置拦截，因此净化牌即使没有对应任务也可以正常打出、推进时间并进入弃牌堆，只是在效果结算阶段会落到“当前没有匹配的净化任务”，不会产生净化收益。
- 影响文件：`scripts/runtime/battle_rules.gd`、`devlog.md`
- 如何验证：进入战斗后，在当前敌人没有对应净化步骤时打出相关净化牌，确认该牌仍会被打出、消耗对应时间并进入弃牌堆/补牌；日志应提示没有匹配的净化任务，但不会阻止出牌。

### 探索交互切换为真正的 Area2D 检测
- 做了什么：在 `PlayerActor` 上新增交互检测 `Area2D`，并将 `ExploreScene` 的交互判定从“遍历所有交互点做距离扫描”改为“监听玩家交互范围内的 `Area2D` 进入/离开事件”。现在只有进入玩家交互圆形范围的 `ExploreInteractable` 才会进入可交互列表，按 `E` 时再从当前重叠列表中选最近目标；因此交互现在已经是真正基于 `Area2D` 的检测，而不再只是把 `Area2D` 节点当占位。
- 影响文件：`scripts/explore/player_actor.gd`、`scripts/explore/explore_scene.gd`、`devlog.md`
- 如何验证：进入探索后，只有角色走进出口/怪物/宝箱的碰撞范围时，对应交互点才会高亮并显示 `E ...` 提示；走出范围后提示消失；拖动房间 scene 中交互点的位置或调整其 `area_size` 后，交互触发范围会随之变化。

### 修复宝箱状态同步的类型推断报错
- 做了什么：修正 `ExploreScene` 在同步宝箱交互点显示状态时的局部变量声明。此前使用 `var opened := room != null and room.payload.get("opened", false)`，由于 `payload.get()` 返回 `Variant`，GDScript 无法可靠推断 `opened` 的静态类型，导致解析时报错。现改为显式 `bool` 转换。
- 影响文件：`scripts/explore/explore_scene.gd`、`devlog.md`
- 如何验证：重新加载项目，确认不再出现 `Cannot infer the type of "opened" variable because the value doesn't have a set type.`；进入宝箱房后，宝箱未开时显示“补给宝箱”，打开后切换为“已开宝箱”。

### 探索交互物重构为 Node2D + Area2D 并下沉到房间 scene
- 做了什么：将探索中的出口、怪物、宝箱、提示牌从 `Control` UI 占位重构为真正的 `Node2D + Area2D` 交互点，并新增 `scenes/explore/explore_interactable.tscn` 作为可复用场景；四个现有房间模板现在直接实例化自己的交互点，位置、碰撞范围、文案和目标房间都在房间 `.tscn` 里可视化维护，不再由 `ExploreScene` 运行时按锚点动态生成。`ExploreScene` 切换为在加载房间 scene 后收集其中的 `ExploreInteractable` 节点，并根据运行时状态同步怪物房/宝箱房显示文案。
- 影响文件：`scripts/explore/explore_interactable.gd`、`scenes/explore/explore_interactable.tscn`、`scripts/explore/explore_scene.gd`、`scripts/explore/room_scene.gd`、`scenes/rooms/start_room.tscn`、`scenes/rooms/monster_room.tscn`、`scenes/rooms/chest_room.tscn`、`scenes/rooms/boss_room.tscn`、`devlog.md`
- 如何验证：在编辑器中打开四个房间 scene，确认出口/怪物/宝箱/提示牌已经是独立节点而不是 `feature/exit` 锚点；运行项目，确认靠近这些交互点后仍会高亮并响应 `E`，怪物房/Boss 房在清理前仍锁门，宝箱打开后文案会变成“已开宝箱”。

### 探索主角重构为 Node2D + AnimatedSprite2D
- 做了什么：将探索主角从 `Control + TextureRect` 的 UI 节点实现重构为 `Node2D + AnimatedSprite2D`。角色动画现在由 Godot 自带的 `AnimatedSprite2D` 和 `SpriteFrames` 驱动，不再手写帧计时与 UI 贴图切换；仍保留现有“四组目录按文件名排序加载帧图、横向主导用右向动画并在向左时翻转、纵向主导用前向动画、初始待机前”的方向规则。同时调整 `ExploreScene` 的出生点应用逻辑，使其直接把房间锚点中心作为 `Node2D.position`，不再依赖旧 `Control.size` 计算左上角。
- 影响文件：`scripts/explore/player_actor.gd`、`scripts/explore/explore_scene.gd`、`scenes/explore/explore_scene.tscn`、`devlog.md`
- 如何验证：进入探索，确认 `PlayerActor` 节点已改为 `Node2D` 且能正常显示动画；游戏开始时显示待机前，左右移动时播放右向动画并在向左时翻转，上下移动时播放前向动画；主角中心点仍与房间出生锚点对齐，移动边界和交互判定不因节点类型切换而失效。

### 主角动画改为整帧播放并补充批量缩放脚本
- 做了什么：按当前资源组织调整探索主角动画方案，不再对主角动画做透明区域裁切，而是直接把整张帧图作为 sprite 按文件顺序循环播放；同时新增 `tools/resize_player_sprites.py`，用于把 `sprites/主角动画/` 下四组原始 `1280x720` PNG 批量缩放到新的 `sprites/主角动画_256x144/` 目录，当前 `PlayerActor` 默认从这个缩小后的目录读取动画帧。由于这些新生成的 PNG 在首次运行时不一定已经有 Godot 的导入产物，`PlayerActor` 读取帧图时改为直接从源 PNG 文件构建运行时 `ImageTexture`，避免出现 `load(res://...)` 拿不到可显示纹理、导致主角完全不可见的问题。
- 影响文件：`scripts/explore/player_actor.gd`、`tools/resize_player_sprites.py`、`devlog.md`
- 如何验证：先运行 `python3 tools/resize_player_sprites.py --clean` 生成缩小后的动画资源；然后进入探索，确认主角初始显示待机前动画，左右移动时播放右向整帧动画并在向左时翻转，上下移动时播放前向整帧动画，且不再出现因为裁切导致的透明主角。

### 探索主角替换为四向规则动画显示
- 做了什么：将探索中的 `PlayerActor` 从简单自绘方块改为基于 `sprites/主角动画/` 下四组 PNG 序列的贴图动画播放。现在会读取“主角待机动画前 / 主角待机动画右 / 走路动画前 / 走路动画右”四个目录：当横向分量大于纵向分量时使用右向动画，向左移动时对右向动画做水平翻转；当更偏上下移动时使用前向动画且不翻转；停下后沿用最后一次移动得到的朝向状态，初始状态是待机前动画。由于这些源帧本身是 1280x720 的大画布，运行时不会直接拿导入纹理裁切，而是直接读取原始 PNG，先扫描全部动画的非透明区域生成统一裁切框，再把每一帧裁成小图并按固定缩放显示，避免出现整张大画布或裁到透明区导致主角不可见的问题。若资源加载失败，仍回退到原来的方块占位，避免探索直接不可见。
- 影响文件：`scripts/explore/player_actor.gd`、`devlog.md`
- 如何验证：运行项目进入探索，确认游戏开始时主角显示为待机前动画；按 `A/D` 横向移动时播放右行走动画，并在向左时左右翻转；按 `W/S` 或纵向分量更大时播放前行走动画；松开按键后切回与最后朝向一致的待机动画。

### 修正首次进入探索时房间边界过早计算
- 做了什么：调整 `ExploreScene` 在房间刷新后的玩家定位时机。此前首次进入探索时，`_refresh_view()` 只在房间重建后 `call_deferred()` 一次 `_reset_player_position()`；如果这时 `RoomCanvas` 仍在容器布局过程中，玩家可移动边界就会按一个尚未稳定的尺寸计算，表现为入口前厅下半部分像有空气墙，但切换一次房间后又恢复正常。现在改为在房间刷新后标记待同步，并监听 `RoomCanvas.resized`，总是等到最新一次布局后的下一帧再应用出生点和移动边界。
- 影响文件：`scripts/explore/explore_scene.gd`、`devlog.md`
- 如何验证：重新启动项目后直接进入入口前厅，确认首次进入时也能走到房间下半区域；再切换到其他房间并返回，入口前厅的可行走范围应保持一致，不再只有首次进入时异常。

### 修正探索房间可见区域与可行走区域错位
- 做了什么：为 `explore_scene.tscn` 的 `RoomCanvas` 开启 `clip_contents`。此前 room scene 模板会按完整场景尺寸绘制内容，但 `PlayerActor` 的可活动范围实际只按 `RoomCanvas` 尺寸夹取；在未裁剪内容时，房间下半部可能仍然可见，导致看起来像“下面还有地图，但角色被空气墙挡住”。开启裁剪后，可见区域会和实际移动边界保持一致。
- 影响文件：`scenes/explore/explore_scene.tscn`、`devlog.md`
- 如何验证：重新进入探索场景，确认入口前厅中不再出现“下半部分地图可见但角色无法走过去”的错觉；角色可见范围应与实际可行走区域一致，移动到房间下边缘时会明确停在可见房间底边附近。

### 修复 room scene 出口锚点参数类型错误
- 做了什么：修正 `ExploreRoomScene.get_exit_anchor_positions()` 的参数类型定义。此前它要求调用方传入 `Array[Vector2]`，但 `ExploreScene` 传入的默认出口常量在运行时会被视为普通 `Array`，导致 Godot 在进入探索场景时直接报 typed array 参数不匹配。现在改为接受普通 `Array`，并在函数内部筛出 `Vector2` 转成返回用的 `Array[Vector2]`。
- 影响文件：`scripts/explore/room_scene.gd`、`devlog.md`
- 如何验证：重新启动项目并进入探索，确认不再出现 `The array of argument 1 (Array) does not have the same element type as the expected typed array argument`；各房间出口仍按 room scene 中的 `exit` 锚点位置生成。

### 探索房间改为独立 room scene 模板
- 做了什么：将探索层原本由 `ExploreScene` 直接按房间类型生成背景色和固定坐标交互物的做法，改为“运行时房间数据 + 独立房间 `.tscn` 模板”结构；为 `RoomRuntimeData` 增加 `scene_path`，新增 `ExploreRoomScene` 与 `RoomAnchor` 脚本，用于在房间模板里可视化标记功能物、出口和玩家出生点；把当前已有的 `start`、`monster_room`、`chest_room`、`boss_room` 四个房间分别拆到 `scenes/rooms/` 下独立场景中，并让 `ExploreScene` 运行时按模板加载房间，再根据模板锚点放置交互物和出口。
- 影响文件：`scripts/map/room_runtime_data.gd`、`scripts/map/map_generator.gd`、`scripts/explore/explore_scene.gd`、`scripts/explore/room_scene.gd`、`scripts/explore/room_anchor.gd`、`scenes/rooms/start_room.tscn`、`scenes/rooms/monster_room.tscn`、`scenes/rooms/chest_room.tscn`、`scenes/rooms/boss_room.tscn`、`devlog.md`
- 如何验证：当前环境未安装 Godot，无法执行 headless 场景加载。请在编辑器中分别打开 `res://scenes/rooms/start_room.tscn`、`monster_room.tscn`、`chest_room.tscn`、`boss_room.tscn`，确认能直接可视化编辑房间内容，并能看到 `feature/exit/player_spawn` 锚点；再运行项目，确认进入不同房间时会加载对应模板，玩家出生点、房间中央功能物和出口位置以各房间 scene 中的锚点为准，怪物房/Boss 房仍会阻止未清理前离开，宝箱房仍能正常给金币并返回探索。

## 2026-05-12

### 调整 CardView 卡面文字锚定布局
- 做了什么：将 `CardView` 的文字覆盖层从纵向 `VBoxContainer` 排布改为按卡面美术区域锚定，费用贴近左上角时钟区域，卡牌名落在顶部纸条中间，图案占位居中在椭圆图片区，描述移动到下方云朵上方的左侧阅读区。
- 影响文件：`scenes/ui/card_view.tscn`、`devlog.md`
- 如何验证：已运行 `D:\Godot\Godot_v4.6.2-stable_win64.exe --headless --path . --scene res://scenes/ui/card_view.tscn --quit`，场景可正常加载；需要在编辑器中打开 `res://scenes/ui/card_view.tscn` 或进入战斗确认文字位置与当前卡面素材匹配。

> 已按阶段精简历史记录，只保留当前仍有参考价值的结果、影响文件和验证方式。后续新增记录默认使用中文。

## 2026-05-12

### 清理 battle_scene 旧隐藏节点
- 做了什么：从 `scenes/battle/battle_scene.tscn` 中移除旧的隐藏 UI 节点 `DeckInfo`、`CapacityValue` 与 `EnemySummary`；脚本中已确认没有这三个节点名的直接引用，因此未修改 GDScript。
- 影响文件：`scenes/battle/battle_scene.tscn`、`devlog.md`
- 如何验证：全局搜索 `DeckInfo|CapacityValue|EnemySummary`，确认 `scenes/` 与 `scripts/` 中不再存在这些节点名；使用 `D:\Godot\Godot_v4.6.2-stable_win64.exe --headless --path . --quit` 加载项目后再次搜索，确认 Godot 没有把节点写回。

### 战斗净化进度 UI 场景预览补充
- 做了什么：为 `battle_scene.tscn` 的 `PurificationTaskRow` 增加可见预览节点，打开场景时无需运行脚本也能看到右上角“名字 + 方块”的净化进度 UI；运行时仍会由 `BattleScene` 根据真实战斗状态清空预览并重新生成任务项。
- 影响文件：`scenes/battle/battle_scene.tscn`、`scripts/ui/battle_scene.gd`、`devlog.md`
- 如何验证：打开 `res://scenes/battle/battle_scene.tscn`，确认顶部右侧可直接看到净化任务预览；进入战斗后确认预览会被真实任务状态替换。

### 手牌卡牌背景素材替换
- 做了什么：将 `CardView` 从纯 `PanelContainer + StyleBoxFlat` 配色卡面改为“底图素材 + 现有文字覆盖层”的结构；把 `sprites/攻击卡.png`、`sprites/技能卡.png`、`sprites/净化卡.png` 原始 1024x750 画布中的有效卡面区域裁成 `sprites/card_backgrounds/attack_card.png`、`sprites/card_backgrounds/skill_card.png`、`sprites/card_backgrounds/purify_card.png` 三张 336x448 的独立背景图，再由 `CardView` 直接贴图显示，避免运行时 `AtlasTexture` 裁切/缩放导致卡面被放大截断；保留了现有费用、名称、图案占位字和描述节点，以及拖拽、悬停、可出牌高亮等交互逻辑，只把状态反馈改为独立描边层，避免现在就把后续数字、图案和标题替换方案写死。
- 影响文件：`scenes/ui/card_view.tscn`、`scripts/ui/card_view.gd`、`sprites/card_backgrounds/attack_card.png`、`sprites/card_backgrounds/skill_card.png`、`sprites/card_backgrounds/purify_card.png`、`devlog.md`
- 如何验证：打开 `res://scenes/ui/card_view.tscn` 或进入一场战斗，确认攻击/技能/净化牌分别显示对应底图而不是纯色面板；确认卡牌上的费用、名称、中央图案占位字和描述仍然可见；确认手牌悬停抬升、拖拽、可出牌高亮和打出后补牌行为没有因为 `CardView` 结构调整而失效。

### 战斗右上角净化进度 UI 替换
- 做了什么：将战斗顶部原本整行文字形式的净化进度条，改为右上角横向任务行；每个净化步骤改为“步骤名 + 方块状态”显示，未完成使用空方块，完成后切换为打勾方块，直接复用 `sprites/净化进度、.png` 里的现有素材切片。
- 影响文件：`scenes/battle/battle_scene.tscn`、`scripts/ui/battle_scene.gd`、`devlog.md`
- 如何验证：打开 `res://scenes/battle/battle_scene.tscn` 或进入一场战斗，确认净化进度不再显示在左上角整行文本区域，而是显示在顶部右侧；每个任务以“名字 方块”的顺序横向排列，完成净化步骤后对应方块会切换成打勾图标，并保留原有的高亮反馈。

## 2026-05-11

### 战斗角色区文字回收与边距调整
- 做了什么：将 `BattleActorView` 改为只显示玩家/敌人图案，不再在图案区域直接绘制 HP、防御、胃容量、意图等文字；把玩家与敌人的文字状态信息继续收回上半区左右两列；暂时隐藏角色下方的道具、金币和食物块摘要区域，为后续单独设计胃内食物块 UI 留出空间。
- 做了什么：同步增大 `battle_scene.tscn` 的左右外边距、上下半区左右列宽和主要横向间距，减少文字贴边与被屏幕截断的问题，并让图案区域相对更居中。
- 影响文件：`scripts/ui/battle_actor_view.gd`、`scripts/ui/battle_scene.gd`、`scenes/battle/battle_scene.tscn`、`devlog.md`
- 如何验证：打开 `res://scenes/battle/battle_scene.tscn` 或进入一场战斗，确认左上/右上文字信息恢复为主要状态展示，左右角色图案区域不再叠加文字，下方不再显示当前这版金币/道具/食物块摘要，且左右两侧文字不会再紧贴屏幕边缘。

### 战斗界面节点路径热修复
- 做了什么：修正 `scripts/ui/battle_scene.gd` 中玩家道具行与金币标签的 `@onready` 路径，使其和当前 `ItemGoldRow` 场景层级一致，避免 `_refresh_player_items()` 对空节点调用 `get_children()`。
- 影响文件：`scripts/ui/battle_scene.gd`、`devlog.md`
- 如何验证：重新进入一场战斗，确认不再出现 `Cannot call method 'get_children' on a null value`，并检查左下区域的道具占位与金币文本是否正常刷新。

### 战斗上半区布局重构
- 将战斗场景上半区从“左右信息面板 + 中央大净化任务面板”改为“左侧玩家占位、右侧敌人占位、顶部紧凑任务条、中央大日志区”的结构，更接近正式战斗画面的阅读方式。
- 新增自绘 `BattleActorView`，分别用于玩家和敌人的极简符号占位，不再用普通 `PanelContainer` 充当角色主体展示。
- 左右区域保留关键摘要信息：玩家侧显示金币、道具和胃队列摘要，敌人侧显示食物块摘要；顶部任务条单行汇总当前步骤、净化进度、任务勾选和敌人意图。
- 影响文件：`scripts/ui/battle_actor_view.gd`、`scripts/ui/battle_scene.gd`、`scenes/battle/battle_scene.tscn`。
- 验证：当前环境无法运行 Godot。请打开 `res://scenes/battle/battle_scene.tscn`，确认左侧玩家占位、右侧敌人占位和顶部单行任务条已经出现，中央日志区比之前更大；进入一场战斗后确认 HP、防御、胃容量、净化进度、敌人意图和食物块数量都会同步刷新，且底部手牌拖拽、右键取消、出牌补牌与时间轴显示不受影响。

### 探索主循环与战斗回传
- 项目主入口改为房间式探索场景，不再启动后直接进入战斗。
- 新增最小可运行的 run/map 流程，包含房间生成、移动与交互、宝箱奖励、Boss 结算，以及探索与战斗之间的往返切换。
- 战斗启动改为支持从探索流程注入初始生命、牌组、道具与金币，并在战斗结束后把结果回传给探索界面。
- 影响文件：`project.godot`、`scenes/main/main.gd`、`scenes/explore/explore_scene.tscn`、`scripts/explore/explore_scene.gd`、`scripts/explore/player_actor.gd`、`scripts/explore/explore_interactable.gd`、`scripts/run/run_controller.gd`、`scripts/run/run_factory.gd`、`scripts/run/run_state.gd`、`scripts/run/battle_definition_builder.gd`、`scripts/map/map_generator.gd`、`scripts/map/map_types.gd`、`scripts/map/room_runtime_data.gd`、`scripts/data/battle_definition.gd`、`scripts/runtime/battle_rules.gd`、`scripts/ui/battle_scene.gd`、`scripts/content/sample_battle_factory.gd`。
- 验证：当前环境无法运行 Godot。请启动主场景，确认游戏先进入探索；使用 `WASD` 移动、`E` 交互；进入怪物房完成战斗后确认生命值与金币正确回传；打开宝箱房确认奖励只发一次；击败或败给 Boss 后确认会出现重新开始覆盖层。

### 战斗手牌交互定型
- 手牌 UI 从旧的滚动列表改为扇形排布的 `HandView`，卡牌支持直接拖拽、悬停抬升、右键取消，并以“松手位置是否离开手牌区”为主要出牌判定。
- 交互逻辑多轮收敛后，当前重点结果是：拖拽时不再出现幽灵预览、重叠卡牌悬停更稳定、松手出牌判定更符合直觉、连锁抽弃牌后手牌顺序与显示一致。
- 同步支持最多 8 张手牌，并按数量自动缩放，尽量保证扇形布局仍居中且不遮挡时间轴。
- 影响文件：`scripts/ui/hand_view.gd`、`scripts/ui/card_view.gd`、`scripts/ui/battle_scene.gd`、`scenes/battle/battle_scene.tscn`、`scripts/runtime/battle_state.gd`、`scripts/data/battle_definition.gd`、`scripts/content/sample_battle_factory.gd`。
- 验证：当前环境无法运行 Godot。请在战斗场景中测试悬停、拖拽、右键取消、在手牌区内外松手、以及连续出牌后补牌的情况，确认没有错位、误出牌、卡牌消失或顺序错乱的问题；再测试 8 张手牌时的缩放和排布是否正常。

### 卡面与战斗 HUD 可读性调整
- 卡面布局改为更偏横向、矮一些的比例，标题移到费用同行，图片和描述区域重新分配空间，描述文字字号也单独调大，优先提升战斗中读牌效率。
- `CardView` 不再在脚本里强行覆盖子节点尺寸，卡面尺寸和局部排版以 `card_view.tscn` 为主，后续微调会更直接。
- 战斗 HUD 新增金币显示，使战斗界面中的金币数与探索 HUD 保持一致。
- 顺手清理了部分 Godot 脚本警告，例如参数遮蔽和未使用参数/信号。
- 影响文件：`scenes/ui/card_view.tscn`、`scripts/ui/card_view.gd`、`scenes/battle/battle_scene.tscn`、`scripts/ui/battle_scene.gd`、`scripts/runtime/battle_state.gd`、`scripts/runtime/battle_rules.gd`、`scripts/run/battle_definition_builder.gd`、`scripts/data/battle_definition.gd`、`scripts/ui/hand_view.gd`。
- 验证：当前环境无法运行 Godot。请打开 `res://scenes/battle/battle_scene.tscn`，确认卡牌标题与费用同处顶行、描述文字更易读、图片与描述区域没有重叠；从探索获取金币后进入战斗，确认战斗界面金币数一致；重新载入脚本后确认相关 warning 不再出现。

## 2026-05-10

### 战斗基础框架落地
- 建立了当前战斗原型的基础结构，包括共享类型、数据资源、运行时状态、规则执行器、示例内容工厂和最小可运行战斗场景。
- 战斗整体展示改为时间轴布局，围绕玩家、敌人、净化任务、牌堆/弃牌堆、手牌和日志组织界面。
- 同步整理了 1280x720 下的首轮布局，并把现有战斗文案、日志和示例名称切到中文。
- 影响文件：`scripts/core/battle_types.gd`、`scripts/data/card_data.gd`、`scripts/data/enemy_action_data.gd`、`scripts/runtime/card_instance.gd`、`scripts/runtime/battle_state.gd`、`scripts/runtime/battle_rules.gd`、`scripts/content/sample_battle_factory.gd`、`scripts/ui/battle_scene.gd`、`scripts/ui/play_drop_zone.gd`、`scenes/battle/battle_scene.tscn`、`project.godot`。
- 验证：当前环境无法运行 Godot。请打开 `res://scenes/battle/battle_scene.tscn`，确认界面结构、中文文案和基础布局正常显示，并检查窗口缩放时主区域和底部区域是否仍按比例扩展。

### 规则模型与数据驱动增强
- 战斗规则向当前设计文档靠拢：玩家拥有防御，食物块带消化时间，净化任务允许无序完成，敌人行动按循环时间轴推进。
- 时间推进改为逐时间单位结算，先处理胃队列前排消化，再处理该时刻敌人行动，最后结算出牌效果。
- 增加出牌前校验，避免容量不足、任务不匹配等非法出牌直接消耗手牌。
- 卡牌效果不再依赖描述文本解析，改为 `cards.csv` 提供基础元数据，由 `scripts/content/card_catalog.gd` 映射具体效果。
- 影响文件：`scripts/data/food_block_data.gd`、`scripts/data/battle_definition.gd`、`scripts/runtime/food_block_instance.gd`、`scripts/runtime/enemy_runtime.gd`、`scripts/runtime/battle_rules.gd`、`scripts/runtime/battle_state.gd`、`scripts/content/card_catalog.gd`、`scripts/content/sample_battle_factory.gd`、`scripts/ui/card_view.gd`。
- 验证：当前环境无法运行 Godot。请在战斗中测试胃容量限制、防御抵伤、食物逐时消化、敌人按时间轴重复行动、净化任务乱序完成，以及不同卡牌效果是否按名称正确结算。

### 战斗界面信息补全
- 从临时按钮演进到独立 `CardView` 与 `PlayDropZone`，并加入基础反馈效果，战斗过程中的信息提示更完整。
- HUD 补充了防御、胃容量、胃队列剩余时间、净化任务状态、牌库预览、生命文字覆盖层、滚动日志等关键可视信息。
- 牌堆/弃牌堆与时间行也做了多轮压缩，当前目标是让底部区域更聚焦手牌与时间轴。
- 影响文件：`scripts/ui/card_view.gd`、`scripts/ui/play_drop_zone.gd`、`scripts/ui/battle_scene.gd`、`scenes/ui/card_view.tscn`、`scenes/battle/battle_scene.tscn`。
- 验证：当前环境无法运行 Godot。请打开战斗场景，确认卡牌可拖拽到投放区、取消时不会改状态；确认生命、防御、胃队列、净化任务、牌库预览和日志都能随战斗变化更新；确认时间行显示为单行且角落牌堆控件保持紧凑。
# 2026-05-12 补充记录

### 清理 `BattleActorView` 参数遮蔽 warning
- 做了什么：将 `scripts/ui/battle_actor_view.gd` 中 `set_enemy_snapshot()` 的参数 `name` 改为 `enemy_name`，避免遮蔽 `Node` 基类已有属性 `name`，消除脚本 reload 时的 `SHADOWED_VARIABLE_BASE_CLASS` warning。
- 影响文件：`scripts/ui/battle_actor_view.gd`、`devlog.md`
- 如何验证：重新加载 `res://scripts/ui/battle_actor_view.gd` 或启动项目，确认不再出现 `The local function parameter "name" is shadowing an already-declared property in the base class "Node"`。

### 战斗右上角按钮素材替换
- 做了什么：将战斗界面右上角的设置与查看卡组从文字 `Button` 改为 `TextureButton`，使用 `sprites/按钮/设置.png` 与 `sprites/按钮/查看卡组.png` 的有效区域 `AtlasTexture`，并在脚本中保留原有 `pressed` 行为，同时补充 hover/pressed 的缩放与明暗反馈。
- 影响文件：`scenes/battle/battle_scene.tscn`、`scripts/ui/battle_scene.gd`、`devlog.md`
- 如何验证：打开 `res://scenes/battle/battle_scene.tscn` 或进入战斗，确认右上角显示设置齿轮与查看卡组图标；鼠标悬停、按下、松开有反馈；点击设置仍向日志写入设置占位提示，点击查看卡组仍展开牌库预览。

### 战斗抽牌堆与弃牌堆按钮素材替换
- 做了什么：将底部左右两侧原本显示为文字面板的抽牌堆与弃牌堆区域改为 `TextureButton`，分别使用 `sprites/抽牌堆.png` 与 `sprites/弃牌堆.png` 的有效区域 `AtlasTexture`；保留数量标签作为覆盖层，并暂时只在点击时向日志输出按钮点击结果，不接入完整牌堆查看功能。
- 影响文件：`scenes/battle/battle_scene.tscn`、`scripts/ui/battle_scene.gd`、`devlog.md`
- 如何验证：打开 `res://scenes/battle/battle_scene.tscn` 或进入战斗，确认底部左侧显示抽牌堆素材、右侧显示弃牌堆素材；鼠标悬停和按下有反馈；点击后日志分别追加“抽牌堆按钮点击。”和“弃牌堆按钮点击。”。
## 2026-05-12 琛ュ厖璁板綍 2

### 鎴樻枟澶撮儴琛€鏉?UI 绱犳潗鏇挎崲
- 鍋氫簡浠€涔堬細灏嗘垬鏂楀満鏅ご閮ㄧ殑 `PlayerHpBar` 浠庨粯璁?`ProgressBar` 鏀逛负 `TextureProgressBar`锛屾帴鍏?`sprites/血条/血条底槽.png` 鍜?`sprites/血条/血条.png` 鐨勬湁鏁堝尯鍩?`AtlasTexture`锛屼繚鐣欏師鏈?HP 鏂囨湰瑕嗙洊灞傚拰鐜版湁鐢熷懡鍊煎埛鏂伴€昏緫銆?
- 褰卞搷鏂囦欢锛歚scenes/battle/battle_scene.tscn`銆乣scripts/ui/battle_scene.gd`銆乣devlog.md`
- 濡備綍楠岃瘉锛氭墦寮€ `res://scenes/battle/battle_scene.tscn` 鎴栬繘鍏ユ垬鏂楋紝纭澶撮儴鐢熷懡鏉℃樉绀轰负绾㈣壊濉厖 + 娣辨牳搴曟Ы绱犳潗锛汬P 鏂囨湰浠嶅眳涓彔鍦ㄨ鏉′笂锛涚帺瀹剁敓鍛藉€煎彉鍖栨椂濉厖闀垮害浼氶殢涔嬪埛鏂帮紝涓嶅啀鏄剧ず榛樿绯荤粺椋庢牸杩涘害鏉°€?
### 战斗滚动条素材接入与复用接口
- 做了什么：新增 `ScrollBarSkin` 通用滚动条皮肤脚本，统一封装滚动条轨道与滚轮素材的主题覆盖；当前先接入战斗场景日志滚动区 `LogScroll`，后续其他 UI 只要拿到 `ScrollContainer` 或独立 `ScrollBar` 也能复用同一套滚动条皮肤。
- 影响文件：`scripts/ui/scroll_bar_skin.gd`、`scripts/ui/battle_scene.gd`、`devlog.md`
- 如何验证：打开 `res://scenes/battle/battle_scene.tscn` 或进入战斗，确认日志区右侧滚动条不再使用 Godot 默认样式，而是显示美术提供的细条轨道和滚轮；滚动、拖拽滚轮后内容仍能正常滚动。

### 战斗时间轴素材替换
- 做了什么：将战斗底部时间轴从一排纯文本 `Label` 改为基于 `sprites/时间轴/时间轴.png`、`sprites/时间轴/时间轴上的标记点.png` 和 `sprites/时间轴/当前回合标记.png` 的素材化展示；保留每个时间点的文字标签，同时用当前回合标记固定指向起点、用不同标记点区分普通时间点与敌人行动时间点。
- 影响文件：`scenes/battle/battle_scene.tscn`、`scripts/ui/battle_scene.gd`、`devlog.md`
- 如何验证：打开 `res://scenes/battle/battle_scene.tscn` 或进入战斗，确认底部时间轴显示为一条横向箭头底图；左侧有当前回合标记；后续时间点显示小标记，且敌人行动所在时刻的标记与普通时刻不同；时间文字仍会随战斗推进刷新。

### 战斗时间轴窗口与敌人行动标记修正
- 做了什么：将时间轴窗口改为显示“当前时间前 2 格 + 当前时间 + 后续时间”，让当前回合标记落在中间偏左位置而不是整条时间轴最左端；同时改为所有时间节点都显示基础节点标记，而敌人行动时刻额外叠加三角标记，包含当前回合之前两格内已发生或即将显示的敌人行动。
- 影响文件：`scripts/runtime/enemy_runtime.gd`、`scripts/runtime/battle_rules.gd`、`scripts/ui/battle_scene.gd`、`devlog.md`
- 如何验证：进入战斗后确认底部时间轴最左侧不再直接从当前回合开始，而是会多显示前 2 个时间点；每个时间点都有基础节点标记；只要该时间点存在敌人行动，无论在当前回合前后都会额外显示三角标记，并保留对应行动文字。

### 战斗时间轴普通节点三角误用修正
- 做了什么：确认 `sprites/时间轴/时间轴上的标记点.png` 里拆出的两个可用切片都是三角形，而不是“圆点 + 三角”的组合；因此移除了“每个时间节点都绘制基础切片”的逻辑，改为只有敌人行动时间点才显示三角标记，普通时间节点只保留时间文字。
- 影响文件：`scripts/ui/battle_scene.gd`、`devlog.md`
- 如何验证：进入战斗后确认普通时间节点不再出现三角；只有存在敌人行动的时间点才会显示三角标记。

### 战斗时间轴默认可视范围收窄
- 做了什么：缩短时间轴默认预览窗口长度，在保留“当前时间前 2 格”的前提下减少后续可见时间点数量，尽量让默认状态下不拖动滚动条也能直接看到时间轴底图最右端的箭头。
- 影响文件：`scripts/runtime/battle_rules.gd`、`devlog.md`
- 如何验证：进入战斗后确认时间轴默认显示更短，右端箭头在多数情况下无需拖动滚动条即可直接看到。

### 战斗时间轴可见尺寸微调
- 做了什么：进一步轻微压低时间轴区域高度，并同步缩小时间轴文字字号、标签高度与上下偏移，减少时间轴对手牌上缘的遮挡，同时保留当前可见时间点数量和右端箭头可见性。
- 影响文件：`scenes/battle/battle_scene.tscn`、`scripts/ui/battle_scene.gd`、`devlog.md`
- 如何验证：进入战斗后确认时间轴整体比上一版更矮，时间文字略小一些，对手牌遮挡更少；同时右端箭头仍能在默认状态下直接看到。

### 战斗时间轴时间文字下移
- 做了什么：将 `0t`、`1t` 等时间轴文字标签整体进一步下移，减少它们对手牌上缘的遮挡；不改时间轴窗口长度、箭头可见性和敌人行动三角逻辑。
- 影响文件：`scripts/ui/battle_scene.gd`、`devlog.md`
- 如何验证：进入战斗后确认时间轴文字整体比上一版更靠下，与手牌上沿的重叠更少。

### 修正滚动条主题未生效的问题
- 做了什么：调整 `ScrollBarSkin` 的滚动条素材应用方式，竖向轨道与滚轮改为直接使用 `AtlasTexture` 区域，横向版本改为先裁切再显式旋转，避免之前运行时裁图/旋转逻辑不稳定导致主题仍回退到默认样式；同时改用 `scroll_size` 统一控制滚动条厚度，去掉对滚动条 padding 常量的依赖。
- 影响文件：`scripts/ui/scroll_bar_skin.gd`、`devlog.md`
- 如何验证：打开 `res://scenes/battle/battle_scene.tscn` 或进入战斗，确认 `LogScroll` 右侧显示的是素材里的细长轨道和绿色滚轮，而不是 Godot 默认滚动条；如果后续把这套皮肤接到横向滚动条，也应能正常显示横向旋转后的版本。

### 修正日志文本内部滚动条皮肤
- 做了什么：确认日志区实际显示的默认滚动条来自 `RichTextLabel` 自带的内部 `VScrollBar`，不是外层 `ScrollContainer` 的滚动条；为 `ScrollBarSkin` 增加 `apply_to_rich_text_label()`，并在战斗场景中同时应用到 `LogText.get_v_scroll_bar()`，时间轴 `TimelineScroll` 也接入同一套皮肤。
- 影响文件：`scripts/ui/scroll_bar_skin.gd`、`scripts/ui/battle_scene.gd`、`devlog.md`
- 如何验证：打开 `res://scenes/battle/battle_scene.tscn` 或进入战斗，确认日志文本右侧滚动条不再是 Godot 默认深灰轨道/灰色滑块，而是使用 `sprites/滚动条/滚动条的条.png` 与 `sprites/滚动条/滚动条的滚轮.png` 中的轨道和滚轮。

### 调整时间轴横向滚动条尺寸
- 做了什么：为 `ScrollBarSkin` 增加紧凑横向滚动条入口，专门用于时间轴；将时间轴滚动条高度收窄并缩小与时间轴内容之间的间隔，同时略微降低 `TimelineScroll`/`TimelineStrip` 的最小高度，避免时间轴被滚动条顶高后挡住手牌。
- 影响文件：`scripts/ui/scroll_bar_skin.gd`、`scripts/ui/battle_scene.gd`、`scenes/battle/battle_scene.tscn`、`devlog.md`
- 如何验证：打开 `res://scenes/battle/battle_scene.tscn` 或进入战斗，确认时间轴底部仍有素材风格横向滚动条，但高度更薄、与时间轴更贴近，手牌不再被时间轴区域遮挡。
### 战斗顶部按钮位置对调
- 做了什么：在 `scripts/ui/battle_scene.gd` 的 `_ready()` 中调整 `HeaderRow/RightButtons` 下子节点顺序，让“预览牌堆/卡组”按钮显示到“设置”左侧，同时保留两个按钮原有贴图、节点名和点击逻辑。
- 影响文件：`scripts/ui/battle_scene.gd`、`devlog.md`
- 如何验证：打开 `res://scenes/battle/battle_scene.tscn` 或进入战斗，确认右上角“预览牌堆/卡组”和“设置”按钮的位置已互换；点击“设置”仍写入设置占位日志，点击“预览牌堆/卡组”仍输出牌库预览内容。

### 战斗左上角头像框/血条/金币槽 HUD 调整
- 做了什么：将战斗界面顶部左侧的单独血条改成更贴近素材示意图的组合 HUD，新增头像框、横向血条和下方金币槽，并用 `AtlasTexture` 精确裁切 `sprites/头像框.png`、`sprites/血条/血条底槽.png`、`sprites/血条/血条.png`、`sprites/金币槽.png` 左上角的有效区域；同时把战斗内金币数接到新的金币槽文案上。
- 影响文件：`scenes/battle/battle_scene.tscn`、`scripts/ui/battle_scene.gd`、`devlog.md`
- 如何验证：打开 `res://scenes/battle/battle_scene.tscn` 或进入战斗，确认左上角显示为“头像框在左、血条在右上、金币槽在右下”的排列，整体相对位置接近素材示意图；确认血量变化时红色血条仍正常缩放，战斗初始金币与探索带入的金币会显示在金币槽内，且不会影响右上角按钮、顶部任务条和底部手牌/时间轴布局。

### 时间轴滚动条改为随历史累计而缩短
- 做了什么：将时间轴预览数据改为从 `0t` 一直累计到“当前时间 + 少量前瞻格”，不再只生成当前附近的固定窗口；同时在界面刷新时自动把横向滚动位置对齐到“当前时间前 2 格”附近，保留原本的阅读重心，但让更早历史可以通过拖动滚动条回看。
- 影响文件：`scripts/runtime/battle_rules.gd`、`scripts/ui/battle_scene.gd`、`devlog.md`
- 如何验证：进入战斗后连续打出多张带时间消耗的牌，确认时间轴左侧可以回看到 `0t` 开始的内容；随着 `battle_time` 增长，底部横向滚动条滑块会逐渐变短；默认视角仍停在当前时间附近，且不会再显示“当前时间之前固定只有 2 格、之后固定只有一小段”的假窗口感。

### 清理 battle_scene 冗余状态节点
- 做了什么：删除 `battle_scene` 中长期隐藏未使用的 `EnemySummary` 与 `CapacityValue` 节点，并同步移除 `scripts/ui/battle_scene.gd` 里对应的节点引用和刷新代码；同时精简 `PlayerStatus`，去掉其中重复显示的 `HP` 文案，只保留玩家名、护盾与胃容量摘要。
- 影响文件：`scenes/battle/battle_scene.tscn`、`scripts/ui/battle_scene.gd`、`devlog.md`
- 如何验证：打开 `res://scenes/battle/battle_scene.tscn`，确认场景树中不再存在 `EnemySummary` 与 `CapacityValue`；进入战斗后确认左侧 `PlayerStatus` 不再显示 `HP` 行，但左上角独立血条仍正常刷新，抽牌堆与弃牌堆数量显示不受影响。
### 修复 `battle_scene.tscn` 未闭合字符串导致的解析错误
- 做了什么：修复 `battle_scene.tscn` 中多处 UI 预览文本/tooltip 的未闭合字符串，包括净化任务预览名、效果提示文案、抽牌堆与弃牌堆 tooltip；这些字段会让 Godot 在解析场景文件时直接失败。
- 影响文件：`scenes/battle/battle_scene.tscn`、`devlog.md`
- 如何验证：已运行 `D:\Godot\Godot_v4.6.2-stable_win64.exe --headless --path . --quit` 和 `D:\Godot\Godot_v4.6.2-stable_win64.exe --headless --path . --scene res://scenes/battle/battle_scene.tscn --quit`，均正常退出。

### 修复战斗场景乱码文案与资源路径
- 做了什么：将 `battle_scene.tscn` 中被 mojibake 化的静态 UI 文案改回正常中文，包括牌库/设置 tooltip、玩家/敌人状态预览、战斗时间、日志、抽牌堆与弃牌堆文本；同时把场景内写坏的 `sprites/` 中文资源路径改回磁盘上的真实中文路径，避免图标和 HUD 素材加载失败。同步修复 `BattleActorView` 默认敌人名与待机意图的乱码。
- 影响文件：`scenes/battle/battle_scene.tscn`、`scripts/ui/battle_actor_view.gd`、`devlog.md`
- 如何验证：已全局扫描常见 mojibake 残留，未在 `scenes/`、`scripts/`、`data/`、`project.godot` 的 Godot 文本文件中发现同类残留；已运行 `D:\Godot\Godot_v4.6.2-stable_win64.exe --headless --path . --scene res://scenes/battle/battle_scene.tscn --quit` 和 `D:\Godot\Godot_v4.6.2-stable_win64.exe --headless --path . --quit`，均正常退出。

### 修复 `battle_scene.tscn` 文件头 BOM 导致的解析错误
- 做了什么：移除 `scenes/battle/battle_scene.tscn` 文件开头的 UTF-8 BOM；Godot 文本场景解析器会把 BOM 当作第 1 行第 1 个字符，导致即使文本显示为 `[gd_scene ...]`，仍报 `Expected '['`。
- 影响文件：`scenes/battle/battle_scene.tscn`、`devlog.md`
- 如何验证：检查文件开头字节应直接从 `5B`（`[`）开始；再用 Godot 命令行加载 `res://scenes/battle/battle_scene.tscn`，确认不再出现 `Parse Error: Expected '['`。
