# 开发日志

### 实现敌人让前排好食物块变质的 `CORRUPT_BLOCK`
- 做了什么：补全了敌方动作 `CORRUPT_BLOCK` 的真实战斗逻辑，不再只是日志占位。现在敌人触发该动作时，会从自己的食物队列前往后扫描，把前 `2` 个当前仍可视为“好”的食物块变成“变质”状态；本轮先采用可演进的运行时规则：已经自带玩家伤害型消化效果、或已带 `corrupted/spoiled/rotten/sour/dirty` 等坏标签的食物块不再重复变质，其余食物块会被加上 `corrupted` 标记、名称前缀改为“变质”、消化时间额外延长 `1t`，并在原有效果基础上额外附带 `1` 点消化反噬伤害。这样先把“前两个好的食物块会变坏”的设定落到战斗里，后续你们再细化什么算“好”、以及坏块具体类型时，也可以沿着这个运行时状态继续扩展。顺手把演示战斗和草莓怪物都接入了实际的 `腐坏扩散` 动作，方便直接观察效果。
- 影响文件：`scripts/runtime/food_block_instance.gd`、`scripts/runtime/battle_rules.gd`、`scripts/content/sample_battle_factory.gd`、`scripts/content/monster_catalog.gd`、`devlog.md`
- 如何验证：进入演示战斗或遭遇草莓怪物，推进时间直到敌人触发 `腐坏扩散`；确认敌方队列中从前往后数的前 `2` 个原本没有坏效果的食物块会立即改名为“变质…”，并在右侧敌人掉落队列中保留新名字；之后再吃下这些变质块，确认它们比原来多 `1t` 消化时间，并在消化完成时额外对玩家造成 `1` 点伤害；若队列前方本来就是坏块或已变质块，则应跳过它们，继续尝试污染后面的好块。

### 新增战斗胜利结算画面与奖励展示占位
- 做了什么：新增独立的 `BattleVictoryOverlay` 结算层，并接入到 `BattleScene` 的胜利流程中。现在战斗在胜利后不会立刻切回探索，而是先弹出结算画面，展示胜利标题、结算摘要、金币奖励区、卡牌奖励区和“继续探索 / 完成本局”按钮；金币数值直接读取当前房间已有的 `reward_gold` 作为展示预览，卡牌奖励暂时只保留 UI 展示位，不接入发放或选牌逻辑。玩家点击继续后，才会把结果交回 `RunController`，再按原有规则发金币并返回探索或结束 Boss 局。
- 影响文件：`scenes/ui/battle_victory_overlay.tscn`、`scripts/ui/battle_victory_overlay.gd`、`scripts/ui/battle_scene.gd`、`scripts/run/run_controller.gd`、`devlog.md`
- 如何验证：进入任意一场战斗并取得胜利，确认不会立刻跳回探索，而是先出现新的胜利结算画面；结算画面应包含金币奖励区和卡牌奖励区，其中金币区显示当前房间配置的金币数，卡牌区显示占位文案；点击“继续探索”后才返回探索并结算金币；若是 Boss 战胜利，按钮文案应变为“完成本局”，点击后进入本局结束状态。

### 移除战斗底部旧占位图标并清理相关代码
- 做了什么：删除了战斗场景底部原先用于占位的 `PlayerActorView` / `EnemyActorView` 两个旧图标节点，并从 `battle_scene.gd` 中移除了对应的引用、初始化、状态刷新和闪烁反馈逻辑；同时直接删除了已经完全无用的 `scripts/ui/battle_actor_view.gd`。现在战斗场景只保留美术同事已经接入的 `BattlePlayerSprite` / `BattleEnemySprite` 作为角色展示，不再混用旧占位表现。顺手修复了 `battle_enemy_sprite.gd` 中局部变量 `sprite_frames` 遮蔽 `AnimatedSprite2D.sprite_frames` 基类属性的 warning。
- 影响文件：`scenes/battle/battle_scene.tscn`、`scripts/ui/battle_scene.gd`、`scripts/ui/battle_enemy_sprite.gd`、`scripts/ui/battle_actor_view.gd`、`devlog.md`
- 如何验证：进入战斗后，确认底部抽牌堆与弃牌堆上方不再显示那两个简笔画占位图标；场景中只保留新的玩家与敌人大素材表现；重新加载脚本时不应再出现 `battle_enemy_sprite.gd` 里关于 `sprite_frames` 的 `SHADOWED_VARIABLE_BASE_CLASS` warning。

