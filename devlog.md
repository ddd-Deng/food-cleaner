# Devlog

## 2026-05-10
- Started the extensible battle foundation for the food-cleaner demo.
- Planned structure: shared battle types, data resources, runtime state, rules executor, demo content factory, and a minimal battle scene.
- Updated the battle presentation to a time-axis layout with placeholder panels for player, enemy, purification task, deck/discard, hand, and timeline.
- Removed a leftover turn-based controller call after the time-axis refactor so startup no longer references `BattleRules.end_player_turn()`.
- Tightened the first 1280x720 battle layout pass and aligned UI script paths with the new panel-based scene hierarchy.
- Added the missing `display_name` field to `EnemyActionData` after the sample content started assigning named enemy intents.
- Switched the Windows rendering backend in `project.godot` from `d3d12` to `vulkan`.
- Reordered the lower battle UI so the hand sits above the timeline, and translated the current battle scene labels, demo content names, and runtime log text into Chinese.
- Verification: not run in Godot from this environment; please reopen the battle scene and check the updated layout/text in the 1280x720 window.
- Replaced the temporary hand buttons with a dedicated draggable `CardView` scene, a `PlayDropZone`, typed card backgrounds, placeholder art labels, and an effect banner that summarizes the last played card.
- Added lightweight battle feedback flashes for HP, enemy food blocks, purification progress, and effect summary updates; kept battle resolution in `BattleRules`.
- Impacted files: `scripts/core/battle_types.gd`, `scripts/data/card_data.gd`, `scripts/runtime/card_instance.gd`, `scripts/runtime/battle_state.gd`, `scripts/runtime/battle_rules.gd`, `scripts/content/sample_battle_factory.gd`, `scripts/ui/battle_scene.gd`, `scripts/ui/card_view.gd`, `scripts/ui/play_drop_zone.gd`, `scenes/battle/battle_scene.tscn`, `scenes/ui/card_view.tscn`.
- Verification: launch `res://scenes/battle/battle_scene.tscn`, confirm hand cards render with the new layout, drag a card onto the drop zone to play it, drag elsewhere to ensure it returns without state changes, and verify the effect banner plus HP/block/progress flashes respond to card results.
- Added viewport stretch settings and gave the battle layout real container stretch ratios so fullscreen/window resizing should scale the interface proportionally instead of leaving it visually fixed.
- Verification: not run in Godot from this environment; please resize the game window in-editor or run fullscreen and confirm the main columns, hand area, timeline, and log expand smoothly.
- Reworked the battle UI layout toward a more spacious composition: left-side player area, centered task/time-log block, right-side enemy placeholder, and bottom-corner draw/discard piles with the hand/timeline centered.
- Fixed the top-left HP placeholder after `ProgressBar` rejected a `text` assignment by adding a separate overlay label in the same panel.
- Impacted files: `scenes/battle/battle_scene.tscn`, `scripts/ui/battle_scene.gd`.
- Verification: not run in Godot here; reopen the battle scene and confirm the HP bar shows text, the previous runtime error is gone, and the bottom/center panels still render in the new positions.
- Tightened the battle HUD further by putting `战斗时间` and `时间：0t` on one line, wrapping the log in a scroll container, and shrinking the deck/discard placeholders into small lower-corner blocks.
- Impacted files: `scenes/battle/battle_scene.tscn`, `scripts/ui/battle_scene.gd`.
- Verification: not run in Godot here; reopen the battle scene, confirm the log panel scrolls, and check the deck/discard boxes now sit as compact corner widgets.
- Updated the time row to a single-line label and reduced the deck/discard placeholders again so they read as tiny corner widgets rather than full cards.
- Impacted files: `scenes/battle/battle_scene.tscn`.
- Verification: not run in Godot here; reopen the battle scene and confirm the time row reads `战斗时间：0t` and the corner boxes stay compact.
