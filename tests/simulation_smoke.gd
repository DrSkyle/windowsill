extends SceneTree

const WorldSimulation = preload("res://scripts/world_simulation.gd")

func _initialize() -> void:
	var simulation = WorldSimulation.new()
	simulation._create_world()
	assert(simulation.world["width"] == 24)
	assert(simulation.world["height"] == 16)
	assert(simulation.world["creatures"].size() == 6)
	assert(simulation.world["plants"].size() > 20)
	assert(simulation.world["resources"].size() == 42)
	var original_ids: Array[String] = []
	for creature in simulation.world["creatures"]:
		original_ids.append(str(creature["id"]))
		assert(creature["traits"].has("curiosity"))
		assert(creature["needs"].has("hunger"))
	for _step in range(1200):
		simulation._tick(0.25)
	assert(simulation.world["day"] >= 2)
	assert(simulation.world["journal"].size() >= 2)
	assert(simulation.world["creatures"].size() == 6)
	for index in range(original_ids.size()):
		assert(str(simulation.world["creatures"][index]["id"]) == original_ids[index])
	print("Windowsill simulation smoke test passed.")
	quit(0)
