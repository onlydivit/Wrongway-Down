# Wrongway Down - Chapter 01: Foundations

Target: desktop, Godot 4.6, GDScript. Feel: readable, responsive, forgiving. Rule: reverse gravity only from a supporting surface; no jump. Ten single-screen rooms introduce spikes, walls, checkpoints, moving patrols and switch-controlled gates.

The prototype's two-bank layout is now room 3, preceded by two safer introductions. The level data schema and extension instructions are in LEVEL_AUTHORING.md.

## Difficulty envelope

The player is 26 x 34 px. Speed is 270 px/s, gravity is 1500 px/s squared, terminal speed is 760 px/s. These stay constant. Required crossings grow from one to four. Patrols have roughly five-second cycles. Gates require one or two permanent switches. Checkpoints shorten retries and restore gravity.

This first chapter establishes skills rather than exhausting the difficulty potential. Future chapters can expand routing and introduce moving platforms or interacting mechanics. Do not tighten timing merely because a room number is larger.

## Human playtest checklist

- Can new players finish rooms 1-3 without verbal help?
- Is each mechanic understandable before the next one appears?
- Are danger, switches, checkpoints and exits identifiable from text/shapes as well as color?
- Can players find safe stopping and waiting positions?
- Does any room feel unexpectedly easier or harder than its neighbors?
- Are ceiling respawns understandable and safe?
- Does the two-key gate communicate that both switches are required?
- Does room 10 feel moderate, rather than a precision finale?
- Check both wall corners, repeated airborne Space presses and death near landing.
- Check pause during falling/patrol movement; restart from pause/completion; keyboard and mouse menus; progress after relaunch.
- Compare 30/60/144 rendering FPS on real hardware while physics stays fixed-step.
- Include JSON data in a Windows export and test outside the editor before release.

Record completion times and causes of repeated deaths during actual playtests. No human playtest results are claimed yet.
