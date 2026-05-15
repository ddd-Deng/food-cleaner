# 开发日志

### 战斗场景新增玩家胃袋顺序与敌人掉落顺序显示
- 做了什么：把原本右侧单一的 `FoodSlot` 扩展为左右两套顺序面板，左侧新增“玩家胃袋”显示，明确表示玩家胃中待消化食物块的前后顺序；右侧保留“敌人掉落”显示，表示敌人身上还能获取的食物块顺序。两边继续复用现有 `食物槽` 素材作为底槽，但新增 `FoodQueueView` 用文字色块来代替缺失的单独食物图标，并在玩家胃袋里额外显示每块的剩余消化时间与体积。现在当玩家吃入新食物、食物自然消化、被卡牌立即消化、或顺序被前后调换时，胃袋顺序会同步变化；敌人新增或失去食物块时，右侧顺序也会同步刷新。
- 影响文件：`scenes/battle/battle_scene.tscn`、`scripts/ui/battle_scene.gd`、`scripts/ui/food_queue_view.gd`、`devlog.md`
- 如何验证：进入战斗后，确认左侧出现“玩家胃袋”，右侧出现“敌人掉落”，虽然底槽素材相同但标题语义不同；打出吃牌后，右侧最前面的食物块应转移到左侧胃袋末尾；时间推进后，左侧最前面的食物块剩余消化时间应递减并在归零后消失；打出“快速消化”“插队消化”“肠胃翻腾”等会改动胃内顺序或消化状态的牌时，左侧顺序应立即更新；敌人通过行动新增食物块时，右侧列表也应新增对应条目。

### 战斗场景改为独立食物槽叠层
- 做了什么：把战斗场景里的食物槽改成根节点下的独立 `TextureRect` 叠层，不再放进 `MainRow` 的布局里，也删除了原来占位的 `PlayerStatus` 文字 UI 及其刷新代码；食物槽尺寸按原图比例缩到更小一档，避免继续挤压时间轴和底部区域。
- 影响文件：`scenes/battle/battle_scene.tscn`、`scripts/ui/battle_scene.gd`、`devlog.md`
- 如何验证：进入战斗场景后，食物槽应显示在原文字 UI 附近但不参与布局，时间轴应完整可见，底部区域不应再被整体下移或截断。

### 时间轴卡牌标记改用提示框素材承载悬停说明
- 做了什么：把时间轴上的卡牌生效标记预览弹窗改为使用 `sprites/提示框.png` 作为底图，并抽出通用 `show_hint()` 接口，方便后续继续复用同一个提示框承载“卡牌标记说明”“任务机制解释”等内容；同时移除了时间轴标记的原生 tooltip，避免和自定义提示框重复显示。
- 影响文件：`scripts/ui/card_effect_preview_popup.gd`、`scripts/ui/card_effect_timeline_marker.gd`、`devlog.md`
- 如何验证：进入战斗后悬停时间轴卡牌生效标记，应看到使用提示框素材的弹窗，内容包含时间点标题和卡牌列表；移开后弹窗隐藏，且不会再额外弹出系统 tooltip。

### 战斗顶部净化进度条加底板提升可读性
- 做了什么：将战斗顶部的净化任务区从直接压在背景上的裸文字/图标，改为带深色半透明底板的任务条；同时给每个净化步骤增加浅色胶囊底板，未完成与已完成使用不同底色，文字颜色也同步提亮并补了轻微描边，减少在复杂战斗背景下被吃掉的问题。
- 影响文件：`scenes/battle/battle_scene.tscn`、`scripts/ui/battle_scene.gd`、`devlog.md`
- 如何验证：进入战斗后确认顶部净化任务区整体有一层独立深色底板；每个净化步骤各自有浅色小底块，已完成项底色与未完成不同；切换到美术新给的战斗背景下，任务文字和进度图标应明显比之前更容易辨认。

