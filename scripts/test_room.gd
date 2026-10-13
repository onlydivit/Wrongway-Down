extends Node2D

const PLAYER_SCENE = preload("res://scenes/player.tscn")
const OBJECT_SCENE = preload("res://scenes/object.tscn")
const START := Vector2(130, 578)
const INK := Color("e3edf6")
const MUTED := Color("7e93ae")
const MINT := Color("85f5d5")
var player: GravityPlayer
var checkpoint: RoomObject
var spawn_position := START
var spawn_gravity := 1
var state := "menu"
var notice := ""
var notice_time := 0.0
var elapsed := 0.0
var overlay: Control
var menu_title: Label
var menu_description: Label
var buttons: VBoxContainer
var sound: AudioStreamPlayer
var effects: Array[Dictionary] = []
var font: Font

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	font = ThemeDB.fallback_font
	_bind("move_left", [KEY_A, KEY_LEFT])
	_bind("move_right", [KEY_D, KEY_RIGHT])
	_bind("flip", [KEY_SPACE])
	_bind("restart", [KEY_R])
	_bind("pause_game", [KEY_ESCAPE])
	_wall(Rect2(40, 120, 1072, 40))
	_wall(Rect2(40, 600, 1072, 40))
	_wall(Rect2(24, 120, 16, 520))
	_wall(Rect2(1112, 120, 16, 520))
	_object(RoomObject.Kind.SPIKES, Vector2(340, 576), Vector2(150, 24))
	_object(RoomObject.Kind.SPIKES, Vector2(650, 160), Vector2(150, 24), true)
	checkpoint = _object(RoomObject.Kind.CHECKPOINT, Vector2(553, 550), Vector2(36, 50))
	_object(RoomObject.Kind.EXIT, Vector2(1020, 532), Vector2(60, 68))
	player = PLAYER_SCENE.instantiate()
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(player)
	player.position = START
	player.flipped.connect(func():
		_burst(player.position, MINT)
		_tone(560, 0.10)
	)
	player.landed.connect(func(): _burst(player.position + Vector2(0, 17 * player.gravity_direction), MINT))
	sound = AudioStreamPlayer.new()
	add_child(sound)
	_create_menu()
	_show_menu("menu")

func _bind(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)

func _wall(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rect.position
	body.collision_layer = 2
	body.collision_mask = 1
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	collision.position = rect.size / 2
	body.add_child(collision)
	add_child(body)

func _object(kind: RoomObject.Kind, at: Vector2, size: Vector2, ceiling := false) -> RoomObject:
	var object: RoomObject = OBJECT_SCENE.instantiate()
	object.kind = kind
	object.position = at
	object.object_size = size
	object.ceiling = ceiling
	object.process_mode = Node.PROCESS_MODE_PAUSABLE
	object.activated.connect(_on_object)
	add_child(object)
	return object

func _on_object(object: RoomObject) -> void:
	if state != "playing" or not player.enabled:
		return
	match object.kind:
		RoomObject.Kind.SPIKES:
			player.enabled = false
			_burst(player.position, Color("f67f91"))
			_tone(125, 0.18)
			_respawn.call_deferred()
		RoomObject.Kind.CHECKPOINT:
			if not object.active:
				object.active = true
				object.queue_redraw()
				spawn_position = Vector2(569, 578)
				spawn_gravity = 1
				_notify("CHECKPOINT SAVED")
				_burst(object.position + Vector2(12, 15), Color("e4ba70"))
				_tone(880, 0.16)
		RoomObject.Kind.EXIT:
			_tone(1046, 0.26)
			_show_menu.call_deferred("complete")

func _respawn() -> void:
	if state == "playing":
		player.respawn(spawn_position, spawn_gravity)
		_notify("BACK TO CHECKPOINT" if checkpoint.active else "TRY AGAIN • Pick a safe landing")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart") and state in ["playing", "paused", "complete"]:
		_start()
	elif event.is_action_pressed("pause_game"):
		if state == "playing":
			_show_menu("paused")
		elif state == "paused":
			_resume()

func _process(delta: float) -> void:
	if state == "playing":
		elapsed += delta
		notice_time = maxf(0, notice_time - delta)
		for effect in effects:
			effect["life"] -= delta
		effects = effects.filter(func(effect): return effect["life"] > 0)
	queue_redraw()

func _start() -> void:
	spawn_position = START
	spawn_gravity = 1
	checkpoint.active = false
	checkpoint.queue_redraw()
	effects.clear()
	notice_time = 0
	elapsed = 0
	_resume()
	player.respawn(START, 1)

func _resume() -> void:
	state = "playing"
	overlay.hide()
	get_tree().paused = false

func _notify(message: String) -> void:
	notice = message
	notice_time = 2.6

func _burst(at: Vector2, color: Color) -> void:
	effects.append({"position": at, "color": color, "life": 0.45})

func _tone(frequency: float, duration: float) -> void:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var count := int(duration * stream.mix_rate)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in range(count):
		var envelope := sin(PI * float(i) / count) * 0.15
		var sample := int(sin(TAU * frequency * float(i) / stream.mix_rate) * envelope * 32767)
		bytes.encode_s16(i * 2, sample)
	stream.data = bytes
	sound.stream = stream
	sound.play()

func _create_menu() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.016, 0.027, 0.05, 0.9)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	var panel := Panel.new()
	panel.position = Vector2(346, 205)
	panel.size = Vector2(460, 335)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("101e31")
	style.border_color = Color("30465b")
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	panel.add_theme_stylebox_override("panel", style)
	overlay.add_child(panel)
	menu_title = Label.new()
	menu_title.position = Vector2(378, 232)
	menu_title.size.x = 396
	menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_title.add_theme_font_size_override("font_size", 34)
	menu_title.add_theme_color_override("font_color", MINT)
	overlay.add_child(menu_title)
	menu_description = Label.new()
	menu_description.position = Vector2(368, 288)
	menu_description.size = Vector2(416, 62)
	menu_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_description.add_theme_font_size_override("font_size", 16)
	menu_description.add_theme_color_override("font_color", INK)
	overlay.add_child(menu_description)
	buttons = VBoxContainer.new()
	buttons.position = Vector2(412, 363)
	buttons.size.x = 328
	buttons.add_theme_constant_override("separation", 10)
	overlay.add_child(buttons)

