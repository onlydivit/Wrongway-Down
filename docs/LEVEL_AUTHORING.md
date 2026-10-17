# Adding a room

1. Copy a similar JSON from `levels/`, assign a new permanent `id`, and change title, hint and layout.
2. Append `res://levels/11_your_room.json` to `levels/campaign.json`. Array order is play order; filenames are only a convention.
3. Run the Godot import and campaign test. Add a route to `tests/smoke.gd` and update its expected campaign count when adding shipped content.
4. Play from the previous room, verify Continue and replay, and test every checkpoint's gravity. Record the new room's difficulty rationale in your development notes.

## Coordinate system and schema

The viewport is 1152 × 720. Playable space is x40–1112, y160–600. Positive Y points down. Floor player center is approximately y583; ceiling center is y177. Use y578 or y182 to spawn slightly away from the supporting surface. The builder always creates the four outside walls.

| Field | Format | Meaning |
| --- | --- | --- |
| `id` | unique nonempty string | Persistent save key; never change an existing ID. |
| `title`, `hint`, `difficulty` | strings | HUD/menu text; keep title short and hint roughly one line. |
| `spawn` | `[center_x, center_y, gravity]` | Player start; gravity is `1` down or `-1` up. |
| `exit` | `[left_x, top_y, surface]` | 60 × 68 exit rectangle; top_y=532 for floor, 160 for ceiling; surface controls the label. |
| `walls` | `[[x, y, width, height], ...]` | Solid, axis-aligned rectangles. |
| `spikes` | `[[left_x, width, surface], ...]` | 24 px high, surface `1` floor or `-1` ceiling. Minimum width 25. |
| `checkpoints` | `[[center_x, gravity], ...]` | Flag on that surface and safe respawn at the matching x and gravity. |
| `hazards` | `[[x, top_y, bottom_y, period_seconds, phase, radius], ...]` | Vertical patrol. Phase is a cycle fraction, normally 0–1; period is a full out-and-back cycle. |
| `switches` | `[["A", center_x, surface], ...]` | Touch to activate permanently until restart. IDs are local to a room. |
| `gates` | `[[left_x, ["A", "B"]], ...]` | 16 px wide, full-height gate. Every listed switch must be active. |

Use empty arrays for absent mechanics. Do not remove required fields. The catalog validates shapes, IDs and switch references; the author must still keep geometry inside the room, avoid spawn overlap, and provide a safe, reachable route. Gates must not block access to their own required switches.

Example of a new easy room (save as a separate JSON file):

```json
{
  "id": "new_perspective",
  "title": "New Perspective",
  "difficulty": "11 / PRACTICE",
  "hint": "Cross above the spikes and reach the ceiling exit.",
  "spawn": [130, 578, 1],
  "exit": [1020, 160, -1],
  "walls": [],
  "spikes": [[350, 200, 1]],
  "checkpoints": [[750, -1]],
  "hazards": [],
  "switches": [],
  "gates": []
}
```

This is a schema example, not the proposed difficulty for room 11. Build the actual next chapter on the progression described in `DESIGN.md`.

## Safe layout rules

- A flip needs enough horizontal space for the 26 px player and braking distance (about 18 px at full speed).
- Checkpoints must be clear on their own surface; test respawning while the nearest patrol approaches.
- Avoid putting switches/checkpoints in a hazard's reach. Switch progress survives death, but it should be earned fairly.
- Test each direction if the room expects backtracking. Current route tests cover the intended forward route.
- UI counts and selection scroll automatically; advanced new mechanics need their own behavior and tests.
- JSON files must be included in future Godot exports: add `*.json` to the export preset's non-resource include filter. No export preset/build is supplied yet.
