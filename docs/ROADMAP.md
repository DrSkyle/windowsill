# Windowsill roadmap

## Phase 1 — Living prototype (current foundation)

- [x] Procedural meadow and terrain types
- [x] Three distinct species and six named inhabitants
- [x] Persistent identities, traits, needs, and current activities
- [x] Autonomous wandering, exploring, gathering, eating, resting, and social visits
- [x] Relationship growth and creature memories
- [x] Basic resource-based shelter construction
- [x] Day/night clock, weather, seasons, and plant growth
- [x] Local save/load, backup, and bounded offline catch-up
- [ ] Dedicated automated simulation tests and Godot CI runner
- [ ] More deliberate hand-authored pixel-art environment and creature animation

## Phase 2 — Social civilization

- [ ] Directional relationship model with friendship and rivalry thresholds
- [ ] Memory relevance and recall that changes later decisions
- [ ] Shared storage and communal shelter occupancy
- [ ] More construction stages and multiple contributors
- [ ] Birth, growth, ageing, and gentle lifecycle history
- [ ] Biography and searchable world timeline

## Phase 3 — Interactive terrarium

- [ ] Terrain painting and object relocation
- [ ] Plant species with water, soil, sunlight, and seasonal requirements
- [ ] More meaningful food webs and resource regeneration
- [ ] Rich inspection cards for creatures and structures
- [ ] Multiple named worlds with create, duplicate, export, import, and delete

## Phase 4 — Long-lived simulation

- [ ] More robust navigation and spatial partitioning
- [ ] Deterministic simulation replay and property-based tests
- [ ] SQLite-backed event history or another transactional save format
- [ ] Offline progression tests and migration framework
- [ ] Population and ecology stability tests at 30, 60, and 100 inhabitants

## Phase 5 — Desktop companion

- [ ] Compact always-on-top window
- [ ] Observation mode and reduced-motion setting
- [ ] Screenshot postcards and creature cards
- [ ] Local GIF/video capture where supported
- [ ] Locally bundled ambient audio
- [ ] Release packaging, signing, and platform-specific QA

## Acceptance gates

A milestone is not complete just because a control or panel exists. Each feature must be demonstrated in a running Godot build, backed by a relevant simulation or persistence test, and verified after closing and reopening the game. Network-disabled operation remains a release requirement.
