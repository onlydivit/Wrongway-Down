class_name AlienRoster
extends RefCounted

const ALIENS := [
	{"id": "sprout", "name": "Sprout", "price": 0, "color": "85f5d5", "detail": "A curious visitor with luminous antennae."},
	{"id": "orbix", "name": "Orbix", "price": 200, "color": "bc9aff", "detail": "One enormous eye. Excellent perspective."},
	{"id": "jelly", "name": "Jellyfin", "price": 600, "color": "70d9ff", "detail": "A floating ocean alien with tiny tentacles."},
	{"id": "ember", "name": "Emberling", "price": 1200, "color": "ffb26b", "detail": "A horned explorer from a volcanic moon."},
	{"id": "moth", "name": "Luna Moth", "price": 2200, "color": "dcf08c", "detail": "Wide wings and an appetite for starlight."},
	{"id": "crown", "name": "Nebula Crown", "price": 3600, "color": "ff96d5", "detail": "Three eyes, a crystal crown, infinite curiosity."}
]

static func get_alien(id: String) -> Dictionary:
	for alien in ALIENS:
		if alien.id == id:
			return alien
	return {}

static func paint(canvas: CanvasItem, id: String) -> void:
	var alien := get_alien(id)
	if alien.is_empty():
		alien = ALIENS[0]
	var color := Color(alien.color)
	var dark := Color("123344")
	match alien.id:
		"moth":
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(-8, -9), Vector2(-19, -17), Vector2(-17, 10), Vector2(-7, 15)]), color.darkened(0.2))
			canvas.draw_colored_polygon(PackedVector2Array([Vector2(8, -9), Vector2(19, -17), Vector2(17, 10), Vector2(7, 15)]), color.darkened(0.2))
		"ember", "crown":
			for x in [-9, 0, 9]:
				canvas.draw_colored_polygon(PackedVector2Array([Vector2(x - 4, -9), Vector2(x, -23 if x == 0 else -20), Vector2(x + 4, -9)]), color)
		"sprout":
			for x in [-7, 7]:
				canvas.draw_line(Vector2(x, -10), Vector2(x * 1.4, -23), color, 2)
				canvas.draw_circle(Vector2(x * 1.4, -23), 3, color)
	if alien.id == "jelly":
		canvas.draw_circle(Vector2(0, -4), 14, color)
		for x in [-9, -3, 3, 9]:
			canvas.draw_line(Vector2(x, 5), Vector2(x + 2, 18), color, 3)
	else:
		var style := StyleBoxFlat.new()
		style.bg_color = color
		style.set_corner_radius_all(12 if alien.id == "orbix" else 7)
		canvas.draw_style_box(style, Rect2(-13, -16, 26, 32))
		canvas.draw_line(Vector2(-7, 13), Vector2(-7, 18), color, 4)
		canvas.draw_line(Vector2(7, 13), Vector2(7, 18), color, 4)
	if alien.id == "orbix":
		canvas.draw_circle(Vector2(0, -4), 9, Color("f1ffff"))
		canvas.draw_circle(Vector2(2, -4), 4, dark)
	elif alien.id == "crown":
		for x in [-8, 0, 8]:
			canvas.draw_circle(Vector2(x, -5 if x != 0 else -8), 3.5, Color("f1ffff"))
			canvas.draw_circle(Vector2(x, -5 if x != 0 else -8), 1.5, dark)
	else:
		for x in [-6, 6]:
			canvas.draw_circle(Vector2(x, -5), 4, Color("f1ffff"))
			canvas.draw_circle(Vector2(x + 1, -5), 2, dark)
	canvas.draw_line(Vector2(-4, 7), Vector2(4, 7), dark, 2)
