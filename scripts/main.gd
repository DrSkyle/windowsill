extends Node2D

const WorldSimulation = preload("res://scripts/world_simulation.gd")
const TILE := 28.0
const PANEL_W := 278.0
const FOOTER_H := 82.0

var sim
var selected_id := ""
var active_tool := "inspect"
var panel_mode := "creature"
var rain_phase := 0.0
var world_origin := Vector2(24.0, 104.0)
var tile_size := TILE
var world_rect := Rect2()
var panel_rect := Rect2()
var footer_rect := Rect2()
var mouse_position := Vector2.ZERO

const COLORS := {
	"grass": Color("#76976d"), "moss": Color("#66845f"), "soil": Color("#987d60"),
	"water": Color("#709e9d"), "stone": Color("#9e9a83"), "cream": Color("#f0e8ce"),
	"ink": Color("#26372d"), "muted": Color("#a5b39a"), "panel": Color("#1d2b24"),
	"panel_light": Color("#2a3b30"), "accent": Color("#e1bd78"), "pipkin": Color("#d28f70"),
	"mossback": Color("#a9b77b"), "lumen": Color("#d6c5eb")
}

func _ready() -> void:
	get_window().title = "Windowsill — A little life of its own"
	sim = WorldSimulation.new()
	sim.load_or_create()
	set_process(true)
	queue_redraw()

func _process(delta: float) -> void:
	sim.advance(delta)
	rain_phase += delta
	queue_redraw()

func _draw() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color("#18251f"), true)
	_layout(size)
	_draw_header(size)
	_draw_world()
	_draw_side_panel()
	_draw_footer(size)
	_draw_weather_overlay()

func _layout(size: Vector2) -> void:
	var available_w := maxf(480.0, size.x - PANEL_W - 82.0)
	var available_h := maxf(280.0, size.y - 214.0)
	var cols := int(sim.world.get("width", 24))
	var rows := int(sim.world.get("height", 16))
	tile_size = minf(TILE, minf(available_w / float(cols), available_h / float(rows)))
	world_origin = Vector2(26.0, 100.0 + maxf(0.0, (available_h - rows * tile_size) * 0.5))
	world_rect = Rect2(world_origin, Vector2(cols * tile_size, rows * tile_size))
	panel_rect = Rect2(Vector2(size.x - PANEL_W - 22.0, 92.0), Vector2(PANEL_W, size.y - 190.0))
	footer_rect = Rect2(Vector2(20.0, size.y - FOOTER_H - 14.0), Vector2(size.x - 40.0, FOOTER_H))

func _draw_header(size: Vector2) -> void:
	_draw_text(Vector2(28, 38), "WINDOWSILL", 23, COLORS.cream, true)
	_draw_text(Vector2(30, 60), "A little life of its own", 11, COLORS.muted)
	var clock := float(sim.world.get("clock", 7.5))
	var hour := int(floor(clock))
	var minute := int(floor((clock - float(hour)) * 60.0))
	var time_text := "%02d:%02d" % [hour, minute]
	var meta := "DAY %d  ·  %s  ·  %s  ·  %d INHABITANTS" % [int(sim.world.get("day", 1)), str(sim.world.get("season", "Spring")).to_upper(), str(sim.world.get("weather", "Clear")).to_upper(), sim.world["creatures"].size()]
	_draw_text(Vector2(size.x - PANEL_W - 300.0, 34), meta, 10, COLORS.muted)
	_draw_text(Vector2(size.x - PANEL_W - 300.0, 58), time_text, 18, COLORS.accent, true)
	var pause_label := "Ⅱ  PAUSE" if not bool(sim.world.get("paused", false)) else "▶  RESUME"
	_draw_button(Rect2(size.x - 128.0, 20.0, 104.0, 40.0), pause_label, bool(sim.world.get("paused", false)))

