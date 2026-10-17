class_name CampaignLevel
extends Node2D

signal danger
signal completed
signal checkpoint_changed(at: Vector2, direction: int)
signal switch_changed(remaining: int)
const OBJECT_SCENE = preload("res://scenes/object.tscn")
const HAZARD_SCRIPT = preload("res://scripts/moving_hazard.gd")
var data: Dictionary
var walls: Array[Rect2] = []
var gates: Array[Dictionary] = []
var switches: Dictionary = {}
var hazards: Array[MovingHazard] = []
var checkpoint: RoomObject

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	for rect in [Rect2(40, 120, 1072, 40), Rect2(40, 600, 1072, 40), Rect2(24, 120, 16, 520), Rect2(1112, 120, 16, 520)]:
		_wall(rect)
	for item in data.walls:
		_wall(Rect2(item[0], item[1], item[2], item[3]))
	for spike in data.spikes:
		_object(RoomObject.Kind.SPIKES, Vector2(spike[0], 160 if spike[2] == -1 else 576), Vector2(spike[1], 24), spike[2] == -1)
	for point in data.checkpoints:
		var object := _object(RoomObject.Kind.CHECKPOINT, Vector2(point[0] - 16, 160 if point[1] == -1 else 550), Vector2(36, 50), point[1] == -1)
		object.respawn_position = Vector2(point[0], 182 if point[1] == -1 else 578)
		object.respawn_gravity = int(point[1])
	for item in data.switches:
		var object := _object(RoomObject.Kind.SWITCH, Vector2(item[1] - 18, 160 if item[2] == -1 else 564), Vector2(36, 36))
		object.object_id = item[0]
		switches[item[0]] = object
	for item in data.gates:
		var rect := Rect2(item[0], 160, 16, 440)
		gates.append({"rect": rect, "body": _body(rect), "requires": item[1], "open": false})
	for item in data.hazards:
		var hazard := HAZARD_SCRIPT.new()
		hazard.start = Vector2(item[0], item[1])
		hazard.finish = Vector2(item[0], item[2])
		hazard.period = item[3]
		hazard.phase = item[4]
		hazard.radius = item[5]
		hazard.touched.connect(func(): danger.emit())
		add_child(hazard)
		hazards.append(hazard)
	_object(RoomObject.Kind.EXIT, Vector2(data.exit[0], data.exit[1]), Vector2(60, 68))

func _body(rect: Rect2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = rect.position
	body.collision_layer = 2
	body.collision_mask = 1
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.position = rect.size / 2
	body.add_child(collision)
	add_child(body)
	return body

func _wall(rect: Rect2) -> void:
	walls.append(rect)
	_body(rect)

func _object(kind: RoomObject.Kind, at: Vector2, size: Vector2, ceiling := false) -> RoomObject:
	var object: RoomObject = OBJECT_SCENE.instantiate()
	object.kind = kind
	object.position = at
	object.object_size = size
	object.ceiling = ceiling
	object.activated.connect(_on_object)
	add_child(object)
	return object

func _on_object(object: RoomObject) -> void:
	match object.kind:
		RoomObject.Kind.SPIKES:
			danger.emit()
		RoomObject.Kind.EXIT:
			completed.emit()
		RoomObject.Kind.CHECKPOINT:
			if checkpoint != object:
				if checkpoint != null:
					checkpoint.active = false
					checkpoint.queue_redraw()
				checkpoint = object
				object.active = true
				object.queue_redraw()
				checkpoint_changed.emit(object.respawn_position, object.respawn_gravity)
		RoomObject.Kind.SWITCH:
			if not object.active:
				object.active = true
				object.queue_redraw()
				_update_gates()
				var remaining := 0
				for item in switches.values():
					if not item.active:
						remaining += 1
				switch_changed.emit(remaining)

func _update_gates() -> void:
	for gate in gates:
		var opened := true
		for id in gate.requires:
			if not switches[id].active:
				opened = false
		gate.open = opened
		gate.body.set_deferred("collision_layer", 0 if opened else 2)
	queue_redraw()

func _draw() -> void:
	for rect in walls:
		draw_rect(rect, Color("192b40"))
		draw_rect(rect, Color("4a7287"), false, 2)
		for x in range(int(rect.position.x + 8), int(rect.end.x - 18), 32):
			draw_line(Vector2(x, rect.position.y + 10), Vector2(x + 18, rect.position.y + 28), Color("29445a"), 2)
	for hazard in hazards:
		draw_line(hazard.start, hazard.finish, Color("542d43"), 1)
		draw_circle(hazard.start, 3, Color("f67f91"))
		draw_circle(hazard.finish, 3, Color("f67f91"))
	for gate in gates:
		var rect: Rect2 = gate.rect
		if not gate.open:
			draw_rect(rect, Color("68528f"))
			for y in range(170, 590, 24):
				draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y + 12), Color("c6acff"), 2)
		else:
			draw_rect(Rect2(rect.position, Vector2(16, 8)), Color("85f5d5"))
		var label := "+".join(gate.requires) + (" OPEN" if gate.open else " LOCK")
		draw_string(ThemeDB.fallback_font, Vector2(rect.position.x - 25, 112), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("c6acff"))