### 新增战斗内卡组阅览覆盖层
- 做了什么：新增 `DeckViewOverlay` 和 `DeckCardTile`，把战斗里的“查看卡组 / 抽牌堆 / 弃牌堆”从日志占位改成真正的整页阅览层。现在会按攻击、技能、净化、其他分组展示卡牌，并合并同名卡显示数量；打开 `查看卡组` 默认看整个卡组，打开抽牌堆/弃牌堆按钮则切到对应页签，支持 `Esc` 和返回按钮关闭。
- 影响文件：`scripts/ui/battle_scene.gd`、`scripts/ui/deck_view_overlay.gd`、`scripts/ui/deck_card_tile.gd`、`scenes/ui/deck_view_overlay.tscn`、`scenes/ui/deck_card_tile.tscn`、`devlog.md`
- 如何验证：进入战斗后点击顶部“查看卡组”应弹出覆盖层；点击抽牌堆和弃牌堆按钮应切到对应页签；覆盖层打开时底层手牌拖拽与战斗按钮不应继续响应；关闭后战斗界面恢复正常交互；打出卡牌后重新打开，抽牌堆/弃牌堆/整个卡组数量应随 `BattleState` 更新。

## 2026-05-13

### 探索主角接入背面待机与走路动画
- 做了什么：重新运行 `tools/resize_player_sprites.py --clean`，将新加入的 `sprites/主角动画/主角待机动画后` 与 `sprites/主角动画/走路动画后` 一并按最近邻采样生成到 `sprites/主角动画_256x144/` 下；同时扩展 `PlayerActor` 的探索朝向逻辑，从原本的“前/侧”改为“前/后/侧”。现在角色在探索地图中向上移动时会播放背面走路动画，松开后如果最后朝向为上，则会停在背面待机动画；左右移动仍沿用右侧动画和左翻转。
- 影响文件：`scripts/explore/player_actor.gd`、`sprites/主角动画_256x144/主角待机动画后/`、`sprites/主角动画_256x144/走路动画后/`、`devlog.md`
- 如何验证：进入探索场景，按住向上移动时确认主角显示背面走路动画，松开后保持背面待机；向下移动和左右移动时，仍分别显示正面/侧面动画；抽查 `sprites/主角动画_256x144/主角待机动画后/` 与 `sprites/主角动画_256x144/走路动画后/` 已生成对应缩小帧图。

### 战斗攻击牌会触发主角攻击动画
- 做了什么：扩展了战斗场景中的 `BattlePlayerSprite`。现在它会在运行时同时加载待机右、`攻击_前`、`攻击_后` 三组动画；当玩家成功打出攻击牌时，会先播放一次 `攻击_前`，再无缝播放一次 `攻击_后`，最后自动回到待机右循环。若玩家连续快速打出攻击牌，新的攻击请求会立刻从 `攻击_前` 重新开始并覆盖当前正在播放的攻击动画。
- 影响文件：`scripts/ui/battle_player_sprite.gd`、`scripts/ui/battle_scene.gd`、`devlog.md`
- 如何验证：进入一场战斗，打出一张攻击牌后确认战斗场景里的主角会连续播放两段攻击动画并回到待机右；连续快速打出多张攻击牌时，确认新的攻击动画会打断前一个并立即重播前半段，而不是排队等待。

### 战斗场景加入可编辑的主角 AnimatedSprite2D 形象
- 做了什么：在 `battle_scene.tscn` 中新增 `BattlePlayerSprite` 节点，作为纯展示用的主角形象，当前默认放在战斗场景中间位置。该节点使用 `AnimatedSprite2D`，并通过 `scripts/ui/battle_player_sprite.gd` 在运行时从 `res://sprites/主角动画_256x144/主角待机动画右` 目录加载待机右动画帧并循环播放；层级放在背景之上、战斗前景光效之下，方便后续直接在场景中拖拽位置和查看动画。
- 影响文件：`scripts/ui/battle_player_sprite.gd`、`scenes/battle/battle_scene.tscn`、`devlog.md`
- 如何验证：打开战斗场景或进入一场战斗，确认场景中央会出现一个持续播放待机右动画的 `AnimatedSprite2D` 主角形象；在编辑器中选中 `BattlePlayerSprite` 后，应能直接拖动位置或调整节点参数。

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

### 战斗场景食物槽移到右侧并修复日志面板收缩
- 做了什么：将战斗场景中的 `FoodSlot` 重新锚定到右侧，避免它继续停留在左边的玩家侧；日志面板保留在中间列内，并改用 `HBoxContainer` 居中对齐，避免之前 `CenterContainer` 把日志区压缩成细长条导致看不到日志内容。
- 影响文件：`scenes/battle/battle_scene.tscn`、`scripts/ui/battle_scene.gd`、`devlog.md`
- 如何验证：进入战斗场景后，食物槽应出现在屏幕右侧；日志区域应恢复为原来的大矩形并能显示战斗开始、抽牌、出牌等日志，同时整体不再向右铺满整个屏幕。
