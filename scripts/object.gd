class_name RoomObject
extends Area2D

signal activated(object: RoomObject)
enum Kind { SPIKES, CHECKPOINT, EXIT }
@export var kind: Kind = Kind.SPIKES
@export var object_size := Vector2(150, 24)
@export var ceiling := false
var active := false

func _ready() -> void:
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	# Inset spike detection slightly so the visible tips are forgiving.
	shape.size = object_size - Vector2(6, 6) if kind == Kind.SPIKES else object_size
	collision.shape = shape
	collision.position = object_size / 2.0
	add_child(collision)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is GravityPlayer:
		activated.emit(self)

func _draw() -> void:
	match kind:
		Kind.SPIKES:
			var count := int(object_size.x / 25)
			for i in range(count):
				var x := i * 25.0
				var points := PackedVector2Array([Vector2(x, object_size.y), Vector2(x + 12.5, 0), Vector2(x + 25, object_size.y)])
				if ceiling:
					points = PackedVector2Array([Vector2(x, 0), Vector2(x + 12.5, object_size.y), Vector2(x + 25, 0)])
				draw_colored_polygon(points, Color("f67f91"))
		Kind.CHECKPOINT:
			var color := Color("85f5d5") if active else Color("e4ba70")
			draw_line(Vector2(12, 0), Vector2(12, object_size.y), color, 3)
			draw_colored_polygon(PackedVector2Array([Vector2(12, 0), Vector2(36, 8), Vector2(12, 17)]), color)
			draw_line(Vector2(0, object_size.y), Vector2(32, object_size.y), color, 3)
		Kind.EXIT:
			draw_rect(Rect2(Vector2.ZERO, object_size), Color("102e3b"))
			draw_rect(Rect2(Vector2.ZERO, object_size), Color("85f5d5"), false, 2)
			draw_line(Vector2(17, 32), Vector2(43, 32), Color("85f5d5"), 3)
			draw_line(Vector2(34, 23), Vector2(43, 32), Color("85f5d5"), 3)
			draw_line(Vector2(34, 41), Vector2(43, 32), Color("85f5d5"), 3)
