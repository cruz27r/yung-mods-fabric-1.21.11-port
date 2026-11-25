# Porting guide: 1.21.4 to 1.21.11 (Fabric)

Everything here is a change we had to make to get YUNG's `1.21.4` code compiling on 1.21.11. Entries marked **seen** came up in this repository's builds. Entries marked **earlier port** come from our earlier manual port of the same mods and have not been re-verified here yet.

## 1. Build setup (every mod)

| File | Change | Why |
|------|--------|-----|
| `gradle.properties` | `mc_version=1.21.11`, `parchment_minecraft=1.21.11`, `parchment_version=2025.12.20`, `fabric_version=0.141.6`, `fabric_loader_version=0.20.1`, `compatible_versions=1.21.11` | Target the new version. `fabric_version` is written *without* the `+1.21.11` suffix: the build adds it. |
| `build.gradle` | Fabric Loom `1.10-SNAPSHOT` to `1.13-SNAPSHOT` | Loom 1.10 cannot handle 1.21.11. Loom 1.14 needs Gradle 9, so 1.13 is the safe pick on Gradle 8. |
| `gradle/wrapper/gradle-wrapper.properties` | Gradle `8.12` to `8.14.3` | Required by Loom 1.13. |
| `settings.gradle` | `includeGroup("net.fabricmc")` to `includeGroupAndSubgroups("net.fabricmc")` | Loom 1.13 pulls `net.fabricmc.unpick:*`, a subgroup the old filter blocked. |
| `buildSrc/.../multiloader-common.gradle` | add `mavenLocal()` | Lets the other mods find our locally built YUNG's API. |
| Signing | disable signing tasks locally (`tools/no-signing.init.gradle`) | Upstream release signing needs the author's private key. Local builds do not need it. |

Mods that depend on YUNG's API: build the API first and run `publishToMavenLocal`.

## 2. Minecraft API changes

**seen** (compiled and fixed in this repository):

| 1.21.4 | 1.21.11 |
|--------|---------|
| `net.minecraft.resources.ResourceLocation` | `net.minecraft.resources.Identifier` (rename only) |
| `net.minecraft.Util` | `net.minecraft.util.Util` |
| `@MethodsReturnNonnullByDefault` | removed; delete the annotation and import |
| `ResourceKey.location()` | `ResourceKey.identifier()` |
| `ResourceKey.create(registry, key)` where `key` is already a `ResourceKey` | pass the key through unchanged |
| `compoundTag.getInt("k")`, `getFloat`, `getString` | now return `Optional`; use `getIntOr("k", 0)`, `getFloatOr("k", 0f)`, `getStringOr("k", "")` |
| `compoundTag.getList("k", 10)` | `getListOrEmpty("k")` (type argument removed) |
| `SimpleWeightedRandomList<T>` / `.empty()` | `WeightedList<T>` / `WeightedList.of()` |
| `new Beardifier(Iterator, Iterator)` | `new Beardifier(List<Rigid>, List<JigsawJunction>, BoundingBox)`; the fields are now `pieces`, `junctions`, `affectedBox` (mixin accessors need updating) |
| `EntityType` constructor | gained a trailing `boolean` (allowed in peaceful); we pass `true`, which is a default we chose |
| `entity.moveTo(x, y, z, yaw, pitch)` | `entity.snapTo(...)` |
| `EntityType.create(CompoundTag, level, reason)` | takes a `ValueInput`: `TagValueInput.create(ProblemReporter.DISCARDING, registryAccess, tag)` |
| `Window.getWindow()` | `Window.handle()` |
| `Screen.hasShiftDown()` in a widget's `onPress` | `onPress(InputWithModifiers input)` now receives the modifiers; call `input.hasShiftDown()` (mixin descriptor changes) |
| `guiGraphics.blit(RenderType::guiTextured, ...)` | `guiGraphics.blit(RenderPipelines.GUI_TEXTURED, ...)`; drop `RenderSystem.enableBlend/disableBlend` |
| `OptionsList.children()` element type | no longer `OptionsList.Entry`; iterate as `Object` and pattern-match |

**earlier port** (to be re-verified as each mod is rebuilt):

- `LevelChunk.setBlockState(pos, state, boolean)` to `(pos, state, int flags)`
- `MobEffects.DIG_SLOWDOWN` to `MINING_FATIGUE`
- `WallBlock.EAST_WALL` etc. to `WallBlock.EAST`
- `LivingEntity.getArmorSlots()` removed; iterate `EquipmentSlot.values()` with `getItemBySlot`
- `GameProfile.getProperties()` to `properties()`
- `ServerLevel.<init>` mixins must not list `ChunkProgressListener`
- `Zombie`/`Husk` moved to `net.minecraft.world.entity.monster.zombie`

## 3. The silent failure: mixins

A mixin can compile fine and still crash at launch if its target method's descriptor changed. After a port, check every `@Inject`/`@Redirect`/`@Shadow` against the new method signature (we inspect the game jar with `javap -p`). Only launching the game proves a mixin applies.

## 4. How to find a replacement for a removed API

1. Locate the Loom-mapped game jar under your Gradle cache (`fabric-loom/minecraftMaven/.../minecraft-merged-*.jar`).
2. Run `javap -p -cp <jar> <fully.qualified.Class>` and read the new signatures.
3. Fix, rebuild, repeat.