func _draw_world() -> void:
	var terrain: Array = sim.world["terrain"]
	draw_rect(world_rect.grow(8.0), Color("#26372c"), true, 12.0)
	draw_rect(world_rect.grow(3.0), Color("#c7b891"), true, 4.0)
	for y in range(terrain.size()):
		for x in range(terrain[y].size()):
			var tile := str(terrain[y][x])
			var rect := Rect2(world_origin + Vector2(x, y) * tile_size, Vector2(tile_size, tile_size))
			var base: Color = COLORS.get(tile, COLORS.grass)
			var variation := float((x * 17 + y * 31) % 9) * 0.008
			base = base.lightened(variation)
			draw_rect(rect, base, true)
			if tile == "water":
				_draw_water_tile(rect, x, y)
			elif tile == "stone":
				draw_circle(rect.get_center(), tile_size * 0.28, Color("#777967"))
				draw_circle(rect.get_center() + Vector2(-2, -2), tile_size * 0.21, Color("#b5ad91"))
			elif tile == "moss":
				draw_circle(rect.get_center(), tile_size * 0.09, Color("#8fa77a"))
	_draw_plants()
	_draw_resources()
	_draw_structures()
	_draw_creatures()
	if active_tool != "inspect" and world_rect.has_point(mouse_position):
		var cell := _screen_to_cell(mouse_position)
		var preview := Rect2(world_origin + Vector2(cell) * tile_size, Vector2(tile_size, tile_size))
		draw_rect(preview, Color(0.95, 0.84, 0.57, 0.42), false, 2.0)

func _draw_water_tile(rect: Rect2, x: int, y: int) -> void:
	var shimmer := sin(rain_phase * 1.2 + float(x * 5 + y * 3)) * tile_size * 0.06
	draw_line(rect.position + Vector2(5, rect.size.y * 0.38 + shimmer), rect.position + Vector2(rect.size.x - 5, rect.size.y * 0.38 + shimmer), Color("#a9c8bb"), 1.0)
	draw_line(rect.position + Vector2(8, rect.size.y * 0.7 - shimmer), rect.position + Vector2(rect.size.x - 9, rect.size.y * 0.7 - shimmer), Color(0.82, 0.87, 0.75, 0.55), 1.0)

func _draw_plants() -> void:
	for plant in sim.world["plants"]:
		var point := _cell_center(int(plant["x"]), int(plant["y"]))
		var growth := float(plant.get("growth", 0.7))
		var kind := str(plant.get("kind", "flower"))
		var scale := tile_size * (0.10 + growth * 0.10)
		match kind:
			"tree":
				draw_circle(point + Vector2(0, 3), scale * 1.7, Color("#405b43"))
				draw_circle(point + Vector2(-2, -scale * 0.55), scale * 1.35, Color("#557b54"))
				draw_circle(point + Vector2(2, -scale), scale * 0.95, Color("#78966a"))
			"bush", "berry":
				draw_circle(point, scale * 1.25, Color("#47694b"))
				draw_circle(point + Vector2(-2, -2), scale, Color("#739267"))
				if kind == "berry":
					draw_circle(point + Vector2(2, -2), maxf(1.5, scale * 0.18), Color("#bd7d70"))
			"mushroom":
				draw_rect(Rect2(point + Vector2(-1.5, -1), Vector2(3, 6)), Color("#e5d4b6"), true)
				draw_circle(point + Vector2(0, -2), scale * 0.55, Color("#bd816d"))
			"flower":
				draw_line(point, point + Vector2(0, -scale), Color("#536d49"), 1.3)
				for petal in range(5):
					var angle := TAU * float(petal) / 5.0
					draw_circle(point + Vector2(cos(angle), sin(angle)) * scale * 0.36 + Vector2(0, -scale), scale * 0.22, Color("#e7d0a6") if petal % 2 == 0 else Color("#c6b7d5"))
				draw_circle(point + Vector2(0, -scale), scale * 0.16, Color("#d4a95f"))
			_:
				draw_line(point + Vector2(-2, 2), point + Vector2(0, -scale * 0.9), Color("#55754d"), 2.0)
				draw_line(point + Vector2(1, 3), point + Vector2(3, -scale * 0.7), Color("#8da775"), 1.5)

func _draw_resources() -> void:
	for resource in sim.world["resources"]:
		var p := _cell_center(int(resource["x"]), int(resource["y"]))
		if str(resource["kind"]) == "berry":
			draw_circle(p, tile_size * 0.085, Color("#b97170"))
			draw_circle(p + Vector2(2, -2), tile_size * 0.055, Color("#d99a87"))
		else:
			draw_line(p + Vector2(-3, 2), p + Vector2(4, -2), Color("#a98a64"), 2.2)

func _draw_structures() -> void:
	for structure in sim.world["structures"]:
		var p := _cell_center(int(structure["x"]), int(structure["y"]))
		draw_colored_polygon(PackedVector2Array([p + Vector2(-tile_size * 0.36, 1), p + Vector2(0, -tile_size * 0.36), p + Vector2(tile_size * 0.36, 1)]), Color("#9b805d"))
		draw_rect(Rect2(p + Vector2(-tile_size * 0.29, 0), Vector2(tile_size * 0.58, tile_size * 0.27)), Color("#c4a77b"), true)
		draw_rect(Rect2(p + Vector2(-tile_size * 0.055, tile_size * 0.09), Vector2(tile_size * 0.11, tile_size * 0.18)), Color("#4a5541"), true)

