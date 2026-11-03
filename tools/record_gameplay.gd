extends SceneTree

# Run with Godot Movie Maker (--write-movie) at a fixed 60 FPS. These are
# the same real-input routes used by the foundation gameplay smoke test.
const ROUTES := [[240], [240], [230, 550]]
const EXPANSION_ROUTES := [
	[175, 380, 570, 760], [180, 450, 680], [180, 410, 610, 810],
	[165, 355, 555, 755], [160, 335, 505, 675, 845], [180, 400, 605, 810]
]
var game: Node2D
var recording_save := ""
var recorded_frames := 0
var harder_mode := false
var recording_levels: Array[int] = [0, 1, 2]

func _initialize() -> void:
	_run.call_deferred()

func frames(count: int) -> void:
	for tick in range(count):
		await physics_frame
		recorded_frames += 1

func settle() -> bool:
	await frames(4)
	for tick in range(150):
		if game.player.is_on_floor():
			return true
		await frames(1)
	return false

func flip() -> bool:
	# Render and physics ticks do not necessarily share an input flush. Keep
	# the press alive until the actual player acknowledges the gravity flip.
	Input.action_release("flip")
	await frames(2)
	var previous_direction: int = game.player.gravity_direction
	Input.action_press("flip")
	var accepted := false
	for tick in range(8):
		await frames(1)
		if game.player.gravity_direction != previous_direction:
			accepted = true
			break
	Input.action_release("flip")
	await frames(2)
	print("RECORDING FLIP room=%d accepted=%s position=%s gravity=%d" % [game.level_index + 1, accepted, game.player.position, game.player.gravity_direction])
	return accepted

func move_to(target: float) -> bool:
	var waiting_ticks := 0
	for tick in range(900):
		if game.state != "playing" or game.player.position.x >= target:
			break
		if not harder_mode or _safe_to_advance():
			Input.action_press("move_right", clampf((target - game.player.position.x) / 60.0, 0.2, 1.0))
		else:
			Input.action_release("move_right")
			waiting_ticks += 1
		await frames(1)
	Input.action_release("move_right")
	await frames(12)
	if waiting_ticks > 0:
		print("RECORDING WAIT room=%d target=%.0f ticks=%d" % [game.level_index + 1, target, waiting_ticks])
	return game.player.position.x >= target or game.state in ["complete", "ending"]

func _safe_to_advance() -> bool:
	# Stop well outside the player's braking distance; after committing to
	# a crossing, keep moving until clear instead of braking in the danger.
	for hazard in game.level.hazards:
		var gap: float = hazard.position.x - game.player.position.x
		if gap < 70.0 or gap > 120.0:
			continue
		for sample in range(13):
			var future: float = hazard.elapsed + sample * 0.075
			var point: Vector2 = hazard.start.lerp(hazard.finish, (1.0 - cos(TAU * (future / hazard.period + hazard.phase))) / 2.0)
			if absf(point.y - game.player.position.y) < 90.0:
				return false
	for pulse in game.level.pulses:
		var gap: float = pulse.position.x - game.player.position.x
		if gap < 70.0 or gap > 120.0:
			continue
		for sample in range(13):
			if pulse.stage_at(pulse.elapsed + sample * 0.075) != 0:
				return false
	return true

func _route_for(index: int) -> Array:
	if index < ROUTES.size():
		return ROUTES[index]
	var offset := index - 10
	var shift: int = [0, 5, -5, 8, -8][int(offset / 6)]
	var route: Array = []
	for target in EXPANSION_ROUTES[offset % EXPANSION_ROUTES.size()]:
		route.append(target + shift)
	return route

func _select_levels() -> bool:
	var arguments := OS.get_cmdline_user_args()
	harder_mode = "--harder" in arguments
	if harder_mode:
		recording_levels = [30, 39]
	for argument in arguments:
		if not argument.begins_with("--levels="):
			continue
		recording_levels.clear()
		for number in argument.trim_prefix("--levels=").split(","):
			if not number.is_valid_int():
				return false
			var index := int(number) - 1
			if index < 0 or index >= 40 or (index >= ROUTES.size() and index < 10):
				return false
			recording_levels.append(index)
			harder_mode = harder_mode or index >= 10
	return not recording_levels.is_empty()

func _run() -> void:
	if not _select_levels():
		push_error("Recording levels must be 1–3 or 11–40; use --harder or --levels=31,40")
		quit(1)
		return
	# Each recording has its own profile and never writes campaign.cfg.
	recording_save = "user://gameplay-recording-%d.cfg" % OS.get_process_id()
	game = load("res://scenes/test_room.tscn").instantiate()
	game.progress.save_path = recording_save
	root.add_child(game)
	# Only this disposable profile is pre-unlocked for later-room showcases.
	# Every selected room is still traversed through normal player inputs.
	if harder_mode:
		for index in recording_levels:
			if index > 0 and not game.catalog.levels[index - 1].id in game.progress.completed:
				game.progress.completed.append(game.catalog.levels[index - 1].id)
	await frames(60 if harder_mode else 90)
	for index in recording_levels:
		game.start_level(index)
		game.level.danger.connect(func():
			print("RECORDING DANGER room=%d frame=%d position=%s gravity=%d" % [game.level_index + 1, recorded_frames, game.player.position, game.player.gravity_direction])
		)
		if not await settle():
			push_error("Recording spawn did not settle in room %d" % (index + 1))
			await finish_recording(false)
			return
		await frames(24)
		for target in _route_for(index):
			if not await move_to(float(target)):
				await finish_recording(false)
				return
			if not await flip() or not await settle():
				push_error("Recording flip failed in room %d" % (index + 1))
				await finish_recording(false)
				return
		await move_to(1060)
		await frames(60)
		print("RECORDING ROOM room=%d state=%s deaths=%d position=%s gravity=%d" % [index + 1, game.state, game.deaths, game.player.position, game.player.gravity_direction])
		var expected_state := "ending" if index == game.catalog.levels.size() - 1 else "complete"
		if game.state != expected_state or game.deaths > 0:
			push_error("Recording route failed in room %d" % (index + 1))
			await finish_recording(false)
			return
	await frames(30)
	await finish_recording(true)

func finish_recording(success: bool) -> void:
	Input.action_release("move_right")
	Input.action_release("flip")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(recording_save))
	print("Gameplay recording: %d frames (%.1f seconds); success=%s" % [recorded_frames, recorded_frames / 60.0, success])
	game.queue_free()
	paused = false
	await process_frame
	quit(0 if success else 1)
