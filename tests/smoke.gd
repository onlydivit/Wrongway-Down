extends SceneTree

var room: Node2D
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
	else:
		print("PASS: ", message)

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func flip() -> void:
	Input.action_press("flip")
	await frames(1)
	Input.action_release("flip")
	await frames(1)

func move_to(target: float) -> void:
	var action := "move_right" if target > room.player.position.x else "move_left"
	Input.action_press(action)
	for i in range(300):
		await frames(1)
		if (action == "move_right" and room.player.position.x >= target) or (action == "move_left" and room.player.position.x <= target):
			break
	Input.action_release(action)
	await frames(12)

func walk_into_spikes(action: String) -> void:
	Input.action_press(action)
	for i in range(180):
		var before: Vector2 = room.player.position
		await frames(1)
		if absf(room.player.position.x - before.x) > 50:
			break
	Input.action_release(action)
	await frames(10)

func _run() -> void:
	room = load("res://scenes/test_room.tscn").instantiate()
	root.add_child(room)
	await frames(2)
	check(paused and room.state == "menu", "Main menu pauses gameplay")
	room._start()
	await frames(12)
	check(room.player.is_on_floor(), "Player settles on floor")
	await flip()
	check(room.player.gravity_direction == -1, "Grounded flip reverses gravity")
	await flip()
	check(room.player.gravity_direction == -1, "Airborne flip rejected")
	await frames(70)
	check(room.player.is_on_floor() and room.player.position.y < 180, "Ceiling is a valid support surface")
	await move_to(550)
	await flip()
	await frames(70)
	check(room.checkpoint.active, "Intended route activates checkpoint")
	check(room.player.gravity_direction == 1 and room.player.is_on_floor(), "Return to floor succeeds")
	await walk_into_spikes("move_left")
	await frames(20)
	check(room.player.position.x > 500 and room.player.gravity_direction == 1, "Spikes restore checkpoint position and gravity")
	room._show_menu("paused")
	var at: Vector2 = room.player.position
	await frames(10)
	check(room.player.position == at and paused, "Pause freezes player")
	room._resume()
	await move_to(1020)
	await frames(5)
	check(room.state == "complete" and paused, "Exit completes room")
	room._start()
	await frames(10)
	check(not room.checkpoint.active and room.player.position.x < 200 and not paused, "Replay clears checkpoint and resets spawn")
	await walk_into_spikes("move_right")
	await frames(10)
	check(room.player.position.x < 200 and room.player.gravity_direction == 1, "Death before checkpoint restores initial spawn")
	Input.action_press("move_left")
	await frames(60)
	Input.action_release("move_left")
	check(room.player.position.x >= 52, "Left wall blocks movement")
	await flip()
	await frames(75)
	check(room.player.is_on_floor() and room.player.position.y < 180, "Flip at wall corner does not trap player")
	room._start()
	await frames(5)
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://tests/room-preview.png")
	print("SMOKE RESULT: ", failures, " failures")
	quit(0 if failures == 0 else 1)
