# Campaign validation — 17 October 2026

Engine: Godot 4.6.3 stable, Windows. Rendered run: OpenGL compatibility renderer on NVIDIA GeForce GTX 1650.

| Check | Result |
| --- | --- |
| Import and normal main-scene startup | Successful; no script errors in final startup check |
| Ten-level smoke suite, headless, fixed render delta 60 FPS | 57 checks passed |
| Ten-level smoke suite, rendered, fixed render delta 60 FPS | 57 checks passed |
| Ten-level smoke suite, headless, fixed render delta 30 FPS | 57 checks passed |
| Ten-level smoke suite, headless, fixed render delta 144 FPS | 57 checks passed; clean shutdown after audio cleanup fix |
| Visual inspection | Rooms 1, 5, 10 and level-selection menu inspected |

`--fixed-fps` controls simulated rendering cadence; these are not hardware performance benchmarks or measured monitor frame rates. Physics remains at Godot's normal fixed rate. Test input advances on physics ticks so it is independent of rendering delays.

## Covered behaviors

- Every room has a grounded spawn and a known zero-death route using movement, flips and patrol waits.
- Surface-only flipping rejects airborne presses; wall-corner flipping remains safe.
- Locked rooms cannot be started directly, completion is saved, and all ten IDs survive a reload.
- An appended eleventh room becomes available to a player who completed room 10.
- A two-key gate stays closed with one switch and loses collision only after both are active.
- A ceiling checkpoint restores upward gravity after actual spike contact.
- Switch state survives death; restart clears switches and checkpoints.
- Moving patrol contact kills the player; pause freezes both patrols and player.
- Completion/ending states follow the current campaign length.

Completion routes do not teleport, disable collisions or remove hazards. Separate targeted tests reposition the character to exercise contact and state transitions. The test save is isolated from real progress and removed at the end. A short wall-time shutdown interval lets the audio thread release its final playback even when headless simulation runs much faster than real time.

Previews are `tests/level-01-preview.png`, `tests/level-05-preview.png`, `tests/level-10-preview.png` and `tests/level-select-preview.png`. The older `tests/room-preview.png` is a historical prototype screenshot and does not represent the current campaign.

## Still required before release

- Blind human playtests to assess difficulty, clarity and retry frustration.
- Real hardware frame-rate/resize checks and mouse/keyboard usability testing beyond automated callbacks.
- Export-template setup, JSON inclusion in the export preset and testing the exported build outside Godot.
- Fault-injection tests for unreadable saves and disk-write failures; fallback/reporting paths exist but have not been exercised here.
