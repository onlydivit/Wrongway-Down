extends Node2D

const PLAYER_SCENE = preload("res://scenes/player.tscn")
const LEVEL_SCRIPT = preload("res://scripts/level.gd")
const MENU_SCRIPT = preload("res://ui/campaign_menu.gd")
const AUDIO_SCRIPT = preload("res://scripts/game_audio.gd")
const INK := Color("e3edf6")
const MUTED := Color("7e93ae")
const MINT := Color("85f5d5")
var catalog := LevelCatalog.new()
var progress := CampaignProgress.new()
var player: GravityPlayer
var level: CampaignLevel
var menu: CampaignMenu
var sound: GameAudio
var level_index := 0
var state := "menu"
var spawn_position := Vector2.ZERO
var spawn_gravity := 1
var notice := ""
var notice_time := 0.0
var deaths := 0
var effects: Array[Dictionary] = []
var font: Font
var save_warning := ""
var submenu_return := "menu"
var shop_message := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	font = ThemeDB.fallback_font
	_bind("move_left", [KEY_A, KEY_LEFT])
	_bind("move_right", [KEY_D, KEY_RIGHT])
	_bind("flip", [KEY_SPACE])
	_bind("restart", [KEY_R])
	_bind("pause_game", [KEY_ESCAPE])
	menu = MENU_SCRIPT.new()
	add_child(menu)
	sound = AUDIO_SCRIPT.new()
	add_child(sound)
	# Tests use a separate save and never overwrite the player's campaign.
	if "--test-save" in OS.get_cmdline_user_args():
		progress.save_path = "user://campaign-test.cfg"
	progress.load_progress()
	if not catalog.load_campaign():
		state = "error"
		get_tree().paused = true
		menu.show_page("LEVEL DATA ERROR", catalog.error)
		menu.add_button("Quit", func(): get_tree().quit()).grab_focus()
		return
	if progress.migrate_rewards(catalog.levels) != OK:
		save_warning = "Could not save migrated Gravitos. Progress is available this session."
	sound.apply_settings(progress.settings)
	_show_menu("menu")

func _bind(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)

func start_level(index: int) -> void:
	if not progress.is_unlocked(index, catalog.levels):
		return
	get_tree().paused = true
	state = "loading"
	if is_instance_valid(player):
		remove_child(player)
		player.queue_free()
	if is_instance_valid(level):
		remove_child(level)
		level.queue_free()
	level_index = index
	var data := catalog.levels[index]
	spawn_position = Vector2(data.spawn[0], data.spawn[1])
	spawn_gravity = int(data.spawn[2])
	effects.clear()
	notice_time = 0
	deaths = 0
	level = LEVEL_SCRIPT.new()
	level.data = data
	level.danger.connect(_die)
	level.completed.connect(_finish)
	level.checkpoint_changed.connect(_checkpoint)
	level.switch_changed.connect(_switch)
	add_child(level)
	player = PLAYER_SCENE.instantiate()
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(player)
	player.alien_id = progress.equipped
	player.respawn(spawn_position, spawn_gravity)
	player.flipped.connect(func():
		_burst(player.position, MINT)
		sound.tone(560, 0.10)
	)
	player.landed.connect(func(): _burst(player.position + Vector2(0, 17 * player.gravity_direction), MINT))
	_resume()

func _die() -> void:
	if state != "playing" or not player.enabled:
		return
	player.enabled = false
	deaths += 1
	_burst(player.position, Color("f67f91"))
	sound.tone(125, 0.18)
	_respawn.call_deferred(player)

func _respawn(victim: GravityPlayer) -> void:
	# A queued contact from an old level must never move the new player.
	if is_instance_valid(victim) and victim == player and state in ["playing", "paused"]:
		player.respawn(spawn_position, spawn_gravity)
		_notify("CHECKPOINT RESTORED" if level.checkpoint != null else "TRY AGAIN - LOOK FOR A SAFE SURFACE")

func _checkpoint(at: Vector2, direction: int) -> void:
	if state != "playing" or not player.enabled:
		return
	spawn_position = at
	spawn_gravity = direction
	_notify("CHECKPOINT SAVED / " + ("CEILING" if direction == -1 else "FLOOR"))
	sound.tone(880, 0.16)
	_burst(at, Color("e4ba70"))

func _switch(remaining: int) -> void:
	_notify("GATE OPEN" if remaining == 0 else "SWITCH ON / %d LEFT" % remaining)
	sound.tone(740, 0.14)

