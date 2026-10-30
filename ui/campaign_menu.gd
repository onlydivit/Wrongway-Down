class_name CampaignMenu
extends CanvasLayer

var overlay: Control
var title: Label
var description: Label
var choices: VBoxContainer
var scroll: ScrollContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay = Control.new()
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	overlay.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.016, 0.027, 0.05, 0.94)
	var panel := Panel.new()
	panel.position = Vector2(266, 150)
	panel.size = Vector2(620, 480)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("101e31")
	style.border_color = Color("30465b")
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	panel.add_theme_stylebox_override("panel", style)
	overlay.add_child(panel)
	title = _label(Vector2(296, 178), Vector2(560, 48), 32, Color("85f5d5"))
	description = _label(Vector2(296, 232), Vector2(560, 60), 16, Color("dce8f3"))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll = ScrollContainer.new()
	scroll.position = Vector2(306, 306)
	scroll.size = Vector2(540, 298)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	overlay.add_child(scroll)
	choices = VBoxContainer.new()
	choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choices.add_theme_constant_override("separation", 10)
	scroll.add_child(choices)

func _label(at: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = at
	label.size = size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	overlay.add_child(label)
	return label

func show_page(heading: String, body: String) -> void:
	overlay.show()
	title.text = heading
	description.text = body
	for child in choices.get_children():
		choices.remove_child(child)
		child.queue_free()
	scroll.scroll_vertical = 0

func hide_page() -> void:
	overlay.hide()

func add_button(text: String, callback: Callable, locked := false, parent: Node = null) -> Button:
	var button := Button.new()
	button.text = text
	button.disabled = locked
	button.custom_minimum_size = Vector2(250, 40)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 16)
	for item in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("254a56") if item in ["hover", "focus"] else Color("1a3347")
		style.border_color = Color("85f5d5") if item == "focus" else Color("3b6070")
		style.set_border_width_all(1)
		style.set_corner_radius_all(6)
		button.add_theme_stylebox_override(item, style)
	button.pressed.connect(callback)
	(choices if parent == null else parent).add_child(button)
	return button

func add_level_grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	choices.add_child(grid)
	return grid

func add_slider(label_text: String, value: float, callback: Callable) -> HSlider:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 48
	choices.add_child(row)
	var label := Label.new()
	label.custom_minimum_size.x = 145
	label.text = "%s  %d%%" % [label_text, roundi(value * 100)]
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = value * 100
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(slider)
	slider.value_changed.connect(func(amount: float):
		label.text = "%s  %d%%" % [label_text, roundi(amount)]
		callback.call(amount / 100.0)
	)
	return slider

func add_alien_card(alien: Dictionary, action_text: String, callback: Callable, locked: bool) -> Button:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 104
	row.add_theme_constant_override("separation", 16)
	choices.add_child(row)
	var portrait = load("res://ui/alien_portrait.gd").new()
	portrait.alien_id = alien.id
	portrait.custom_minimum_size = Vector2(96, 100)
	row.add_child(portrait)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	var label := Label.new()
	label.text = alien.name
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(alien.color))
	info.add_child(label)
	var detail := Label.new()
	detail.text = alien.detail
	detail.add_theme_font_size_override("font_size", 13)
	info.add_child(detail)
	return add_button(action_text, callback, locked, info)
