class_name GravityPlayer
extends CharacterBody2D

signal flipped
signal landed

const SPEED := 270.0
const ACCELERATION := 2100.0
const GRAVITY := 1500.0
const TERMINAL_SPEED := 760.0
var gravity_direction := 1
var enabled := true
var visual_rotation := 0.0
var pulse := 0.0
var was_grounded := false
var settling_frames := 0

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	if settling_frames > 0:
		settling_frames -= 1
		velocity = Vector2(0, 30 * gravity_direction)
		move_and_slide()
		return
	var axis := Input.get_axis("move_left", "move_right")
	velocity.x = move_toward(velocity.x, axis * SPEED, ACCELERATION * delta)
	if Input.is_action_just_pressed("flip") and is_on_floor():
		gravity_direction *= -1
		up_direction = Vector2(0, -gravity_direction)
		velocity.y = 80.0 * gravity_direction
		pulse = 1.0
		flipped.emit()
	velocity.y = clampf(velocity.y + GRAVITY * gravity_direction * delta, -TERMINAL_SPEED, TERMINAL_SPEED)
	move_and_slide()
	if is_on_floor() and not was_grounded:
		landed.emit()
	was_grounded = is_on_floor()
	visual_rotation = lerp_angle(visual_rotation, PI if gravity_direction == -1 else 0.0, minf(delta * 18.0, 1.0))
	pulse = maxf(0.0, pulse - delta * 3.5)
	queue_redraw()

func respawn(at: Vector2, direction: int) -> void:
	position = at
	gravity_direction = direction
	up_direction = Vector2(0, -direction)
	velocity = Vector2.ZERO
	visual_rotation = PI if direction == -1 else 0.0
	was_grounded = false
	pulse = 1.0
	# Clear the previous surface contact before another flip can be accepted.
	settling_frames = 2
	enabled = true
	queue_redraw()

func _draw() -> void:
	if pulse > 0.0:
		draw_arc(Vector2.ZERO, 25.0 + (1.0 - pulse) * 20.0, 0, TAU, 32, Color(0.35, 0.95, 0.86, pulse * 0.6), 2.0)
	draw_set_transform(Vector2.ZERO, visual_rotation)
	draw_style_box(_body_style(), Rect2(-13, -17, 26, 34))
	draw_rect(Rect2(-9, -10, 18, 9), Color("123f50"))
	draw_rect(Rect2(-6, -8, 4, 4), Color("edfff6"))
	draw_rect(Rect2(3, -8, 4, 4), Color("edfff6"))
	draw_line(Vector2(-7, 12), Vector2(7, 12), Color("123f50"), 3.0)
	draw_set_transform(Vector2.ZERO)

func _body_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("85f5d5")
	style.set_corner_radius_all(5)
	return style
