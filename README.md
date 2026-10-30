# Wrongway Down

A Godot 4.6 gravity-flipping puzzle platformer with 40 progressively more demanding rooms. The campaign moves from safe flips and patrols into timed reaction barriers, shorter openings, and combined switch challenges.

## Play

Open project.godot in Godot 4.6 and press F5. Choose Play or Continue. Choose Level shows unlocked and completed rooms; completing a room unlocks the next. Replaying does not erase progress.

| Input | Action |
| --- | --- |
| A / D or left / right | Move |
| Space | Flip from a supporting surface |
| R | Restart current room; reset checkpoint and switches |
| Escape | Pause/resume; leave level selection |
| Arrow keys + Enter, or mouse | Navigate menus |

There is no jump or midair flip. Pink spikes and patrols cause respawn. Amber flags save position and gravity. Violet lettered switches open matching gates; every listed letter is required. Switches stay active after death but reset on restart. Mint doors complete rooms.

## Campaign and Gravitos

1. First Flip: safe introduction and ceiling exit.
2. Safe Landing: first spikes and a forgiving ceiling route.
3. Both Sides: plan a return to the floor.
4. Zigzag: three alternating crossings.
5. Headroom: solid blocks and route reading.
6. Take Your Time: first moving patrol.
7. Permission: switch-controlled gate.
8. Upper Ground: four crossings and a ceiling checkpoint.
9. Two Keys: two switches and two patrols.
10. Field Exam: combine the chapter's mechanics.
11-20. Reflex: introduce visible pulse barriers and faster patrol reads.
21-30. Pulse: combine two barriers with route and switch choices.
31-40. Mastery: shortest safe windows and the full set of established mechanics.

Movement speed stays constant; difficulty grows through routing, reaction timing and combinations. There is no time limit. Human playtesting is still needed to confirm the intended curve.

Each room rewards Gravitos. The first clear pays the listed reward; replaying a room pays one tenth. Previous progress is migrated on first launch, so already-completed rooms receive their original first-clear reward once. The main menu and level selection show your balance and the next reward.

## Shop and Sound

The Alien Shop unlocks six cosmetic aliens: Sprout, Orbix, Jellyfin, Emberling, Luna Moth and Nebula Crown. Characters share exactly the same hitbox and movement; the choice is visual. Purchases, ownership and equipped alien are saved.

Sound Settings provides master, music and effect sliders plus mute. Settings apply immediately and save between sessions. The game includes a quiet procedural ambient loop and synthesized effects.

## Documentation and extension

- [LEVEL_AUTHORING.md](docs/LEVEL_AUTHORING.md): exact data schema and how to add room 11 onward.
- [DESIGN.md](docs/DESIGN.md): current scope and human playtest checklist.
- [VALIDATION.md](docs/VALIDATION.md): recorded checks and remaining validation.

Each room has a JSON file in levels/. Append its path to levels/campaign.json to extend the game. Menus, counts, unlocks and ending detection derive from the manifest. Completed stable IDs survive content additions; preserve IDs when changing titles or layouts. An appended room 11 unlocks for someone who has completed room 10.

## Runtime files

| File | Responsibility |
| --- | --- |
| scenes/test_room.tscn | Campaign entry scene; original path retained |
| scripts/campaign.gd | Navigation, HUD, respawning and game flow |
| scripts/level_catalog.gd | Manifest loading and structural validation |
| scripts/level.gd | Build geometry, objects and gate connections |
| scenes/player.tscn + scripts/player.gd | Character collision and gravity movement |
| scenes/object.tscn + scripts/object.gd | Spikes, checkpoint, exit and switch contacts |
| scripts/moving_hazard.gd | Patrol movement and collision |
| scripts/progress.gd | Save/load and stable-ID unlocks |
| scripts/game_audio.gd | Synthesized feedback tones |
| ui/campaign_menu.gd | Main, pause, level selection and completion controls |
| tests/smoke.gd | Automated route and state checks |

## Saves

Completed IDs are stored in user://campaign.cfg, in Godot's application-data directory for Wrongway Down. Checkpoints and switches are session-local. A missing/unreadable save starts fresh. Save-write errors are shown at completion; unlocks still work for that session.

## Run checks

With Godot on your PATH:

```powershell
godot --headless --path . --editor --import --quit
godot --headless --path . --fixed-fps 60 --script res://tests/smoke.gd
godot --path . --fixed-fps 60 --script res://tests/smoke.gd -- --capture
```

On Windows, use the full path to Godot_v4.6.3-stable_win64_console.exe if needed. Tests use a separate campaign-test.cfg save and delete only that file. Routes use actual movement/flip inputs; isolated collision tests also reposition the player. The capture option writes previews of rooms 1, 5, 10 and level selection into tests/.

## Assets and remaining scope

Graphics are original procedural shapes; effects use original synthesized tones. No external art, music or fonts were downloaded. The editor-generated Godot icon remains. art/ and audio/ are reserved for future assets.

Music/audio settings, control remapping, controller support, moving platforms, later chapters and exported builds remain future work. When exporting, include *.json in the preset's non-resource filter to package the level data.