func _button(title: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(328, 40)
	button.add_theme_font_size_override("font_size", 17)
	for item in ["normal", "hover", "pressed", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("254a56") if item in ["hover", "focus"] else Color("1a3347")
		style.border_color = MINT if item == "focus" else Color("3b6070")
		style.set_border_width_all(1)
		style.set_corner_radius_all(6)
		button.add_theme_stylebox_override(item, style)
	button.pressed.connect(callback)
	buttons.add_child(button)

func _show_menu(next_state: String) -> void:
	state = next_state
	get_tree().paused = true
	overlay.show()
	for child in buttons.get_children():
		buttons.remove_child(child)
		child.queue_free()
	match state:
		"menu":
			menu_title.text = "WRONGWAY DOWN"
			menu_description.text = "A small gravity experiment.\nTwo surfaces. One way forward."
			_button("Enter the lab", _start)
			_button("Quit", func(): get_tree().quit())
		"paused":
			menu_title.text = "TAKE A BREATH"
			menu_description.text = "The lab can wait."
			_button("Resume", _resume)
			_button("Restart room", _start)
			_button("Main menu", func(): _show_menu("menu"))
		"complete":
			menu_title.text = "TEST COMPLETE"
			menu_description.text = "You found your feet. On both sides.\nFirst playable room completed."
			_button("Replay room", _start)
			_button("Main menu", func(): _show_menu("menu"))
	buttons.get_child(0).grab_focus()

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
	_text(Vector2(355, 54), "/   GRAVITY LAB", 14, MUTED)
	_text(Vector2(880, 43), "01   /   FIRST FLIP", 19, INK)
	_text(Vector2(880, 68), "PROTOTYPE  •  TEST ROOM", 12, MUTED)
	draw_line(Vector2(40, 88), Vector2(1112, 88), Color("25354a"))
	for rect in [Rect2(40, 120, 1072, 40), Rect2(40, 600, 1072, 40)]:
		draw_rect(rect, Color("192b40"))
		for x in range(48, 1112, 32):
			draw_line(Vector2(x, rect.position.y + 10), Vector2(x + 18, rect.position.y + 28), Color("22394e"), 2)
	draw_rect(Rect2(24, 120, 16, 520), Color("192b40"))
	draw_rect(Rect2(1112, 120, 16, 520), Color("192b40"))
	draw_line(Vector2(40, 160), Vector2(1112, 160), Color("4a7287"), 2)
	draw_line(Vector2(40, 600), Vector2(1112, 600), Color("4a7287"), 2)
	_text(Vector2(82, 280), "01 / CHANGE YOUR PERSPECTIVE", 14, MINT)
	_text(Vector2(82, 314), "Space flips gravity.", 26, INK)
	_text(Vector2(82, 344), "Touch a surface before flipping again.", 16, MUTED)
	_text(Vector2(376, 541), "MIND THE LANDING", 12, Color("f67f91"))
	_text(Vector2(651, 221), "LOOK BOTH WAYS", 12, Color("f67f91"))
	_text(Vector2(520, 633), "CHECKPOINT", 12, Color("e4ba70"))
	_text(Vector2(1023, 517), "EXIT", 14, MINT)
	_text(Vector2(87, 575), "START", 11, MUTED)
	draw_line(Vector2(40, 657), Vector2(1112, 657), Color("25354a"))
	_text(Vector2(40, 693), "A / D  or  ← / →   Move      SPACE   Flip", 16, INK)
	_text(Vector2(705, 693), "R  Restart       ESC  Pause", 16, MUTED)
	if player != null:
		_text(Vector2(881, 110), "GRAVITY  " + ("↓ DOWN" if player.gravity_direction == 1 else "↑ UP"), 13, MINT)
	if notice_time > 0:
		var width := font.get_string_size(notice, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
		_text(Vector2((1152 - width) / 2, 460), notice, 17, MINT)
	for effect in effects:
		var fraction: float = effect["life"] / 0.45
		var color: Color = effect["color"]
		color.a = fraction
		draw_arc(effect["position"], 10 + (1 - fraction) * 35, 0, TAU, 32, color, 2)
