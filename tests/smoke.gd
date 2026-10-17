extends SceneTree

const ROUTES := [
	[240], [240], [230, 550], [180, 430, 680], [180, 450, 700],
	[180, 450, 680], [180, 450, 680], [175, 380, 570, 760],
	[175, 380, 570, 760], [180, 410, 610, 810]
]
var game: Node2D
var failures := 0
var checks := 0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame

func flip() -> void:
	Input.action_press("flip")
	await frames(1)
	Input.action_release("flip")
	await frames(1)

func settle() -> void:
	await frames(4)
	for i in range(150):
		if game.player.is_on_floor():
			break
		await frames(1)

func _safe_to_advance() -> bool:
	# Wait before crossing patrol lines. Check the coming crossing interval.
	# No teleporting is used on completion routes.
	for hazard in game.level.hazards:
		var gap: float = hazard.position.x - game.player.position.x
		if gap < 45 or gap > 110:
			continue
		for tick in range(10):
			var future: float = hazard.elapsed + tick * 0.1
			var point: Vector2 = hazard.start.lerp(hazard.finish, (1 - cos(TAU * (future / hazard.period + hazard.phase))) / 2)
			if absf(point.y - game.player.position.y) < 85:
				return false
	return true

func move_to(target: float) -> bool:
	for i in range(1500):
		if game.state != "playing" or game.player.position.x >= target:
			break
		if _safe_to_advance():
			Input.action_press("move_right", clampf((target - game.player.position.x) / 60.0, 0.2, 1.0))
		else:
			Input.action_release("move_right")
		await frames(1)
	Input.action_release("move_right")
	await frames(12)
	return game.player.position.x >= target or game.state in ["complete", "ending"]

func _run() -> void:
	game = load("res://scenes/test_room.tscn").instantiate()
	game.progress.save_path = "user://campaign-test.cfg"
	root.add_child(game)
	await frames(2)
	game.progress.completed.clear()
	check(game.catalog.levels.size() == 10, "Ten campaign levels load")
	check(paused and game.state == "menu", "Menu pauses the world")
	check(not game.progress.is_unlocked(1, game.catalog.levels), "New saves lock later levels")
	game.start_level(1)
	check(game.state == "menu", "Locked level cannot be started directly")
	for index in range(10):
		game.start_level(index)
		await settle()
		check(game.player.is_on_floor(), "Level %02d spawn is grounded" % (index + 1))
		var initial_deaths: int = game.deaths
		game.level.danger.connect(func():
			print("CONTACT level=", game.level_index + 1, " at=", game.player.position, " gravity=", game.player.gravity_direction)
		)
		for x in ROUTES[index]:
			var reached := await move_to(float(x))
			if not reached:
				check(false, "Route reached x=%s in level %s" % [x, index + 1])
				break
			await flip()
			if index == 0:
				var direction: int = game.player.gravity_direction
				await flip()
				check(game.player.gravity_direction == direction, "Midair flip rejected")
			await settle()
		await move_to(1060)
		await frames(3)
		check(game.state == ("ending" if index == 9 else "complete"), "Level %02d completed by movement and flips" % (index + 1))
		check(game.deaths == initial_deaths, "Level %02d route is survivable without deaths" % (index + 1))
		check(game.catalog.levels[index].id in game.progress.completed, "Level %02d completion saved" % (index + 1))
		if game.state not in ["complete", "ending"]:
			break
	var saved := CampaignProgress.new()
	saved.save_path = game.progress.save_path
	saved.load_progress()
	check(saved.completed.size() == 10, "All completion IDs survive save/reload")
	var expanded: Array[Dictionary] = game.catalog.levels.duplicate(true)
	expanded.append({"id": "future_room"})
	check(saved.is_unlocked(10, expanded) and saved.continue_index(expanded) == 10, "Appending level 11 unlocks it for returning players")
	# Isolated collision/state checks; completion routes above use real inputs.
	game.start_level(8)
	await settle()
	check(not game.level.gates[0].open, "Gate initially closed")
	game.player.respawn(Vector2(380, 578), 1)
	await frames(10)
	check(game.level.switches.A.active and not game.level.gates[0].open, "One of two switches does not open gate")
	game.player.respawn(Vector2(760, 578), 1)
	await frames(10)
	check(game.level.gates[0].open and game.level.gates[0].body.collision_layer == 0, "Both switches disable gate collision")
	game.player.respawn(Vector2(570, 182), -1)
	await frames(10)
	check(game.spawn_gravity == -1 and game.level.checkpoint != null, "Ceiling checkpoint stores upward gravity")
	game.player.position = Vector2(470, 177)
	await frames(12)
	check(game.deaths > 0 and game.player.gravity_direction == -1 and absf(game.player.position.x - 570) < 1, "Spike death restores ceiling checkpoint")
	check(game.level.gates[0].open, "Switch activation survives checkpoint death")
	game._show_menu("paused")
	var before: Vector2 = game.player.position
	var hazard_before: Vector2 = game.level.hazards[0].position
	await frames(10)
	check(game.player.position == before and game.level.hazards[0].position == hazard_before, "Pause freezes player and patrols")
	game.start_level(8)
	await settle()
	check(game.level.checkpoint == null and not game.level.gates[0].open, "Restart resets checkpoints and switches")
	var old_deaths: int = game.deaths
	game.player.position = game.level.hazards[0].position
	await frames(10)
	check(game.deaths > old_deaths, "Moving hazard contact causes death")
	game.start_level(0)
	await settle()
	Input.action_press("move_left")
	await frames(60)
	Input.action_release("move_left")
	await flip()
	await settle()
	check(game.player.position.x >= 52 and game.player.is_on_floor() and game.player.gravity_direction == -1, "Wall corner flip remains safe")
	if "--capture" in OS.get_cmdline_user_args():
		for index in [0, 4, 9]:
			game.start_level(index)
			await frames(6)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://tests/level-%02d-preview.png" % (index + 1))
		game._show_menu("select")
		await frames(3)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/level-select-preview.png")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.progress.save_path))
	print("CAMPAIGN RESULT: %d checks, %d failures" % [checks, failures])
	game.queue_free()
	paused = false
	await process_frame
	# Let the audio thread release its last playback; fixed-fps tests can run
	# much faster than wall time, so simulated timers are unsuitable here.
	var shutdown_deadline := Time.get_ticks_msec() + 100
	while Time.get_ticks_msec() < shutdown_deadline:
		await process_frame
	quit(0 if failures == 0 else 1)
