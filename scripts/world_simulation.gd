extends RefCounted

const SAVE_PATH := "user://windowsill_world.json"
const BACKUP_PATH := "user://windowsill_world.backup.json"
const SAVE_VERSION := 1
const MAP_W := 24
const MAP_H := 16

var world: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _accumulator := 0.0
var _save_clock := 0.0
var _plant_clock := 0.0

func load_or_create() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file != null:
			var parsed = JSON.parse_string(file.get_as_text())
			file.close()
			if parsed is Dictionary and int(parsed.get("save_version", 0)) <= SAVE_VERSION and parsed.has("creatures"):
				world = parsed
				_rng.seed = int(world.get("seed", 1))
				_apply_offline_progression()
				return
	_create_world()
	save_world()

func _create_world() -> void:
	_rng.randomize()
	var seed_value := int(_rng.randi())
	_rng.seed = seed_value
	world = {
		"save_version": SAVE_VERSION,
		"id": "world-%08x" % seed_value,
		"name": "Mosslight Meadow",
		"seed": seed_value,
		"width": MAP_W,
		"height": MAP_H,
		"day": 1,
		"clock": 7.5,
		"season": "Spring",
		"weather": "Clear",
		"weather_timer": 38.0,
		"last_saved_utc": int(Time.get_unix_time_from_system()),
		"terrain": [],
		"plants": [],
		"resources": [],
		"creatures": [],
		"structures": [],
		"journal": [],
		"population_limit": 24,
		"paused": false,
		"speed": 1.0
	}
	_generate_terrain()
	_generate_plants_and_resources()
	_generate_creatures()
	_record_event("A little world took root in the meadow.", "world")
	_record_event("Six tiny lives began their morning near the pond.", "milestone")

func _generate_terrain() -> void:
	var rows: Array = []
	for y in range(MAP_H):
		var row: Array = []
		for x in range(MAP_W):
			var tile := "grass"
			if _rng.randf() < 0.09:
				tile = "moss"
			elif _rng.randf() < 0.035:
				tile = "soil"
			row.append(tile)
		rows.append(row)
	world["terrain"] = rows
	# A little oval pond in the western half of the map.
	for y in range(5, 9):
		for x in range(5, 10):
			var dx := (float(x) - 7.2) / 2.5
			var dy := (float(y) - 6.8) / 2.0
			if dx * dx + dy * dy < 1.15:
				world["terrain"][y][x] = "water"
	for point in [Vector2i(3, 3), Vector2i(17, 4), Vector2i(19, 12), Vector2i(2, 12), Vector2i(13, 10)]:
		world["terrain"][point.y][point.x] = "stone"

func _generate_plants_and_resources() -> void:
	for i in range(62):
		var cell := _random_land_cell()
		var kind := ["grass", "flower", "berry", "mushroom", "bush", "tree"][_rng.randi_range(0, 5)]
		if kind == "grass" and _rng.randf() < 0.45:
			continue
		world["plants"].append({
			"id": "plant-%03d" % i,
			"kind": kind,
			"x": cell.x,
			"y": cell.y,
			"growth": _rng.randf_range(0.35, 1.0),
			"phase": _rng.randi_range(0, 2)
		})
	for i in range(42):
		var cell := _random_land_cell()
		var kind := "twig"
		if i % 5 == 0:
			kind = "berry"
		elif i % 4 == 0:
			kind = "leaf"
		world["resources"].append({"id": "resource-%03d" % i, "kind": kind, "x": cell.x, "y": cell.y})

