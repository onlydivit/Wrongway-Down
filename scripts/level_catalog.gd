class_name LevelCatalog
extends RefCounted

var levels: Array[Dictionary] = []
var error := ""

func load_campaign(manifest_path := "res://levels/campaign.json") -> bool:
	levels.clear()
	error = ""
	var manifest = _read_json(manifest_path)
	if not manifest is Array or manifest.is_empty():
		return _fail("Campaign manifest must be a non-empty array of level paths.")
	var ids: Array[String] = []
	for path in manifest:
		if not path is String:
			return _fail("Manifest entries must be paths.")
		var data = _read_json(path)
		if not data is Dictionary:
			return _fail("Cannot read level: " + path)
		for key in ["id", "title", "hint", "difficulty", "spawn", "exit", "walls", "spikes", "checkpoints", "hazards", "switches", "gates"]:
			if not data.has(key):
				return _fail(path + ": missing " + key)
		if not data.id is String or data.id.is_empty() or data.id in ids:
			return _fail(path + ": level ID must be unique and non-empty")
		if not data.title is String or not data.hint is String or not data.difficulty is String:
			return _fail(path + ": title, hint and difficulty must be text")
		if not _numbers(data.spawn, 3) or not int(data.spawn[2]) in [-1, 1] or not _numbers(data.exit, 3):
			return _fail(path + ": invalid spawn/exit")
		if not int(data.exit[2]) in [-1, 1]:
			return _fail(path + ": exit surface must be -1 or 1")
		for key in ["walls", "spikes", "checkpoints", "hazards", "switches", "gates"]:
			if not data[key] is Array:
				return _fail(path + ": " + key + " must be an array")
		for wall in data.walls:
			if not _numbers(wall, 4) or wall[2] <= 0 or wall[3] <= 0:
				return _fail(path + ": invalid wall")
		for spike in data.spikes:
			if not _numbers(spike, 3) or spike[1] < 25 or not int(spike[2]) in [-1, 1]:
				return _fail(path + ": invalid spike")
		for point in data.checkpoints:
			if not _numbers(point, 2) or not int(point[1]) in [-1, 1]:
				return _fail(path + ": invalid checkpoint")
		for hazard in data.hazards:
			if not _numbers(hazard, 6) or hazard[3] <= 0 or hazard[5] <= 0:
				return _fail(path + ": invalid moving hazard")
		var switch_ids: Array[String] = []
		for item in data.switches:
			if not item is Array or item.size() != 3 or not item[0] is String or item[0] in switch_ids:
				return _fail(path + ": invalid or duplicate switch")
			if not _numbers(item.slice(1), 2) or not int(item[2]) in [-1, 1]:
				return _fail(path + ": invalid switch position")
			switch_ids.append(item[0])
		for gate in data.gates:
			if not gate is Array or gate.size() != 2 or not (gate[0] is float or gate[0] is int) or not gate[1] is Array or gate[1].is_empty():
				return _fail(path + ": invalid gate")
			for id in gate[1]:
				if not id in switch_ids:
					return _fail(path + ": gate references missing switch")
		ids.append(data.id)
		levels.append(data)
	return true

func _numbers(value: Variant, count: int) -> bool:
	if not value is Array or value.size() != count:
		return false
	for item in value:
		if not (item is int or item is float) or not is_finite(float(item)):
			return false
	return true

func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))

func _fail(message: String) -> bool:
	error = message
	levels.clear()
	return false