func _draw_creatures() -> void:
	for creature in sim.world["creatures"]:
		var pos: Array = creature["pos"]
		var point := world_origin + Vector2(float(pos[0]) + 0.5, float(pos[1]) + 0.5) * tile_size
		var selected := str(creature["id"]) == selected_id
		var bob := sin(rain_phase * 3.5 + float(str(creature["id"]).length())) * 1.3
		point.y += bob
		draw_ellipse(point + Vector2(0, tile_size * 0.18), Vector2(tile_size * 0.28, tile_size * 0.12), Color(0.12, 0.18, 0.13, 0.25))
		var species := str(creature["species"])
		var body: Color = COLORS.pipkin
		if species == "Mossback":
			body = COLORS.mossback
		elif species == "Lumenmoth":
			body = COLORS.lumen
		if species == "Lumenmoth":
			draw_colored_polygon(PackedVector2Array([point + Vector2(-tile_size * 0.16, 0), point + Vector2(-tile_size * 0.46, -tile_size * 0.28), point + Vector2(-tile_size * 0.38, tile_size * 0.12)]), body.lightened(0.12))
			draw_colored_polygon(PackedVector2Array([point + Vector2(tile_size * 0.16, 0), point + Vector2(tile_size * 0.46, -tile_size * 0.28), point + Vector2(tile_size * 0.38, tile_size * 0.12)]), body.lightened(0.12))
			draw_circle(point, tile_size * 0.18, body)
		else:
			draw_ellipse(point, Vector2(tile_size * 0.29, tile_size * (0.22 if species == "Mossback" else 0.25)), body)
			if species == "Mossback":
				draw_arc(point, tile_size * 0.21, PI, TAU, 16, Color("#667c56"), 1.2)
			else:
				draw_circle(point + Vector2(-tile_size * 0.08, -tile_size * 0.17), tile_size * 0.055, Color("#f4d7b4"))
				draw_circle(point + Vector2(tile_size * 0.08, -tile_size * 0.17), tile_size * 0.055, Color("#f4d7b4"))
		draw_circle(point + Vector2(-tile_size * 0.075, -tile_size * 0.17), tile_size * 0.022, Color("#27342c"))
		draw_circle(point + Vector2(tile_size * 0.075, -tile_size * 0.17), tile_size * 0.022, Color("#27342c"))
		if selected:
			draw_arc(point, tile_size * 0.48, 0, TAU, 32, COLORS.accent, 2.0)
			_draw_text(point + Vector2(-22, -tile_size * 0.62), str(creature["name"]), 10, COLORS.cream, true)