func _generate_creatures() -> void:
	var starters := [
		{"name": "Pip", "species": "Pipkin", "x": 12.0, "y": 5.0, "traits": {"curiosity": 0.91, "sociability": 0.72, "boldness": 0.68, "industry": 0.48, "playfulness": 0.81}},
		{"name": "Mallow", "species": "Pipkin", "x": 14.0, "y": 7.0, "traits": {"curiosity": 0.57, "sociability": 0.88, "boldness": 0.38, "industry": 0.66, "playfulness": 0.74}},
		{"name": "Tumble", "species": "Pipkin", "x": 10.0, "y": 11.0, "traits": {"curiosity": 0.77, "sociability": 0.49, "boldness": 0.82, "industry": 0.79, "playfulness": 0.56}},
		{"name": "Fern", "species": "Mossback", "x": 16.0, "y": 10.0, "traits": {"curiosity": 0.42, "sociability": 0.75, "boldness": 0.36, "industry": 0.69, "playfulness": 0.45}},
		{"name": "Moss", "species": "Mossback", "x": 20.0, "y": 8.0, "traits": {"curiosity": 0.35, "sociability": 0.62, "boldness": 0.51, "industry": 0.38, "playfulness": 0.32}},
		{"name": "Glim", "species": "Lumenmoth", "x": 18.0, "y": 3.0, "traits": {"curiosity": 0.86, "sociability": 0.54, "boldness": 0.42, "industry": 0.51, "playfulness": 0.79}}
	]
	for i in range(starters.size()):
		var starter: Dictionary = starters[i]
		world["creatures"].append({
			"id": "creature-%03d" % (i + 1),
			"name": starter.name,
			"species": starter.species,
			"age_days": _rng.randi_range(18, 90),
			"pos": [starter.x, starter.y],
			"home": [int(starter.x), int(starter.y)],
			"target": [],
			"target_id": "",
			"action": "wander",
			"action_timer": _rng.randf_range(0.3, 1.5),
			"traits": starter.traits,
			"needs": {"hunger": _rng.randf_range(12.0, 35.0), "energy": _rng.randf_range(58.0, 88.0), "social": _rng.randf_range(18.0, 55.0), "curiosity": _rng.randf_range(22.0, 52.0)},
			"inventory": {"twig": 0, "berry": 0, "leaf": 0},
			"relationships": {},
			"memories": ["Woke beneath a soft spring sky."],
			"favorite": "the meadow"
		})

func _random_land_cell() -> Vector2i:
	for attempt in range(40):
		var cell := Vector2i(_rng.randi_range(1, MAP_W - 2), _rng.randi_range(1, MAP_H - 2))
		if world["terrain"][cell.y][cell.x] != "water" and world["terrain"][cell.y][cell.x] != "stone":
			return cell
	return Vector2i(12, 12)

func advance(delta: float) -> void:
	if world.is_empty() or bool(world.get("paused", false)):
		return
	var scaled_delta := minf(delta, 0.5) * float(world.get("speed", 1.0))
	_accumulator += scaled_delta
	while _accumulator >= 0.25:
		_tick(0.25)
		_accumulator -= 0.25
	_save_clock += scaled_delta
	if _save_clock >= 8.0:
		save_world()
		_save_clock = 0.0

func _tick(dt: float) -> void:
	var old_day := int(world["day"])
	world["clock"] = fmod(float(world["clock"]) + dt * 0.12, 24.0)
	if float(world["clock"]) < 7.5 and old_day == int(world["day"]):
		world["day"] = old_day + 1
		if int(world["day"]) % 8 == 0:
			world["season"] = ["Spring", "Summer", "Autumn", "Winter"][int((int(world["day"]) / 8) % 4)]
			_record_event("The meadow has drifted into %s." % world["season"], "season")
	world["weather_timer"] = float(world["weather_timer"]) - dt
	if float(world["weather_timer"]) <= 0.0:
		_change_weather()
	_plant_clock += dt
	if _plant_clock >= 4.0:
		_update_plants()
		_plant_clock = 0.0
	_update_creatures(dt)

func _change_weather() -> void:
	var previous: String = str(world["weather"])
	var options := ["Clear", "Cloudy", "Breeze", "Light rain", "Fog"]
	var weights := [0.43, 0.22, 0.16, 0.13, 0.06]
	var roll := _rng.randf()
	var running := 0.0
	var next_weather := "Clear"
	for i in range(options.size()):
		running += weights[i]
		if roll <= running:
			next_weather = options[i]
			break
	world["weather"] = next_weather
	world["weather_timer"] = _rng.randf_range(28.0, 70.0)
	if previous != next_weather and (next_weather == "Light rain" or previous == "Light rain" or next_weather == "Fog"):
		_record_event("A %s settled over the meadow." % next_weather.to_lower(), "weather")

func _update_plants() -> void:
	for plant in world["plants"]:
		var growth := float(plant.get("growth", 0.5))
		var multiplier := 1.0 if world["weather"] == "Light rain" else 0.55
		if world["season"] == "Winter":
			multiplier *= 0.22
		plant["growth"] = minf(1.0, growth + 0.0018 * multiplier)
		plant["phase"] = int(float(plant["growth"]) * 3.0)
	if _rng.randf() < 0.12 and world["plants"].size() < 100:
		var cell := _random_land_cell()
		world["plants"].append({"id": "sprout-%d" % Time.get_ticks_msec(), "kind": "flower" if _rng.randf() < 0.65 else "grass", "x": cell.x, "y": cell.y, "growth": 0.15, "phase": 0})

