# Wrongway Down

A Godot 4.6 desktop puzzle-platformer prototype. Flip between floor and ceiling, read your landing, and reach the mint exit. This is the first playable milestone, not the finished six-level game.

## Run

Import `project.godot` in Godot 4.6 and press **F6** on `scenes/test_room.tscn`, or **F5** to run the project. Choose **Enter the lab**. The complete room fits on screen; resize the window freely.

| Input | Action |
| --- | --- |
| A / D or left / right | Move |
| Space | Reverse gravity while touching the floor or ceiling |
| R | Restart the room and clear its checkpoint |
| Escape | Pause / resume |

There is no jump and no midair flip. Touch pink spikes to respawn. The amber flag saves a safe floor spawn and turns mint when active. The exit opens a completion menu with replay. Menus support mouse and keyboard navigation.

## Implemented

- Fixed-timestep CharacterBody2D movement, acceleration, bounded gravity, surface-relative grounded checks, and animated orientation.
- Reusable player and area-object scenes; a single test room with solid boundaries, floor and ceiling spikes, checkpoint, and exit.
- Start, pause, restart, completion, and replay flow; tutorial labels; flip, landing, checkpoint and death feedback with generated sound effects.
- A compatibility renderer and 1152 × 720 stretchable viewport.

## Layout and system

`scripts/player.gd` owns motion and changes `up_direction` when reversing gravity, allowing Godot's floor detection to work on the ceiling. A flip is allowed only when `is_on_floor()` is true. Respawn resets velocity, gravity, visual orientation and briefly settles collision contacts before allowing another flip.

`scripts/object.gd` supplies spike, checkpoint and exit Area2D triggers. `scripts/test_room.gd` assembles the room, owns the checkpoint and menus, and synthesizes short sound effects. All distances are pixels; physics uses delta time. A fixed camera is intentional because the entire route is visible.

## Next milestones

1. Playtest the ground-only flip rule and the first room with new players.
2. Add separate level resources and five additional rooms: Safe Landing, Narrow Passage, Timing, The Gate, Final Test.
3. Add moving hazards, then switches and doors. Consider moving platforms only after the core feels reliable.
4. Add progress saving, level selection, audio settings, reduced-shake option, music, and desktop export presets/templates.
5. Validate an exported build, record gameplay, and document real playtest changes for the portfolio.

There is currently no music, screen shake, persistent progress, export, or six-level campaign. See `docs/DESIGN.md` for scope and playtest checks.

## Validation

`godot --headless --path . --script res://tests/smoke.gd` runs the gameplay smoke test. Append `--max-fps 30` before `--script` to check low rendering frame rates. Run without `--headless` and append `-- --capture` to save `tests/room-preview.png`.

Verified with Godot 4.6.3: all 14 checks passed in a rendered run and a headless run capped at 30 FPS. Checks cover the complete route, grounded and airborne flip rules, ceiling support, checkpoint and initial-spawn deaths, pause, replay, wall collision, and corner flipping. The rendered room screenshot was visually inspected. Human playtesting, 144 FPS checks, and exported-build validation remain outstanding.

## Assets

All in-game graphics are original procedural shapes drawn by this project. Sound effects are original synthesized sine tones. No external art, audio or fonts were downloaded. The editor-generated Godot icon is retained as the project icon. Folders `art/` and `audio/` are reserved for future assets; menus currently live in the room script.
