extends SceneTree

var game: Node2D
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures += 1
		push_error(message)

func frames(count: int) -> void:
	for index in range(count):
		await physics_frame

func _run() -> void:
	var test_save := "user://campaign-expansion-test.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_save))
	game = load("res://scenes/test_room.tscn").instantiate()
	game.progress.save_path = test_save
	root.add_child(game)
	await frames(3)
	check(game.catalog.levels.size() == 40, "Forty campaign levels load")
	check(game.catalog.levels[10].pulses.size() == 1, "Reaction chapter adds pulse barriers")
	check(game.catalog.levels[20].pulses.size() == 2, "Pulse chapter combines two barriers")
	check(game.catalog.levels[39].reward == 490, "Rewards scale through level 40")
	check(game.progress.gravitos == 0 and game.progress.equipped == "sprout", "Fresh wallet and starter alien")
	game.progress.completed.clear()
	game.progress.completed.append(game.catalog.levels[0].id)
	check(game.progress.migrate_rewards(game.catalog.levels) == OK and game.progress.gravitos == 100, "Existing completed levels migrate to first-clear reward")
	check(game.progress.mark_complete("level_test", 200) == OK and game.progress.last_reward == 200, "First clear grants full Gravitos")
	check(game.progress.mark_complete("level_test", 200) == OK and game.progress.last_reward == 20, "Replay grants one-tenth Gravitos")
	game.progress.gravitos = 199
	var before: int = game.progress.gravitos
	check(not game.progress.buy_or_equip("orbix").is_empty() and game.progress.gravitos == before, "Shop rejects unaffordable alien without spending")
	game.progress.gravitos = 250
	check(game.progress.buy_or_equip("orbix").is_empty() and "orbix" in game.progress.owned and game.progress.equipped == "orbix" and game.progress.gravitos == 50, "Shop unlocks and equips alien")
	game.progress.settings.master = 0.25
	game.progress.settings.music = 0.4
	game.progress.settings.sfx = 0.6
	game.progress.settings.muted = true
	check(game.progress.save_progress() == OK, "Audio settings save")
	var loaded := CampaignProgress.new()
	loaded.save_path = game.progress.save_path
	loaded.load_progress()
	check(loaded.gravitos == 50 and loaded.equipped == "orbix" and loaded.settings.muted and is_equal_approx(loaded.settings.music, 0.4), "Wallet, alien, and audio settings reload")
	game.progress.completed.clear()
	game.start_level(10)
	check(game.state == "menu", "Locked reaction level remains protected")
	for index in range(10):
		game.progress.completed.append(game.catalog.levels[index].id)
	game.start_level(10)
	await frames(8)
	check(game.state == "playing" and game.level.pulses.size() == 1 and game.player.alien_id == "orbix", "Unlocked reaction level builds pulse and equipped alien")
	var pulse: PulseBarrier = game.level.pulses[0]
	pulse.elapsed = pulse.safe_time + pulse.warning_time + 0.05
	await frames(2)
	check(pulse.stage == 2, "Pulse reaches STOP state")
	game.player.position = Vector2(pulse.position.x + 8, 380)
	await frames(3)
	check(game.deaths > 0, "Active pulse barrier causes respawn")
	game._open_submenu("settings")
	check(game.state == "settings" and paused, "Sound settings open from game flow")
	game._open_submenu("shop")
	check(game.state == "shop", "Alien shop opens from game flow")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(game.progress.save_path))
	game.queue_free()
	await process_frame
	print("EXPANSION RESULT: %d failures" % failures)
	quit(0 if failures == 0 else 1)
