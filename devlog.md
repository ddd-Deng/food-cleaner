# 开发日志

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
