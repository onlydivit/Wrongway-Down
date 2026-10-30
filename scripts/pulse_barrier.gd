class_name PulseBarrier
extends Area2D

signal touched
var safe_time := 2.8
var warning_time := 0.65
var active_time := 1.1
var phase := 0.0
var elapsed := 0.0
var beam_width := 16.0
var stage := 0

func stage_at(seconds: float) -> int:
	var period := safe_time + warning_time + active_time
	var time := fposmod(seconds + phase * period, period)
	if time < safe_time:
		return 0
	return 1 if time < safe_time + warning_time else 2

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var shape := RectangleShape2D.new()
	shape.size = Vector2(beam_width, 440)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = Vector2(beam_width / 2, 380)
	add_child(collision)
	stage = stage_at(elapsed)

func _physics_process(delta: float) -> void:
	elapsed += delta
	stage = stage_at(elapsed)
	# Check overlap every tick: standing in a safe beam becomes dangerous
	# when it activates, even without a fresh body_entered event.
	if stage == 2:
		for body in get_overlapping_bodies():
			if body is GravityPlayer and body.enabled:
				touched.emit()
	queue_redraw()

func _draw() -> void:
	var color := Color("42596b")
	var label := "PASS"
	if stage == 1:
		color = Color("f0c572")
		label = "READY"
	elif stage == 2:
		color = Color("ff758e")
		label = "STOP"
	if stage == 2:
		draw_rect(Rect2(0, 160, beam_width, 440), Color(color, 0.45))
		draw_line(Vector2(beam_width / 2, 160), Vector2(beam_width / 2, 600), color, 4)
	else:
		for y in range(160, 600, 20):
			draw_line(Vector2(beam_width / 2, y), Vector2(beam_width / 2, y + 8), color, 2)
	draw_rect(Rect2(-4, 155, beam_width + 8, 7), color)
	draw_rect(Rect2(-4, 598, beam_width + 8, 7), color)
	draw_string(ThemeDB.fallback_font, Vector2(-7, 115), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color)
