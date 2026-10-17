class_name CampaignProgress
extends RefCounted

var completed: Array[String] = []
var save_path := "user://campaign.cfg"
var last_error: Error = OK

func load_progress() -> void:
	completed.clear()
	var config := ConfigFile.new()
	last_error = config.load(save_path)
	if last_error != OK:
		return
	var saved = config.get_value("campaign", "completed", [])
	if saved is Array:
		for id in saved:
			if id is String and not id in completed:
				completed.append(id)

func is_unlocked(index: int, levels: Array[Dictionary]) -> bool:
	if index < 0 or index >= levels.size():
		return false
	# Completed rooms remain replayable if later content is inserted earlier.
	return index == 0 or levels[index].id in completed or levels[index - 1].id in completed

func continue_index(levels: Array[Dictionary]) -> int:
	for index in range(levels.size()):
		if is_unlocked(index, levels) and not levels[index].id in completed:
			return index
	return levels.size() - 1

func mark_complete(id: String) -> Error:
	if not id in completed:
		completed.append(id)
	var config := ConfigFile.new()
	config.set_value("campaign", "version", 1)
	config.set_value("campaign", "completed", completed)
	last_error = config.save(save_path)
	return last_error