func _finish() -> void:
	if state != "playing" or not player.enabled:
		return
	state = "finishing"
	player.enabled = false
	sound.tone(1046, 0.26)
	save_warning = ""
	if progress.mark_complete(catalog.levels[level_index].id, int(catalog.levels[level_index].get("reward", 100))) != OK:
		save_warning = "Progress could not be saved to disk. Unlocks work this session."
	_show_menu.call_deferred("ending" if level_index == catalog.levels.size() - 1 else "complete")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart") and state in ["playing", "paused", "complete", "ending"]:
		start_level(level_index)
	elif event.is_action_pressed("pause_game"):
		if state == "playing":
			_show_menu("paused")
		elif state == "paused":
			_resume()
		elif state == "select":
			_show_menu("menu")
		elif state in ["settings", "shop"]:
			_show_menu(submenu_return)

func _resume() -> void:
	state = "playing"
	menu.hide_page()
	get_tree().paused = false

func _show_menu(next_state: String) -> void:
	state = next_state
	get_tree().paused = true
	var first: Button
	match state:
		"menu":
			menu.show_page("WRONGWAY DOWN", "%d ROOMS / %d GRAVITOS\nFirst clears pay full rewards. Replays pay 10%%." % [catalog.levels.size(), progress.gravitos])
			first = menu.add_button("Play" if progress.completed.is_empty() else "Continue", func(): start_level(progress.continue_index(catalog.levels)))
			menu.add_button("Choose level", func(): _show_menu("select"))
			menu.add_button("Alien shop", func(): _open_submenu("shop"))
			menu.add_button("Sound settings", func(): _open_submenu("settings"))
			menu.add_button("Quit", func(): get_tree().quit())
		"select":
			menu.show_page("CHOOSE YOUR ROOM", "%d Gravitos / Clear a room to unlock the next.\nRewards show your next clear payout." % progress.gravitos)
			var grid := menu.add_level_grid()
			for index in range(catalog.levels.size()):
				var data := catalog.levels[index]
				var unlocked := progress.is_unlocked(index, catalog.levels)
				var prefix := "DONE " if data.id in progress.completed else ("" if unlocked else "LOCK ")
				var reward := int(data.get("reward", 100))
				if data.id in progress.rewarded:
					reward = int(reward / 10)
				var button := menu.add_button("%s%02d  %s\n+%d Gravitos" % [prefix, index + 1, data.title, reward], start_level.bind(index), not unlocked, grid)
				button.add_theme_font_size_override("font_size", 14)
				button.custom_minimum_size.y = 56
				if first == null and unlocked:
					first = button
			menu.add_button("Main menu", func(): _show_menu("menu"))
		"paused":
			menu.show_page("TAKE A BREATH", "%02d / %s" % [level_index + 1, catalog.levels[level_index].title])
			first = menu.add_button("Resume", _resume)
			menu.add_button("Restart level", start_level.bind(level_index))
			menu.add_button("Alien shop", func(): _open_submenu("shop"))
			menu.add_button("Sound settings", func(): _open_submenu("settings"))
			menu.add_button("Main menu", func(): _show_menu("menu"))
		"settings":
			menu.show_page("SOUND SETTINGS", "Changes apply immediately and are saved.\nArrow keys adjust a focused slider.")
			menu.add_slider("Master", progress.settings.master, _volume_changed.bind("master")).grab_focus()
			menu.add_slider("Music", progress.settings.music, _volume_changed.bind("music"))
			menu.add_slider("Effects", progress.settings.sfx, _volume_changed.bind("sfx"))
			var mute := CheckButton.new()
			mute.text = "Mute all audio"
			mute.button_pressed = progress.settings.muted
			mute.toggled.connect(_mute_changed)
			menu.choices.add_child(mute)
			menu.add_button("Play test sound", func(): sound.tone(560, 0.2))
			menu.add_button("Back", func(): _show_menu(submenu_return))
		"shop":
			menu.show_page("ALIEN SHOP", "%d GRAVITOS / Cosmetic aliens; identical movement.\n%s" % [progress.gravitos, shop_message if not shop_message.is_empty() else "Buy once, equip any time."])
			for alien in AlienRoster.ALIENS:
				var owned: bool = alien.id in progress.owned
				var selected: bool = alien.id == progress.equipped
				var text: String = "Equipped" if selected else ("Equip" if owned else "Unlock - %d Gravitos" % alien.price)
				var button := menu.add_alien_card(alien, text, _purchase.bind(alien.id), selected or (not owned and progress.gravitos < int(alien.price)))
				if first == null and not button.disabled:
					first = button
			var back := menu.add_button("Back", func(): _show_menu(submenu_return))
			if first == null:
				first = back
		"complete", "ending":
			var ending := state == "ending"
			var body: String = "All %d rooms complete. Ready for the next chapter." % catalog.levels.size() if ending else "Next: " + catalog.levels[level_index + 1].title
			body += "\n+%d Gravitos (%s) / Balance: %d" % [progress.last_reward, "first clear" if progress.last_first_clear else "replay: 10%", progress.gravitos]
			if not save_warning.is_empty():
				body = save_warning
			menu.show_page("CHAPTER COMPLETE" if ending else "ROOM COMPLETE", body)
			if not ending:
				first = menu.add_button("Continue", start_level.bind(level_index + 1))
			var replay := menu.add_button("Replay level", start_level.bind(level_index))
			if first == null:
				first = replay
			menu.add_button("Choose level", func(): _show_menu("select"))
			menu.add_button("Alien shop", func(): _open_submenu("shop"))
			menu.add_button("Main menu", func(): _show_menu("menu"))
	if first != null:
		first.grab_focus()