func _update_creatures(dt: float) -> void:
	for creature in world["creatures"]:
		var needs: Dictionary = creature["needs"]
		var action := str(creature.get("action", "wander"))
		needs["hunger"] = minf(100.0, float(needs["hunger"]) + dt * 0.48)
		needs["social"] = minf(100.0, float(needs["social"]) + dt * 0.15)
		needs["curiosity"] = minf(100.0, float(needs["curiosity"]) + dt * 0.12)
		if action == "sleep":
			needs["energy"] = minf(100.0, float(needs["energy"]) + dt * 5.0)
		else:
			needs["energy"] = maxf(0.0, float(needs["energy"]) - dt * 0.20)
		creature["age_days"] = float(creature.get("age_days", 20)) + dt * 0.00008
		if action == "sleep" and float(needs["energy"]) >= 92.0:
			creature["action"] = "wander"
			creature["target"] = []
		if str(creature.get("action", "")) == "socialise":
			_move_towards_target(creature, dt)
			_update_social_action(creature, dt)
		elif str(creature.get("action", "")) == "eat":
			_update_eat_action(creature)
		elif str(creature.get("action", "")) == "build":
			_update_build_action(creature, dt)
		else:
			_move_towards_target(creature, dt)
		creature["action_timer"] = float(creature.get("action_timer", 1.0)) - dt
		if float(creature["action_timer"]) <= 0.0 and str(creature.get("action", "")) != "build":
			_choose_action(creature)

func _choose_action(creature: Dictionary) -> void:
	var needs: Dictionary = creature["needs"]
	var inventory: Dictionary = creature["inventory"]
	var pos := Vector2(float(creature["pos"][0]), float(creature["pos"][1]))
	var traits: Dictionary = creature["traits"]
	var food_target := _nearest_resource(pos, "berry", 12.0)
	if float(needs["energy"]) < 25.0:
		creature["action"] = "sleep"
		creature["target"] = creature.get("home", [int(pos.x), int(pos.y)]).duplicate()
	elif float(needs["hunger"]) > 50.0 and int(inventory.get("berry", 0)) > 0:
		creature["action"] = "eat"
		creature["target"] = []
	elif float(needs["hunger"]) > 48.0 and not food_target.is_empty():
		_set_resource_target(creature, food_target)
	elif int(inventory.get("twig", 0)) >= 4 and int(inventory.get("leaf", 0)) >= 2 and float(traits.get("industry", 0.5)) > 0.55 and world["structures"].size() < 5:
		creature["action"] = "build"
		creature["target"] = [pos.x, pos.y]
		creature["build_progress"] = 0.0
		creature["action_timer"] = 20.0
	elif float(needs["social"]) > 58.0 and float(traits.get("sociability", 0.5)) > 0.4:
		var companion := _nearest_creature(pos, str(creature["id"]))
		if not companion.is_empty():
			creature["action"] = "socialise"
			creature["target_id"] = str(companion["id"])
			creature["target"] = companion["pos"].duplicate()
			creature["action_timer"] = 14.0
		else:
			_start_wander(creature, float(traits.get("curiosity", 0.5)) > 0.7)
	else:
		var resource_kind := "twig" if int(inventory.get("twig", 0)) < 4 else "leaf"
		var gather_target := _nearest_resource(pos, resource_kind, 11.0)
		if not gather_target.is_empty() and float(traits.get("industry", 0.5)) > 0.38:
			_set_resource_target(creature, gather_target)
		else:
			_start_wander(creature, float(traits.get("curiosity", 0.5)) > 0.68)
	if str(creature.get("action", "")) != "build" and str(creature.get("action", "")) != "socialise":
		creature["action_timer"] = _rng.randf_range(2.0, 4.5)

func _start_wander(creature: Dictionary, curious: bool) -> void:
	var cell := _random_land_cell()
	creature["action"] = "explore" if curious else "wander"
	creature["target"] = [float(cell.x), float(cell.y)]
	creature["target_id"] = ""

func _set_resource_target(creature: Dictionary, resource: Dictionary) -> void:
	creature["action"] = "gather"
	creature["target"] = [float(resource["x"]), float(resource["y"])]
	creature["target_id"] = str(resource["id"])