### 玩家默认胃容量从 3 提升到 6
- 做了什么：将项目当前默认玩家胃容量统一从 `3` 调整为 `6`，不只修改演示战斗，还同步更新了战斗定义、探索 run 初始值和战斗运行时默认值，避免从不同入口进入战斗时容量不一致。
- 影响文件：`scripts/content/sample_battle_factory.gd`、`scripts/data/battle_definition.gd`、`scripts/run/run_factory.gd`、`scripts/run/run_state.gd`、`scripts/runtime/battle_state.gd`、`devlog.md`
- 如何验证：进入演示战斗或从探索进入一场战斗后，确认玩家胃袋可容纳 6 个体积为 1 的食物块；连续吃下 6 个普通食物块前不应再出现“胃容量不足”，吃第 7 个时才应触发容量不足判定。

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

## 2026-05-15

### 面包怪物旧采样结果删除后按新原图重新生成
- 做了什么：由于面包怪物原始素材已替换，先按要求删除了旧的 `sprites/怪物_256x144/面包` 采样结果，再用现有最近邻下采样脚本从新的 `sprites/怪物/面包` 原图重新生成整套输出。面包新原图当前仍是 `1280x720`，因此继续按既有规则采样为 `256x144`，并保持 `MonsterCatalog` 里原有的 `res://sprites/怪物_256x144/面包` 路径不变，这样探索房间和战斗里会自动吃到新素材。
- 影响文件：`sprites/怪物_256x144/面包/*`、`devlog.md`
- 如何验证：检查 `sprites/怪物_256x144/面包/`，确认已重新生成 `50` 张 `256x144` 的 PNG；运行游戏进入 `bread_room` 或对应战斗，确认显示的面包怪物已经切换为新的动画素材。

### 部分怪物房接入小镇地图与喷泉地图的前后景
- 做了什么：将 `cake_room`、`bread_room`、`strawberry_room`、`fish_boss_room` 四个怪物房从单层森林底图改为使用 `小镇地图` / `喷泉地图` 的背景与前景组合，并在每个房间场景里新增全屏 `Foreground` 贴图节点。当前做法是让 `Backdrop` 使用 `z_index = -10` 作为角色和怪物之后的背景层，`Foreground` 使用 `z_index = 10` 作为角色和怪物之前的遮挡层，图片按 `1280x720` 直接全屏铺开，后续可再继续调整每个房间具体用哪套图。
- 影响文件：`scenes/rooms/cake_room.tscn`、`scenes/rooms/bread_room.tscn`、`scenes/rooms/strawberry_room.tscn`、`scenes/rooms/fish_boss_room.tscn`、`devlog.md`
- 如何验证：在编辑器中打开上述四个房间场景，确认都新增了 `Foreground` 节点，且 `Backdrop` / `Foreground` 分别引用 `sprites/map/小镇地图/` 或 `sprites/map/喷泉地图/` 下的图片；运行探索进入这些房间，确认背景显示在主角和怪物后面，前景显示在它们前面，交互与出入口仍正常。

### 森林地图房间补齐前景层
- 做了什么：把仍在使用 `森林地图` 的探索房间也统一补成“背景 + 前景”双层结构，不再只显示 `背景.png`。当前为 `start_room`、`chest_room`、`marshmallow_room`、`candy_bean_room` 新增了全屏 `Foreground` 贴图，并给森林背景也补上 `z_index = -10`，确保森林地图与小镇/喷泉地图一样，都会把角色和怪物夹在背景与前景之间显示。
- 影响文件：`scenes/rooms/start_room.tscn`、`scenes/rooms/chest_room.tscn`、`scenes/rooms/marshmallow_room.tscn`、`scenes/rooms/candy_bean_room.tscn`、`devlog.md`
- 如何验证：在编辑器中打开上述四个房间，确认除了 `Backdrop` 外还多出一层 `Foreground`，并引用了 `sprites/map/森林地图/前景1.png` 或 `前景2.png`；运行探索进入这些房间，确认前景会显示在主角、怪物和交互物前方，而不是只剩单层森林背景。

