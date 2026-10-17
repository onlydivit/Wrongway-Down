class_name MovingHazard
extends Area2D

signal touched
var start := Vector2.ZERO
var finish := Vector2.ZERO
var period := 5.0
var phase := 0.0
var radius := 17.0
var elapsed := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var shape := CircleShape2D.new()
	shape.radius = radius - 2
	var collider := CollisionShape2D.new()
	collider.shape = shape
	add_child(collider)
	body_entered.connect(func(body):
		if body is GravityPlayer:
			touched.emit()
	)
	_update_position()

func _physics_process(delta: float) -> void:
	elapsed += delta
	_update_position()
	queue_redraw()

func _update_position() -> void:
	position = start.lerp(finish, (1.0 - cos(TAU * (elapsed / period + phase))) / 2.0)

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color("f67f91"))
	draw_circle(Vector2.ZERO, radius - 6, Color("482d43"))
	for i in range(8):
		var direction := Vector2.from_angle(i * TAU / 8 + elapsed)
		draw_line(direction * (radius - 2), direction * (radius + 4), Color("f67f91"), 3)