func _draw_side_panel() -> void:
	draw_rect(panel_rect, COLORS.panel, true, 14.0)
	draw_rect(Rect2(panel_rect.position, Vector2(panel_rect.size.x, 3)), COLORS.accent, true)
	var x := panel_rect.position.x + 18.0
	var y := panel_rect.position.y + 28.0
	_draw_text(Vector2(x, y), "A CLOSER LOOK", 10, COLORS.muted, true)
	var journal_button := Rect2(panel_rect.end.x - 98, panel_rect.position.y + 13, 82, 28)
	_draw_button(journal_button, "JOURNAL", panel_mode == "journal")
	if panel_mode == "journal":
		_draw_text(Vector2(x, y + 42), "Little moments", 18, COLORS.cream, true)
		var entries: Array = sim.world["journal"]
		var row_y := y + 72.0
		for i in range(mini(entries.size(), 10)):
			var entry: Dictionary = entries[i]
			_draw_text(Vector2(x, row_y), "DAY %d" % int(entry.get("day", 1)), 9, COLORS.accent, true)
			row_y += 16
			row_y = _draw_wrapped_text(Vector2(x, row_y), str(entry.get("text", "")), 11, COLORS.cream, panel_rect.size.x - 36.0, 2)
			row_y += 12
			if row_y > panel_rect.end.y - 18:
				break
		return
	var creature := sim.get_creature(selected_id)
	if creature.is_empty():
		_draw_text(Vector2(x, y + 48), "The meadow is waking.", 17, COLORS.cream, true)
		_draw_wrapped_text(Vector2(x, y + 76), "Choose a little inhabitant to learn their name, habits and recent memories. Or simply leave them be.", 12, COLORS.muted, panel_rect.size.x - 36.0, 4)
		_draw_text(Vector2(x, y + 174), "TODAY IN THE MEADOW", 10, COLORS.accent, true)
		var entries: Array = sim.world["journal"]
		var row_y := y + 198.0
		for i in range(mini(entries.size(), 4)):
			var entry: Dictionary = entries[i]
			row_y = _draw_wrapped_text(Vector2(x, row_y), "· " + str(entry.get("text", "")), 11, COLORS.cream, panel_rect.size.x - 36.0, 3)
			row_y += 12
		return
	_draw_text(Vector2(x, y + 48), str(creature["name"]), 24, COLORS.cream, true)
	_draw_text(Vector2(x, y + 69), str(creature["species"]).to_upper() + "  ·  %d DAYS OLD" % int(creature["age_days"]), 9, COLORS.accent, true)
	_draw_text(Vector2(x, y + 105), "RIGHT NOW", 9, COLORS.muted, true)
	_draw_text(Vector2(x, y + 126), _activity_label(str(creature.get("action", "wandering"))), 15, COLORS.cream)
	var needs: Dictionary = creature["needs"]
	var bar_y := y + 160.0
	for key in ["hunger", "energy", "social", "curiosity"]:
		_draw_need_bar(Vector2(x, bar_y), key.capitalize(), float(needs.get(key, 0.0)))
		bar_y += 34.0
	_draw_text(Vector2(x, bar_y + 7), "PERSONALITY", 9, COLORS.muted, true)
	bar_y += 27.0
	var traits: Dictionary = creature["traits"]
	_draw_text(Vector2(x, bar_y), "Curious %d   Social %d" % [int(float(traits.get("curiosity", 0.5)) * 100), int(float(traits.get("sociability", 0.5)) * 100)], 10, COLORS.cream)
	bar_y += 22.0
	_draw_text(Vector2(x, bar_y), "Bold %d       Industrious %d" % [int(float(traits.get("boldness", 0.5)) * 100), int(float(traits.get("industry", 0.5)) * 100)], 10, COLORS.cream)
	bar_y += 28.0
	_draw_text(Vector2(x, bar_y), "RECENT MEMORIES", 9, COLORS.muted, true)
	bar_y += 20.0
	var memories: Array = creature.get("memories", [])
	for i in range(mini(memories.size(), 3)):
		bar_y = _draw_wrapped_text(Vector2(x, bar_y), "· " + str(memories[memories.size() - 1 - i]), 10, COLORS.cream, panel_rect.size.x - 36.0, 2)
		bar_y += 7.0

func _draw_need_bar(point: Vector2, label: String, value: float) -> void:
	_draw_text(point, label, 10, COLORS.muted)
	var rect := Rect2(point + Vector2(88, -9), Vector2(panel_rect.size.x - 124, 7))
	draw_rect(rect, Color("#34463a"), true, 3.0)
	var fill := rect
	fill.size.x *= clampf(value / 100.0, 0.0, 1.0)
	var color := Color("#91af7f")
	if value > 75:
		color = Color("#d19a70") if label == "Hunger" else Color("#b8a4c8")
	draw_rect(fill, color, true, 3.0)

func _draw_footer(size: Vector2) -> void:
	draw_rect(footer_rect, Color("#1d2b24"), true, 14.0)
	_draw_text(footer_rect.position + Vector2(16, 23), "GENTLE HANDS", 9, COLORS.muted, true)
	var tools := [
		{"id": "inspect", "label": "Observe", "key": "1"},
		{"id": "flower", "label": "Plant a flower", "key": "2"},
		{"id": "twig", "label": "Leave twigs", "key": "3"},
		{"id": "seed", "label": "Berry seed", "key": "4"},
		{"id": "pond", "label": "Little pond", "key": "5"}
	]
	var start_x := footer_rect.position.x + 128.0
	for i in range(tools.size()):
		var rect := Rect2(start_x + float(i) * 142.0, footer_rect.position.y + 18.0, 132.0, 44.0)
		_draw_button(rect, tools[i].label, active_tool == tools[i].id)
		_draw_text(rect.position + Vector2(10, 35), tools[i].key, 8, COLORS.muted)
	_draw_text(Vector2(size.x - 150, footer_rect.end.y - 12), "SPACE  PAUSE", 9, COLORS.muted)

func _draw_weather_overlay() -> void:
	var weather := str(sim.world.get("weather", "Clear"))
	if weather == "Light rain":
		for i in range(54):
			var x := world_rect.position.x + fposmod(float(i * 83) + rain_phase * 42.0, world_rect.size.x)
			var y := world_rect.position.y + fposmod(float(i * 47) + rain_phase * 110.0, world_rect.size.y)
			draw_line(Vector2(x, y), Vector2(x - 3, y + 8), Color(0.79, 0.86, 0.84, 0.34), 1.0)
	elif weather == "Fog":
		draw_rect(world_rect, Color(0.82, 0.86, 0.78, 0.13), true)