### 各套探索地图改为同时叠加全部前景层
- 做了什么：调整探索房间的地图使用方式，不再是“每个房间只挑一张前景图”，而是让每个使用某套地图的房间都同时叠加该地图下的全部前景资源。现在森林地图房间会同时挂 `前景1/2/3`，小镇地图房间会同时挂 `前景1/2`，喷泉地图房间会同时挂 `前景1/2/3/4`，并按 `z_index = 10/11/12/...` 依次叠到角色和怪物前面；顺手也把旧的 `monster_room`、`boss_room` 模板补成同样结构，避免后续误用时表现不一致。
- 影响文件：`scenes/rooms/start_room.tscn`、`scenes/rooms/chest_room.tscn`、`scenes/rooms/marshmallow_room.tscn`、`scenes/rooms/candy_bean_room.tscn`、`scenes/rooms/cake_room.tscn`、`scenes/rooms/strawberry_room.tscn`、`scenes/rooms/bread_room.tscn`、`scenes/rooms/fish_boss_room.tscn`、`scenes/rooms/monster_room.tscn`、`scenes/rooms/boss_room.tscn`、`devlog.md`
- 如何验证：在编辑器中分别打开使用森林/小镇/喷泉地图的房间场景，确认每个房间节点树里都不止一层 `Foreground`，而是完整包含该地图下全部前景贴图；运行探索进入这些房间，确认所有前景都会一起叠加显示在主角、怪物和交互物前方。

### 森林地图前景统一加黄绿色半透明染色
- 做了什么：只对使用 `森林地图` 的前景层追加统一的 `self_modulate` 染色，不改小镇地图和喷泉地图。当前森林地图的所有 `Foreground1/2/3` 都设置为 `#F1EE6B`，不透明度 `29%`，对应 Godot 场景里的 `Color(0.945098, 0.933333, 0.419608, 0.29)`，用于给森林前景整体加一层偏黄的氛围色。
- 影响文件：`scenes/rooms/start_room.tscn`、`scenes/rooms/chest_room.tscn`、`scenes/rooms/marshmallow_room.tscn`、`scenes/rooms/candy_bean_room.tscn`、`scenes/rooms/monster_room.tscn`、`scenes/rooms/boss_room.tscn`、`devlog.md`
- 如何验证：在编辑器中打开任一森林地图房间，确认 `Foreground1/2/3` 的 `self_modulate` 都变成 `Color(0.945098, 0.933333, 0.419608, 0.29)`；运行探索进入森林地图房间，确认前景整体带有轻微黄绿色调和 29% 透明度，而小镇地图、喷泉地图房间的前景颜色保持原样不变。

### 修复卡组预览首次打开时卡牌列表错误变成单列
- 做了什么：继续修正 `DeckViewOverlay` 的网格重建时机。前一版只把首次打开延后到下一帧，但实际从“弃牌堆”等入口打开时，内容区宽度有时在下一帧仍未稳定，依旧可能按 `1` 列生成网格。现在改为统一监听 overlay、本体内容面板和滚动区的 `resized`，并在内容区宽度达到可容纳至少两列卡牌前持续延后重建，最多重试数帧；列数计算也统一改成从内容区实际宽度 helper 获取，避免某些入口仍读到 0 宽度。
- 影响文件：`scripts/ui/deck_view_overlay.gd`、`devlog.md`
- 如何验证：已运行 `D:\Godot\Godot_v4.6.2-stable_win64.exe --headless --path . --scene res://scenes/ui/deck_view_overlay.tscn --quit` 与 `D:\Godot\Godot_v4.6.2-stable_win64.exe --headless --path . --quit`；进入战斗后分别从“查看卡组”“抽牌堆”“弃牌堆”三个入口第一次打开覆盖层，确认卡牌分组都直接按多列网格显示，不再出现“一张卡占一行”，切换 tab 后也应保持正常。