func _move_towards_target(creature: Dictionary, dt: float) -> void:
	var target: Array = creature.get("target", [])
	if target.size() < 2:
		return
	var pos := Vector2(float(creature["pos"][0]), float(creature["pos"][1]))
	var destination := Vector2(float(target[0]), float(target[1]))
	var distance := pos.distance_to(destination)
	if distance < 0.18:
		creature["pos"] = [destination.x, destination.y]
		if str(creature.get("action", "")) == "gather":
			_collect_target_resource(creature)
		elif str(creature.get("action", "")) == "explore":
			creature["needs"]["curiosity"] = maxf(0.0, float(creature["needs"]["curiosity"]) - 18.0)
			_add_memory(creature, "Found a new corner of the meadow.")
		creature["target"] = []
		return
	var speed := 0.55
	if str(creature["species"]) == "Mossback":
		speed = 0.34
	elif str(creature["species"]) == "Lumenmoth":
		speed = 0.68
	var direction := (destination - pos).normalized()
	var next_pos := pos + direction * minf(distance, speed * dt)
	if _is_blocked(Vector2i(roundi(next_pos.x), roundi(next_pos.y))):
		creature["target"] = []
		return
	creature["pos"] = [next_pos.x, next_pos.y]

func _is_blocked(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= MAP_W or cell.y >= MAP_H:
		return true
	return world["terrain"][cell.y][cell.x] == "water" or world["terrain"][cell.y][cell.x] == "stone"

func _collect_target_resource(creature: Dictionary) -> void:
	var target_id := str(creature.get("target_id", ""))
	for i in range(world["resources"].size() - 1, -1, -1):
		var resource: Dictionary = world["resources"][i]
		if str(resource["id"]) == target_id:
			var kind := str(resource["kind"])
			var inventory: Dictionary = creature["inventory"]
			inventory[kind] = int(inventory.get(kind, 0)) + 1
			world["resources"].remove_at(i)
			if kind == "berry":
				creature["needs"]["hunger"] = maxf(0.0, float(creature["needs"]["hunger"]) - 22.0)
			_add_memory(creature, "Gathered a %s near the meadow." % kind)
			return
	creature["action"] = "wander"

func _update_eat_action(creature: Dictionary) -> void:
	var inventory: Dictionary = creature["inventory"]
	if int(inventory.get("berry", 0)) > 0:
		inventory["berry"] = int(inventory["berry"]) - 1
		creature["needs"]["hunger"] = maxf(0.0, float(creature["needs"]["hunger"]) - 48.0)
		_add_memory(creature, "Enjoyed a ripe berry.")
	creature["action"] = "wander"
	creature["action_timer"] = 1.0

func _update_social_action(creature: Dictionary, _dt: float) -> void:
	var other := _find_creature(str(creature.get("target_id", "")))
	if other.is_empty():
		creature["action"] = "wander"
		return
	var a := Vector2(float(creature["pos"][0]), float(creature["pos"][1]))
	var b := Vector2(float(other["pos"][0]), float(other["pos"][1]))
	if a.distance_to(b) <= 1.6:
		creature["needs"]["social"] = maxf(0.0, float(creature["needs"]["social"]) - 24.0)
		other["needs"]["social"] = maxf(0.0, float(other["needs"]["social"]) - 12.0)
		var relation: Dictionary = creature["relationships"]
		var previous := int(relation.get(str(other["id"]), 0))
		relation[str(other["id"])] = mini(100, previous + 2)
		creature["action"] = "wander"
		creature["target"] = []
		if previous < 24 and int(relation[str(other["id"])]) >= 24:
			_record_event("%s and %s have started to become friends." % [creature["name"], other["name"]], "relationship")
			_add_memory(creature, "Spent a lovely moment with %s." % other["name"])
	else:
		creature["target"] = other["pos"].duplicate()

func _update_build_action(creature: Dictionary, dt: float) -> void:
	creature["build_progress"] = float(creature.get("build_progress", 0.0)) + dt * float(creature["traits"].get("industry", 0.5))
	if float(creature["build_progress"]) >= 8.0:
		var inventory: Dictionary = creature["inventory"]
		if int(inventory.get("twig", 0)) >= 4 and int(inventory.get("leaf", 0)) >= 2:
			inventory["twig"] = int(inventory["twig"]) - 4
			inventory["leaf"] = int(inventory["leaf"]) - 2
			var pos: Array = creature["pos"]
			world["structures"].append({"id": "shelter-%d" % Time.get_ticks_msec(), "kind": "leaf shelter", "x": roundi(float(pos[0])), "y": roundi(float(pos[1])), "builder": creature["name"]})
			_record_event("%s finished a little leaf shelter." % creature["name"], "building")
			_add_memory(creature, "Built a small shelter for the meadow.")
		creature["build_progress"] = 0.0
		creature["action"] = "wander"

func _nearest_resource(pos: Vector2, kind: String, max_distance: float) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := max_distance
	for resource in world["resources"]:
		if str(resource["kind"]) != kind:
			continue
		var distance := pos.distance_to(Vector2(float(resource["x"]), float(resource["y"])))
		if distance < best_distance:
			best_distance = distance
			best = resource
	return best

func _nearest_creature(pos: Vector2, exclude_id: String) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := 7.0
	for creature in world["creatures"]:
		if str(creature["id"]) == exclude_id:
			continue
		var distance := pos.distance_to(Vector2(float(creature["pos"][0]), float(creature["pos"][1])))
		if distance < best_distance:
			best_distance = distance
			best = creature
	return best

func _find_creature(id: String) -> Dictionary:
	for creature in world["creatures"]:
		if str(creature["id"]) == id:
			return creature
	return {}

func get_creature(id: String) -> Dictionary:
	return _find_creature(id)

func place_object(cell: Vector2i, kind: String) -> void:
	if cell.x < 0 or cell.y < 0 or cell.x >= MAP_W or cell.y >= MAP_H:
		return
	if kind == "pond":
		world["terrain"][cell.y][cell.x] = "water"
		_record_event("A little pool appeared in the meadow.", "player")
	elif kind == "flower" or kind == "seed":
		world["plants"].append({"id": "gift-%d" % Time.get_ticks_msec(), "kind": "flower" if kind == "flower" else "berry", "x": cell.x, "y": cell.y, "growth": 0.72, "phase": 2})
		_record_event("A new %s was planted." % ("flower" if kind == "flower" else "berry seed"), "player")
	elif kind == "twig":
		world["resources"].append({"id": "gift-%d" % Time.get_ticks_msec(), "kind": "twig", "x": cell.x, "y": cell.y})
		_record_event("A small bundle of twigs was left in the meadow.", "player")

func _add_memory(creature: Dictionary, message: String) -> void:
	var memories: Array = creature["memories"]
	if memories.is_empty() or str(memories[memories.size() - 1]) != message:
		memories.append(message)
	while memories.size() > 12:
		memories.pop_front()

func _record_event(message: String, kind: String) -> void:
	if world.is_empty():
		return
	world["journal"].push_front({"day": int(world.get("day", 1)), "text": message, "kind": kind, "time": float(world.get("clock", 7.5))})
	while world["journal"].size() > 160:
		world["journal"].pop_back()

func save_world() -> void:
	if world.is_empty():
		return
	world["last_saved_utc"] = int(Time.get_unix_time_from_system())
	world["save_version"] = SAVE_VERSION
	var file := FileAccess.open("user://windowsill_world.tmp", FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(world))
	file.flush()
	file.close()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(SAVE_PATH), ProjectSettings.globalize_path(BACKUP_PATH))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	var rename_error := DirAccess.rename_absolute(ProjectSettings.globalize_path("user://windowsill_world.tmp"), ProjectSettings.globalize_path(SAVE_PATH))
	if rename_error != OK and FileAccess.file_exists(BACKUP_PATH):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(BACKUP_PATH), ProjectSettings.globalize_path(SAVE_PATH))

func _apply_offline_progression() -> void:
	var previous := int(world.get("last_saved_utc", Time.get_unix_time_from_system()))
	var elapsed := clampi(int(Time.get_unix_time_from_system()) - previous, 0, 21600)
	if elapsed <= 30:
		return
	# A gentle catch-up: no pathfinding bursts, starvation deaths, or runaway population.
	var hours := float(elapsed) / 3600.0
	world["clock"] = fmod(float(world.get("clock", 7.5)) + hours * 1.8, 24.0)
	for creature in world["creatures"]:
		creature["needs"]["hunger"] = minf(82.0, float(creature["needs"].get("hunger", 20.0)) + hours * 7.0)
		creature["needs"]["energy"] = maxf(48.0, float(creature["needs"].get("energy", 70.0)))
	for plant in world["plants"]:
		plant["growth"] = minf(1.0, float(plant.get("growth", 0.5)) + hours * 0.025)
	if elapsed > 600:
		_record_event("The meadow quietly carried on while you were away.", "offline")