func _draw_button(rect: Rect2, label: String, active: bool) -> void:
	var fill := Color("#4a5c46") if active else Color("#304137")
	draw_rect(rect, fill, true, 7.0)
	draw_rect(rect, Color("#839176") if active else Color("#45594a"), false, 1.0, true)
	_draw_text(rect.position + Vector2(10, rect.size.y * 0.66), label, 10, COLORS.cream, true)

func _draw_text(point: Vector2, value: String, font_size: int, color: Color, bold: bool = false) -> void:
	var font := ThemeDB.fallback_font
	var size := font_size + (1 if bold else 0)
	draw_string(font, point, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw_wrapped_text(point: Vector2, value: String, font_size: int, color: Color, max_width: float, max_lines: int) -> float:
	var font := ThemeDB.fallback_font
	var words := value.split(" ")
	var lines: Array[String] = []
	var current := ""
	for word in words:
		var attempt := word if current.is_empty() else current + " " + word
		if font.get_string_size(attempt, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > max_width and not current.is_empty():
			lines.append(current)
			current = word
		else:
			current = attempt
	if not current.is_empty():
		lines.append(current)
	for i in range(mini(lines.size(), max_lines)):
		_draw_text(point + Vector2(0, float(i) * 15.0), lines[i], font_size, color)
	return point.y + float(mini(lines.size(), max_lines)) * 15.0

func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(20):
		var angle := TAU * float(i) / 20.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)

func _cell_center(x: int, y: int) -> Vector2:
	return world_origin + (Vector2(x, y) + Vector2(0.5, 0.5)) * tile_size

func _screen_to_cell(point: Vector2) -> Vector2i:
	var local := (point - world_origin) / tile_size
	return Vector2i(floori(local.x), floori(local.y))

func _activity_label(action: String) -> String:
	match action:
		"wander": return "Wandering softly"
		"explore": return "Exploring somewhere new"
		"gather": return "Gathering materials"
		"sleep": return "Having a little rest"
		"eat": return "Having a snack"
		"socialise": return "Visiting a friend"
		"build": return "Making a shelter"
	return action.capitalize()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_position = event.position
		queue_redraw()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_handle_click(event.position)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				sim.world["paused"] = not bool(sim.world.get("paused", false))
				queue_redraw()
			KEY_1: active_tool = "inspect"
			KEY_2: active_tool = "flower"
			KEY_3: active_tool = "twig"
			KEY_4: active_tool = "seed"
			KEY_5: active_tool = "pond"
		queue_redraw()

func _handle_click(point: Vector2) -> void:
	var size := get_viewport_rect().size
	var pause_rect := Rect2(size.x - 128.0, 20.0, 104.0, 40.0)
	if pause_rect.has_point(point):
		sim.world["paused"] = not bool(sim.world.get("paused", false))
		return
	var journal_rect := Rect2(panel_rect.end.x - 98, panel_rect.position.y + 13, 82, 28)
	if journal_rect.has_point(point):
		panel_mode = "journal" if panel_mode != "journal" else "creature"
		return
	if footer_rect.has_point(point):
		var start_x := footer_rect.position.x + 128.0
		var ids := ["inspect", "flower", "twig", "seed", "pond"]
		for i in range(ids.size()):
			var rect := Rect2(start_x + float(i) * 142.0, footer_rect.position.y + 18.0, 132.0, 44.0)
			if rect.has_point(point):
				active_tool = ids[i]
				panel_mode = "creature"
				return
	if world_rect.has_point(point):
		var cell := _screen_to_cell(point)
		if active_tool != "inspect":
			sim.place_object(cell, active_tool)
		else:
			selected_id = _creature_at(point)
			panel_mode = "creature"
		return
	selected_id = ""
	panel_mode = "creature"

func _creature_at(point: Vector2) -> String:
	var best := ""
	var best_distance := tile_size * 0.65
	for creature in sim.world["creatures"]:
		var pos: Array = creature["pos"]
		var screen := world_origin + (Vector2(float(pos[0]), float(pos[1])) + Vector2(0.5, 0.5)) * tile_size
		var distance := screen.distance_to(point)
		if distance < best_distance:
			best_distance = distance
			best = str(creature["id"])
	return best

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		sim.save_world()
		get_tree().quit()