### 卡组预览覆盖层改用手绘版外框与分类按钮素材
- 做了什么：将 `DeckViewOverlay` 的外层面板、内部内容区、分类分组容器、顶部分类按钮和右上角返回按钮改为直接使用 `sprites/大框.png`、`sprites/中框.png`、`sprites/小框.png`、`sprites/分类框/平常分类.png`、`sprites/分类框/选中分类.png` 与 `sprites/返回.png` 中的有效区域；保留原有卡组数据分组、切页和关闭交互，只替换界面外壳与按钮表现，并补上了基于贴图的 hover / pressed 反馈。
- 影响文件：`scripts/ui/deck_view_overlay.gd`、`devlog.md`
- 如何验证：已运行 `D:\Godot\Godot_v4.6.2-stable_win64.exe --headless --path . --scene res://scenes/ui/deck_view_overlay.tscn --quit` 与 `D:\Godot\Godot_v4.6.2-stable_win64.exe --headless --path . --quit`，确认项目和该界面场景都能正常加载；进入战斗后打开“查看卡组”，确认整体外框、内部内容框、分类按钮选中态和右上角返回按钮都切换为新的手绘素材，并检查切换“整个卡组 / 抽牌堆 / 弃牌堆”以及按 `Esc` / 点击返回关闭仍然正常。

### 蛋糕怪物改为按五倍缩小采样
- 做了什么：发现蛋糕原始帧尺寸不是和其他怪物一致的 `1280x720`，而是更大的 `2276x1280`，因此不再强行采样成 `256x144`；为现有下采样脚本补充了 `--scale-divisor` 选项后，只重生成了 `sprites/怪物_256x144/蛋糕` 目录，使蛋糕帧按五倍缩小输出为 `455x256`，保留其原始纵横比与构图。面包和其他既有怪物未改动，仍保持原先的采样结果。
- 影响文件：`tools/resize_player_sprites.py`、`sprites/怪物_256x144/蛋糕/*`、`devlog.md`
- 如何验证：检查 `sprites/怪物_256x144/蛋糕/*.png`，确认输出分辨率已变为 `455x256` 而不是 `256x144`；重新进入蛋糕怪物房与蛋糕战斗，确认动画仍可正常播放，且画面构图比之前更符合原素材比例。

### 新增蛋糕与面包怪物，补齐探索房间与战斗接入
- 做了什么：使用现有下采样脚本将 `sprites/怪物/蛋糕` 和 `sprites/怪物/面包` 的原始帧统一采样到 `sprites/怪物_256x144/`；随后在 `MonsterCatalog` 中新增 `cake`、`bread` 两个怪物定义，补上各自的探索/战斗动画目录、房间场景和临时战斗逻辑；新增 `cake_room.tscn`、`bread_room.tscn` 两个怪物房，并把地图链路调整为“起点 -> 棉花糖/糖豆 -> 蛋糕/面包 -> 草莓 -> 鱼 Boss”，使新怪物与现有怪物一样支持探索中可视化摆放、靠近高亮、按 `E` 进入战斗。
- 影响文件：`tools/resize_player_sprites.py`（复用未修改）、`sprites/怪物_256x144/蛋糕/*`、`sprites/怪物_256x144/面包/*`、`scripts/content/monster_catalog.gd`、`scripts/map/map_generator.gd`、`scenes/rooms/cake_room.tscn`、`scenes/rooms/bread_room.tscn`、`scenes/rooms/marshmallow_room.tscn`、`scenes/rooms/candy_bean_room.tscn`、`scenes/rooms/strawberry_room.tscn`、`devlog.md`
- 如何验证：运行游戏后从起点进入棉花糖房与糖豆房，确认出口分别会通向新增的蛋糕房与面包房；进入 `cake_room`、`bread_room` 时确认能看到对应怪物动画、靠近后出现高亮描边、按 `E` 能进入战斗；打完后继续前往草莓房和 Boss 房，确认整条房间链路都能正常走通。

