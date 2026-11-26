# Windowsill

**A little life of its own.**

Windowsill is a local-first desktop terrarium: a small meadow inhabited by autonomous little creatures. They wander, gather, eat, rest, meet one another, remember moments, and slowly begin to make a home. You do not command them. You change the environment and see what happens.

> This repository starts with a playable Phase 1 foundation. It is deliberately honest about what is implemented and what is still planned.

## Run it

1. Install **Godot 4.2 or later**.
2. Open `project.godot` in Godot.
3. Press **F6** or **Run Project** (the project main scene is already configured).

No account, server, network access, downloaded asset, or third-party runtime is required. The initial art is drawn in code so the project can boot offline without an asset pipeline.

## What works in this first build

- A generated meadow with grass, moss, soil, stones, a pond, vegetation, and gatherable resources.
- Six persistent inhabitants across three species: Pipkins, Mossbacks, and a Lumenmoth.
- Individual traits and changing needs influence autonomous activities.
- Creatures wander, explore, gather twigs and berries, eat, sleep, and visit one another.
- Repeated social encounters strengthen individual relationships; meaningful moments enter the world journal and creature memories.
- Simple shelter construction can emerge from gathered materials.
- A day/night clock, seasons, weather changes, rain, and plant growth.
- Player interventions: plant flowers, leave twigs, add berry plants, or make a little pond.
- Creature inspection and a world journal.
- Local JSON persistence, a rolling backup, and gentle offline catch-up capped at six hours.

## Controls

| Input | Action |
|---|---|
| Click a creature | Inspect that creature |
| Click **Observe** or press `1` | Return to inspection mode |
| Click **Plant a flower** or press `2` | Place a flower |
| Click **Leave twigs** or press `3` | Add building material |
| Click **Berry seed** or press `4` | Plant a berry bush |
| Click **Little pond** or press `5` | Add a water tile |
| `Space` | Pause / resume |
| Top-right pause control | Pause / resume |
| Journal button | Browse recent world events |

## Local data

The active save is stored at Godot's per-user application data location as `windowsill_world.json`, with `windowsill_world.backup.json` as a backup. It contains the world seed, map, plants, resources, creatures, identities, traits, needs, memories, relationships, structures, weather, clock, and journal. Nothing is uploaded.

## Project structure

```text
windowsill/
├── project.godot
├── scenes/
│   └── main.tscn
├── scripts/
│   ├── main.gd
│   └── world_simulation.gd
├── tests/
│   └── simulation_smoke.gd
└── docs/
    └── ROADMAP.md
```

## Run the simulation smoke test

With Godot installed, run this from the repository root:

```sh
godot --headless --path . --script tests/simulation_smoke.gd
```

The smoke test checks world generation, creature identity, basic state shape, and a short simulation run. It has been added to the project, but it has **not** been executed in this environment because the Godot executable is unavailable here.

## Development status

This is an early playable foundation, not the full game described in the original design. The current simulation uses utility-style action selection with simple movement; pathfinding around obstacles, richer ecology, births and ageing, complete multi-world management, robust database migrations, postcards, audio, compact companion mode, and performance scaling remain future work. The current visual style is procedural and intentionally asset-free; bespoke pixel-art assets and animation are still needed for a release-quality presentation.

See [docs/ROADMAP.md](docs/ROADMAP.md) for the next milestones.
