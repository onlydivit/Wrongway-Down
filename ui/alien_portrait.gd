extends Control

var alien_id := "sprout"

func _draw() -> void:
	draw_circle(Vector2(46, 48), 42, Color("20364a"))
	draw_set_transform(Vector2(46, 51), 0, Vector2(1.65, 1.65))
	AlienRoster.paint(self, alien_id)
	draw_set_transform(Vector2.ZERO)