### 优化怪物房加载与进战斗卡顿
- 做了什么：清理了 `marshmallow/candy_bean/fish_boss` 三个怪物房 `.tscn` 中被意外内嵌进去的大量 `Image/ImageTexture/SpriteFrames` 数据，让房间重新只保留对 `monster_encounter.tscn` 的外部引用；同时把怪物探索动画和战斗动画的加载改成统一走 `MonsterCatalog` 的 `SpriteFrames` 缓存，并直接 `load()` 导入后的贴图资源，不再在进入房间或进入战斗时同步逐帧 `Image.load_from_file()` 解码 PNG。这样可以同时减少“切入怪物房”和“按 E 进战斗”两段主线程卡顿。
- 影响文件：`scripts/content/monster_catalog.gd`、`scripts/explore/monster_encounter.gd`、`scripts/ui/battle_enemy_sprite.gd`、`scenes/rooms/marshmallow_room.tscn`、`scenes/rooms/candy_bean_room.tscn`、`scenes/rooms/fish_boss_room.tscn`、`devlog.md`
- 如何验证：运行游戏后从起点进入棉花糖/糖豆/Boss 房，确认切房时不再出现此前那种明显的数秒停顿；靠近怪物按 `E` 进入战斗，确认战斗场景仍能显示对应怪物动画，且进入速度明显快于之前；重新打开上述三个房间 `.tscn`，确认文件体积恢复正常，不再因为展开可编辑子场景而保存出几十 MB 的文本场景。

### 修复手动调整交互物后名称丢失且无法交互的问题
- 做了什么：将 `ExploreInteractable`、`MonsterEncounter`、`RoomAnchor` 的导出属性读取方式改回与 Godot 场景序列化一致，不再依赖未同步的 backing field；同时把 `payload` 改为可导出字段，并兼容已保存房间里仅修改了 `Label.text` 的旧数据。随后补回 `start/chest/棉花糖/糖豆/Boss` 房间中因可编辑子场景保存而丢失的 `payload`、`monster_id`、`anchor_kind` 等关键字段，恢复出口跳转、提示消息、宝箱和怪物交互。
- 影响文件：`scripts/explore/explore_interactable.gd`、`scripts/explore/monster_encounter.gd`、`scripts/explore/room_anchor.gd`、`scripts/explore/explore_scene.gd`、`scenes/rooms/start_room.tscn`、`scenes/rooms/chest_room.tscn`、`scenes/rooms/marshmallow_room.tscn`、`scenes/rooms/candy_bean_room.tscn`、`scenes/rooms/fish_boss_room.tscn`、`devlog.md`
- 如何验证：打开任一房间场景，确认交互物导出面板中能直接看到 `display_name / interactable_kind / payload`；运行游戏后确认入口提示显示“清扫路线图”而不是“交互物”，靠近出口/宝箱/怪物按 `E` 能正常触发，切房后不会再出现所有交互都失效的情况。

### 出口等基础交互范围改为编辑器内可见
- 做了什么：将 `ExploreInteractable` 改为 `@tool`，并把 `Area2D`、`CollisionShape2D`、`Label` 直接放进 `scenes/explore/explore_interactable.tscn`，不再只在运行时动态创建；随后又把各房间里实例化的出口、宝箱和怪物节点标记为 `editable` 子节点，解决“子场景内部已有碰撞范围，但在父房间 `.tscn` 中默认仍看不到/不能直接编辑”的问题。
- 影响文件：`scripts/explore/explore_interactable.gd`、`scenes/explore/explore_interactable.tscn`、`scenes/rooms/start_room.tscn`、`scenes/rooms/chest_room.tscn`、`scenes/rooms/marshmallow_room.tscn`、`scenes/rooms/candy_bean_room.tscn`、`scenes/rooms/strawberry_room.tscn`、`scenes/rooms/fish_boss_room.tscn`、`devlog.md`
- 如何验证：在编辑器中打开任一房间场景，确认出口/宝箱/怪物实例可以展开看到内部 `Area2D` 和 `CollisionShape2D`，并能在父场景里直接选中和调整交互范围；运行游戏后交互逻辑仍保持正常。

