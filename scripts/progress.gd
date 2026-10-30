class_name CampaignProgress
extends RefCounted

var completed: Array[String] = []
var save_path := "user://campaign.cfg"
var last_error: Error = OK
var gravitos := 0
var rewarded: Array[String] = []
var owned: Array[String] = ["sprout"]
var equipped := "sprout"
var settings := {"master": 0.8, "music": 0.35, "sfx": 0.8, "muted": false}
var last_reward := 0
var last_first_clear := false

func load_progress() -> void:
	completed.clear()
	rewarded.clear()
	gravitos = 0
	owned = ["sprout"]
	equipped = "sprout"
	settings = {"master": 0.8, "music": 0.35, "sfx": 0.8, "muted": false}
	var config := ConfigFile.new()
	last_error = config.load(save_path)
	if last_error != OK:
		return
	var saved = config.get_value("campaign", "completed", [])
	if saved is Array:
		for id in saved:
			if id is String and not id in completed:
				completed.append(id)
	var wallet = config.get_value("economy", "gravitos", 0)
	if wallet is int:
		gravitos = maxi(0, wallet)
	var paid = config.get_value("economy", "rewarded", [])
	if paid is Array:
		for id in paid:
			if id is String and not id in rewarded:
				rewarded.append(id)
	var collection = config.get_value("aliens", "owned", [])
	if collection is Array:
		for id in collection:
			if id is String and not AlienRoster.get_alien(id).is_empty() and not id in owned:
				owned.append(id)
	var selected = config.get_value("aliens", "equipped", "sprout")
	if selected is String and selected in owned:
		equipped = selected
	for key in ["master", "music", "sfx"]:
		var value = config.get_value("audio", key, settings[key])
		if (value is float or value is int) and is_finite(float(value)):
			settings[key] = clampf(float(value), 0.0, 1.0)
	var muted = config.get_value("audio", "muted", false)
	if muted is bool:
		settings.muted = muted

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

func mark_complete(id: String, base_reward: int = 100) -> Error:
	last_first_clear = not id in rewarded
	last_reward = base_reward if last_first_clear else int(base_reward / 10)
	gravitos += last_reward
	if last_first_clear:
		rewarded.append(id)
	if not id in completed:
		completed.append(id)
	return save_progress()

func migrate_rewards(levels: Array[Dictionary]) -> Error:
	var changed := false
	for level in levels:
		if level.id in completed and not level.id in rewarded:
			rewarded.append(level.id)
			gravitos += int(level.get("reward", 100))
			changed = true
	return save_progress() if changed else OK

func buy_or_equip(id: String) -> String:
	var alien := AlienRoster.get_alien(id)
	if alien.is_empty():
		return "Unknown alien."
	var balance_before := gravitos
	var owned_before := owned.duplicate()
	var equipped_before := equipped
	if not id in owned:
		if gravitos < int(alien.price):
			return "Not enough Gravitos. Clear more levels to earn them."
		gravitos -= int(alien.price)
		owned.append(id)
	equipped = id
	if save_progress() != OK:
		gravitos = balance_before
		owned = owned_before
		equipped = equipped_before
		return "Could not save. Purchase was cancelled; no Gravitos spent."
	return ""

func save_progress() -> Error:
	var config := ConfigFile.new()
	config.set_value("campaign", "version", 2)
	config.set_value("campaign", "completed", completed)
	config.set_value("economy", "gravitos", gravitos)
	config.set_value("economy", "rewarded", rewarded)
	config.set_value("aliens", "owned", owned)
	config.set_value("aliens", "equipped", equipped)
	for key in settings:
		config.set_value("audio", key, settings[key])
	last_error = config.save(save_path)
	return last_error
