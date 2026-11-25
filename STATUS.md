# Status

Last updated: 2026-11-25. Target: Minecraft 1.21.11, Fabric.

**Honest summary: all 14 patches compile and package. None has been run in a real game yet.** Treat every jar you build as untested until the launch checklist below is ticked.

## Mods

| Mod | Upstream branch | Compiles | Tested in game |
|-----|-----------------|----------|----------------|
| YUNG's API | 1.21.4 | yes | no |
| Menu Tweaks | 1.21.4 | yes | no |
| Extras | 1.21.4 | yes | no |
| Bridges | 1.21.4 | yes | no |
| Better Dungeons | 1.21.4 | yes | no |
| Better Mineshafts | 1.21.4 | yes | no |
| Better Strongholds | 1.21.4 | yes | no |
| Better Nether Fortresses | 1.21.4 | yes | no |
| Better Witch Huts | 1.21.4 | yes | no |
| Better Jungle Temples | 1.21.4 | yes | no |
| Better Ocean Monuments | 1.21.4 | yes | no |
| Better Desert Temples | 1.21.4 | yes | no |
| Better End Island | 1.21.4 | yes | no |
| Better Caves | 1.21.1 | yes | no |

Not included: Cave Biomes (upstream license is "All Rights Reserved"), Better Portals (Forge 1.16 only).

## Known risk areas (compile success does not cover these)

- **Mixins.** A changed target signature compiles fine but can crash at launch. Highest risk: API `BeardifierMixin` (the `Beardifier` class was restructured), End Island and Desert Temples `ServerLevel` constructor mixins, Menu Tweaks `CycleButton.onPress`.
- **Entity NBT format.** Since 1.21.5, mobs store worn items under `equipment` instead of `ArmorItems`. Desert Temples' pharaoh detection now reads both; this is untested.
- **EntityType peaceful flag.** The API passes `true` for the new "allowed in peaceful" constructor argument; this is a default we chose.
- **Better Caves** jumps from the 1.21.1 branch across several Minecraft versions; carver registration changed (carving step removed).
- **Structure overlap** with other structure mods is not tested.

## Launch checklist (nobody has done this yet)

- [ ] Fabric Loader 0.20.1+, Fabric API 0.141.6+1.21.11, all 14 jars in `mods`, game reaches the title screen
- [ ] New world loads and generates chunks without crashes
- [ ] Each structure type found and entered (`/locate structure`)
- [ ] Desert Temple pharaoh spawns and the temple state saves/loads
- [ ] End Island: dragon fight works
- [ ] Menu Tweaks: right-click on cycle buttons, scroll on sliders
- [ ] Quit and reload the world

Please report results (including crash logs) as issues so this table can be updated.