### 修正怪物运行时不显示的问题
- 做了什么：把 `MonsterEncounter` 在运行时加载怪物定义的读取来源从导出属性 `monster_id` 改为 setter 写入的 backing field `_monster_id`，避免场景实例化后实际取到空值导致不加载怪物动画；顺便保持编辑器预览和运行时使用同一份怪物定义路径。
- 影响文件：`scripts/explore/monster_encounter.gd`、`devlog.md`
- 如何验证：进入任一怪物房，确认运行时怪物动画正常出现；编辑器里打开对应 `.tscn` 也仍能看到怪物预览。

### 怪物交互节点改为场景内可视化编辑
- 做了什么：将 `MonsterEncounter` 从运行时动态创建 `AnimatedSprite2D / Area2D / CollisionShape2D` 的形式，改为直接把这些节点放进 `scenes/explore/monster_encounter.tscn`；同时给脚本加上 `@tool` 和编辑器预览刷新逻辑，使怪物房 `.tscn` 在 Godot 编辑器中打开时就能直接看到怪物动画、选中交互范围并手动调整位置。`ExploreInteractable` 也同步兼容“优先复用场景里现成子节点，缺失时再运行时补建”的模式。
- 影响文件：`scripts/explore/explore_interactable.gd`、`scripts/explore/monster_encounter.gd`、`scenes/explore/monster_encounter.tscn`、`devlog.md`
- 如何验证：在编辑器中直接打开任一怪物房场景，确认场景树下的怪物节点包含 `AnimatedSprite2D`、`Area2D`、`CollisionShape2D`；视口中应能直接看到怪物预览，并能选中/调整交互范围；运行探索后怪物高亮和按 `E` 进入战斗仍正常。

### 探索界面外层 HUD 精简为仅保留右上角 HP/金币
- 做了什么：移除探索主界面外层的上方标题区、底部提示/状态区和包裹房间的外围面板，只保留全屏房间画面、游戏结束覆盖层以及右上角 `HP/金币` 文本；同时删除 `start`、`chest` 及四个怪物房场景中的 `Title` 标签，避免房间中央和左上角再出现文字标题。`explore_scene.gd` 同步改为不再依赖这些已删除节点。
- 影响文件：`scripts/explore/explore_scene.gd`、`scenes/explore/explore_scene.tscn`、`scenes/rooms/start_room.tscn`、`scenes/rooms/chest_room.tscn`、`scenes/rooms/marshmallow_room.tscn`、`scenes/rooms/candy_bean_room.tscn`、`scenes/rooms/strawberry_room.tscn`、`scenes/rooms/fish_boss_room.tscn`、`devlog.md`
- 如何验证：进入探索后确认场景四周不再有外围面板、底部提示文字和左上角房间名；右上角仍显示 `HP` 和 `金币`；房间内部也不再出现 `Title` 标签；接近交互物、进入战斗和本局结束覆盖层仍能正常工作。

### 删除怪物房中央装饰性 Panel 色块
- 做了什么：删除四个新怪物房场景中仅用于衬托站位的装饰性 `Panel` 节点，避免探索房间中央再出现明显的深色半透明矩形块；怪物动画、交互范围、出口和房间逻辑不受影响。
- 影响文件：`scenes/rooms/marshmallow_room.tscn`、`scenes/rooms/candy_bean_room.tscn`、`scenes/rooms/strawberry_room.tscn`、`scenes/rooms/fish_boss_room.tscn`、`devlog.md`
- 如何验证：分别进入四个怪物房，确认房间中央不再显示额外的半透明矩形底板，只保留背景、怪物动画和交互提示；靠近怪物时高亮描边、按 `E` 进入战斗仍正常。

