# First playable milestone

**Target:** desktop, Godot 4.6, GDScript. **Feel:** readable, responsive, forgiving. **Core rule:** reverse gravity only while touching the current supporting surface. No jumping. Keep this rule until playtesting supplies a reason to change it.

## Route

Start on the lower left. Flip before the floor spikes at x340–490. Move across them on the ceiling, stopping near x550. Flip back down before the ceiling spikes at x650–800. Land at the checkpoint, then walk right to the exit. The wall-to-wall room is sealed and has no moving hazards in this milestone.

The player is 26 × 34 pixels; speed is 270 pixels/second, gravity is 1500 pixels/second², and terminal falling speed is 760 pixels/second. The checkpoint stores position and gravity direction together; this room's only checkpoint is on the floor. Spike hitboxes are slightly inset from their artwork.

## Planned campaign

1. First Flip: teach the surfaces and exit.
2. Safe Landing: deliberate spike landings.
3. Narrow Passage: staggered platforms and walls.
4. Timing: moving hazards.
5. The Gate: switch and door, once implemented.
6. Final Test: combine established mechanics.

## Human playtest checklist

- Can a new player identify movement, flip restriction, spikes, checkpoint and exit without verbal help?
- Finish the route at 30, 60 and 144 rendering FPS. Compare physics behavior.
- Hold movement against walls; flip at both corners and near spike edges. Confirm no sticking or tunneling.
- Attempt repeated midair flips. Only the next new press after landing should work.
- Die before and after the checkpoint; verify position, gravity, and zero carryover velocity.
- Pause during a fall. Resume without teleporting or losing motion.
- Restart while paused and after completion. Verify checkpoint resets.
- Finish, replay, return to menu, and begin again using both mouse and keyboard.
- Before release, install matching export templates, export Windows, and run outside the editor.

Record observed issues and rule changes here after actual playtests. Automated route checks do not replace a new-player playtest.