func _open_submenu(page: String) -> void:
	submenu_return = state
	shop_message = ""
	_show_menu(page)

func _volume_changed(value: float, key: String) -> void:
	progress.settings[key] = value
	_save_audio()

func _mute_changed(muted: bool) -> void:
	progress.settings.muted = muted
	_save_audio()

func _save_audio() -> void:
	sound.apply_settings(progress.settings)
	if progress.save_progress() != OK:
		menu.description.text = "Audio changed for this session, but settings could not be saved."

func _purchase(id: String) -> void:
	var scroll_position := menu.scroll.scroll_vertical
	shop_message = progress.buy_or_equip(id)
	if shop_message.is_empty():
		shop_message = AlienRoster.get_alien(id).name + " equipped!"
		if is_instance_valid(player):
			player.alien_id = progress.equipped
			player.queue_redraw()
	_show_menu("shop")
	menu.scroll.set_deferred("scroll_vertical", scroll_position)

func _process(delta: float) -> void:
	if state == "playing":
		notice_time = maxf(0, notice_time - delta)
		for effect in effects:
			effect.life -= delta
		effects = effects.filter(func(effect): return effect.life > 0)
	queue_redraw()

func _notify(message: String) -> void:
	notice = message
	notice_time = 2.6

func _burst(at: Vector2, color: Color) -> void:
	effects.append({"position": at, "color": color, "life": 0.45})

func _text(at: Vector2, text: String, size: int, color: Color) -> void:
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw() -> void:
	if font == null:
		return
	draw_rect(Rect2(0, 0, 1152, 720), Color("080f1d"))
	for x in range(48, 1120, 32):
		for y in range(176, 600, 32):
			draw_circle(Vector2(x, y), 1, Color("1b2a3e"))
	_text(Vector2(40, 55), "WRONGWAY DOWN", 30, INK)
	_text(Vector2(355, 54), "/   %d GRAVITOS" % progress.gravitos, 14, Color("e4ba70"))
	draw_line(Vector2(40, 88), Vector2(1112, 88), Color("25354a"))
	if not catalog.levels.is_empty():
		var data := catalog.levels[level_index]
		_text(Vector2(710, 43), "%02d / %02d   %s" % [level_index + 1, catalog.levels.size(), data.title.to_upper()], 20, INK)
		_text(Vector2(710, 68), data.difficulty, 12, MUTED)
		_text(Vector2(40, 662), data.hint, 16, MINT)
		_text(Vector2(data.exit[0], 252 if data.exit[2] == -1 else 518), "EXIT", 13, MINT)
		_text(Vector2(58, 111), "NO JUMP / FLIP FROM A SURFACE", 12, MUTED)
	if is_instance_valid(player):
		_text(Vector2(390, 111), "GRAVITY " + ("UP" if player.gravity_direction == -1 else "DOWN"), 13, MINT)
		_text(Vector2(560, 111), "CHECKPOINT " + ("SAVED" if level.checkpoint != null else "START"), 12, Color("e4ba70"))
	_text(Vector2(40, 701), "A / D  or  LEFT / RIGHT   Move      SPACE   Flip", 15, INK)
	_text(Vector2(820, 701), "R  Restart       ESC  Pause", 15, MUTED)
	if notice_time > 0:
		var width := font.get_string_size(notice, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
		_text(Vector2((1152 - width) / 2, 385), notice, 17, MINT)
	for effect in effects:
		var fraction: float = effect.life / 0.45
		var color: Color = effect.color
		color.a = fraction
		draw_arc(effect.position, 10 + (1 - fraction) * 35, 0, TAU, 32, color, 2)