### 撤掉新增的怪物房与怪物专属显示命名
- 做了什么：把这轮新增的显示层命名全部改回通用表述，房间标题统一恢复为“怪物房”或“Boss房”，出口提示不再显示“糖霜操作台”“果酱冷柜”等自定义名字，怪物显示名和战斗敌人名也统一回“污染怪物”或“Boss”；内部 `monster_id`、目录和逻辑拆分保持不变。
- 影响文件：`scripts/content/monster_catalog.gd`、`scenes/rooms/start_room.tscn`、`scenes/rooms/marshmallow_room.tscn`、`scenes/rooms/candy_bean_room.tscn`、`scenes/rooms/strawberry_room.tscn`、`scenes/rooms/fish_boss_room.tscn`、`devlog.md`
- 如何验证：进入探索后确认界面上不再出现“糖霜操作台”“撒糖走道”“果酱冷柜”“后厨水槽”等命名；普通怪物房显示为“怪物房”，Boss 房显示为“Boss房”，战斗中的敌人名称也不再区分四种怪物的专属名字。

### 探索怪物改为独立 AnimatedSprite，并按怪物拆分房间与战斗定义
- 做了什么：新增 `MonsterCatalog` / `MonsterDefinition`，按棉花糖、糖豆人、草莓、鱼 Boss 四个怪物分别维护显示名、探索/战斗动画目录、房间场景和战斗 `EnemyData`；探索层新增 `MonsterEncounter`，用 `AnimatedSprite2D + Area2D` 取代旧的矩形怪物交互框，怪物现在固定站在房间中央，玩家靠近时会通过 shader 显示发光描边，按 `E` 后进入战斗；地图房间从原本单一 `monster_room` / `boss_room` 改为四个独立怪物房，战斗定义也新增 `monster_id`，使战斗场景可加载对应怪物动画。
- 影响文件：`scripts/content/monster_definition.gd`、`scripts/content/monster_catalog.gd`、`scripts/explore/monster_encounter.gd`、`scenes/explore/monster_encounter.tscn`、`shaders/sprite_outline.gdshader`、`scripts/data/battle_definition.gd`、`scripts/run/battle_definition_builder.gd`、`scripts/map/map_generator.gd`、`scripts/run/run_factory.gd`、`scripts/ui/battle_enemy_sprite.gd`、`scripts/ui/battle_scene.gd`、`scenes/battle/battle_scene.tscn`、`scenes/rooms/marshmallow_room.tscn`、`scenes/rooms/candy_bean_room.tscn`、`scenes/rooms/strawberry_room.tscn`、`scenes/rooms/fish_boss_room.tscn`、`scenes/rooms/start_room.tscn`、`devlog.md`
- 如何验证：进入探索后确认起点可通往棉花糖房、糖豆房和宝箱房；进入任一怪物房后确认房间中央显示该怪物的循环动画，主角靠近时怪物出现描边发光，按 `E` 会进入对应战斗；进入战斗后确认战斗场景中会显示与房间一致的怪物动画；击败棉花糖房/糖豆房后可继续前往草莓房，再前往鱼 Boss 房。

## 2026-05-14

### 手牌区上移与日志区压缩
- 做了什么：为 `HandView` 增加 `HAND_VERTICAL_OFFSET` 手动纵向偏移参数并默认设为 `-22.0`，让手牌整体向上移动，同时同步调整出牌释放判定边界；将战斗底部区域 `BottomRow` 高度从 260 增加到 286，使上方日志区自然缩短，给手牌与时间轴更多空间。
- 影响文件：`scripts/ui/hand_view.gd`、`scenes/battle/battle_scene.tscn`、`devlog.md`
- 如何验证：进入战斗后确认手牌整体比之前更靠上，拖拽出牌判定仍以手牌区上方为准；确认日志区高度略短但仍可滚动，底部手牌与时间轴显示正常。

### 卡牌轮廓高亮颜色与时钟边缘优化
- 做了什么：将卡牌状态高亮主色从白色改为金黄色；为轮廓贴图额外保留 8px 透明采样边界并关闭 `CardView` 裁剪，避免左上角时钟高亮被控件边缘截断；同时把轮廓 shader 改为 16 方向采样并使用平滑 alpha 过渡，减少圆形时钟描边的多边形感。
- 影响文件：`scripts/ui/card_view.gd`、`scenes/ui/card_view.tscn`、`devlog.md`
- 如何验证：进入战斗悬停或拖拽卡牌，确认高亮为黄色系，左上角时钟外圈不再明显被切掉，时钟描边比之前更圆滑；确认拖拽、可出牌和不可用状态仍保持不同颜色反馈。

### 卡牌状态高亮改为贴图轮廓描边
- 做了什么：将 `CardView` 的状态高亮从旧的矩形 `Panel` 边框改为 `TextureRect + canvas_item shader`，根据当前卡牌透明素材的 alpha 边缘绘制轮廓，避免高亮框住透明背景区域；攻击/技能/净化三类卡会复用各自当前背景贴图生成对应轮廓。
- 影响文件：`scripts/ui/card_view.gd`、`scenes/ui/card_view.tscn`、`devlog.md`
- 如何验证：进入战斗并悬停、拖拽或移动到可出牌区域，确认高亮沿卡牌本体和左上角时间 UI 的素材边缘显示，不再出现旧版完整矩形白框；确认不可用、拖拽、可出牌状态仍有不同颜色反馈。

### 卡牌 UI 背景改用透明原始素材
- 做了什么：将 `CardView` 的攻击/技能/净化卡背景从 `sprites/card_backgrounds/*.png` 改为直接读取 `sprites/攻击卡.png`、`sprites/技能卡.png`、`sprites/净化卡.png`，并继续用 `AtlasTexture` 裁出 336x448 的有效卡面区域，避免整张 1024x750 透明画布把卡面缩小。
- 影响文件：`scripts/ui/card_view.gd`、`scenes/ui/card_view.tscn`、`devlog.md`
- 如何验证：打开 `res://scenes/ui/card_view.tscn` 或进入战斗，确认三类手牌显示为透明背景版本的卡牌素材，不再使用 `sprites/card_backgrounds` 中的旧裁切图；确认费用、名称、图案占位、描述以及拖拽/悬停状态反馈仍正常显示。

### 战斗时间轴卡牌生效标记与悬停预览
- 做了什么：新增 `CardEffectRecord` 记录每张成功生效卡牌的时间点、牌名、耗时和效果摘要；卡牌完成耗时推进且未被战斗结束打断后写入历史记录；时间轴在对应时间点绘制 `sprites/时间轴/卡牌生效标记.jpg` 裁切出的标记，鼠标悬停时由独立 `CardEffectTimelineMarker` 发出预览请求，并由 `CardEffectPreviewPopup` 显示该时间点生效过的卡牌。
- 影响文件：`scripts/runtime/card_effect_record.gd`、`scripts/runtime/battle_state.gd`、`scripts/runtime/battle_rules.gd`、`scripts/ui/card_effect_timeline_marker.gd`、`scripts/ui/card_effect_preview_popup.gd`、`scripts/ui/battle_scene.gd`、`devlog.md`
- 如何验证：进入战斗后打出带耗时或 `0t` 的卡牌，确认时间轴对应时间点出现卡牌生效标记；拖动时间轴回看历史时标记仍保留；鼠标悬停标记会显示牌名、耗时和效果摘要，移开后隐藏；同一时间点有敌人行动时敌人行动标记和卡牌标记都应可见。

### 时间轴卡牌生效标记透明化与缩小
- 做了什么：从 `sprites/时间轴/卡牌生效标记.jpg` 派生只包含卡牌本体的透明 PNG `sprites/时间轴/卡牌生效卡牌标记.png`，移除原素材中的白底和下方三角回合标记；时间轴改用新小图，并把显示尺寸缩小、略微右移，减少与当前回合标记重合。
- 影响文件：`sprites/时间轴/卡牌生效卡牌标记.png`、`scripts/ui/battle_scene.gd`、`devlog.md`
- 如何验证：进入战斗后打出卡牌，确认时间轴卡牌生效标记不再有白底，也不再包含三角回合标记；当前时间点附近的卡牌标记不会直接压在当前回合标记中心。

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
- 如何验证：进入战斗场景后，食物槽应出现在屏幕右侧；日志区域应恢复为原来的大矩形并能显示战斗开始、抽牌、出牌等日志，同时整体不再向右铺满整个屏幕。
