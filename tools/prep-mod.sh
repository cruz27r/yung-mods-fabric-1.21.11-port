#!/usr/bin/env bash
# Usage: prep-mod.sh <mod-dir>   Applies the shared 1.21.4 -> 1.21.11 (Fabric) build + mechanical API changes.
set -e
cd "$1"
git checkout -q -B port-1.21.11
P=gradle.properties
sed -i -e 's/^mc_version=.*/mc_version=1.21.11/' -e 's/^mc_version_range=.*/mc_version_range=[1.21.11, 1.22)/' \
 -e 's/^mc_version_range_fabric=.*/mc_version_range_fabric=>=1.21.11/' -e 's/^parchment_minecraft=.*/parchment_minecraft=1.21.11/' \
 -e 's/^parchment_version=.*/parchment_version=2025.12.20/' -e 's/^compatible_versions=.*/compatible_versions=1.21.11/' \
 -e 's/^fabric_version=.*/fabric_version=0.141.6/' -e 's/^fabric_loader_version=.*/fabric_loader_version=0.20.1/' \
 -e 's/^clothconfig_version_fabric=.*/clothconfig_version_fabric=21.11.153/' -e 's/^modmenu_version_fabric=.*/modmenu_version_fabric=17.0.1/' \
 -e 's/^yungsapi_version=.*/yungsapi_version=5.4.0/' $P
sed -i -E "s/(fabric-loom' version ')[^']+/\11.13-SNAPSHOT/" build.gradle
sed -i 's/gradle-[0-9.]*-bin/gradle-8.14.3-bin/' gradle/wrapper/gradle-wrapper.properties
sed -i 's/includeGroup("net.fabricmc")/includeGroupAndSubgroups("net.fabricmc")/' settings.gradle
# Local YUNG's API build (published with publishToMavenLocal)
grep -q mavenLocal buildSrc/src/main/groovy/multiloader-common.gradle || \
 sed -i '0,/repositories {/s//repositories {\n    mavenLocal()/' buildSrc/src/main/groovy/multiloader-common.gradle
files=$(grep -rlE "ResourceLocation|net\.minecraft\.Util|MethodsReturnNonnullByDefault" --include=*.java Common Fabric 2>/dev/null || true)
if [ -n "$files" ]; then
 sed -i -e 's/\bResourceLocation\b/Identifier/g' -e 's/net\.minecraft\.resources\.Identifier/net.minecraft.resources.Identifier/' \
  -e 's/import net\.minecraft\.Util;/import net.minecraft.util.Util;/' -e '/MethodsReturnNonnullByDefault/d' $files
fi
wall=$(grep -rlE 'WallBlock\.(NORTH|SOUTH|EAST|WEST)_WALL' --include=*.java Common Fabric 2>/dev/null || true)
if [ -n "$wall" ]; then sed -i -E 's/WallBlock\.(NORTH|SOUTH|EAST|WEST)_WALL/WallBlock.\1/g' $wall; fi
# --- common API shifts (NBT getters now return Optional, weighted lists, chains, chunk flags) ---
java=$(grep -rlE '.' --include=*.java Common Fabric 2>/dev/null || true)
if [ -n "$java" ]; then
 sed -i -E \
  -e 's/\.getInt\(("[^"]+")\)/.getIntOr(\1, 0)/g' \
  -e 's/\.getFloat\(("[^"]+")\)/.getFloatOr(\1, 0f)/g' \
  -e 's/\.getDouble\(("[^"]+")\)/.getDoubleOr(\1, 0.0)/g' \
  -e 's/\.getLong\(("[^"]+")\)/.getLongOr(\1, 0L)/g' \
  -e 's/\.getBoolean\(("[^"]+")\)/.getBooleanOr(\1, false)/g' \
  -e 's/\.getString\(("[^"]+")\)/.getStringOr(\1, "")/g' \
  -e 's/\.getList\(("[^"]+"), *[0-9]+\)/.getListOrEmpty(\1)/g' \
  -e 's/SimpleWeightedRandomList\.single\(/WeightedList.of(/g' \
  -e 's/SimpleWeightedRandomList\.empty\(\)/WeightedList.of()/g' \
  -e 's/SimpleWeightedRandomList/WeightedList/g' \
  -e 's/\bBlocks\.CHAIN\b/Blocks.IRON_CHAIN/g' \
  -e '/getChunk\(.*\)\.setBlockState\(/ s/, false\);/, 0);/' \
  $java
fi
if [ -n "$java" ]; then
 perl -pi -e 's/\.getIntArray\(("[^"]+")\)(?!\.orElse)/.getIntArray($1).orElse(new int[0])/g' $java
fi
if [ -n "$java" ]; then
 # chunk.setBlockState(pos, state, false) -> flags int; multi-line calls included
 perl -0pi -e 's/(getChunk\([^;]*?\)\.setBlockState\((?:(?!;).)*?),(\s*)false\);/$1,${2}0);/gs' $java
 # ResourceKey.location() -> identifier() in structure-locate command mixins
 perl -pi -e 's/optional\.get\(\)\.location\(\)/optional.get().identifier()/g; s/\.getList\(("[^"]+"),\s*[A-Za-z_.]+\)/.getListOrEmpty($1)/g' $java
fi
if [ -n "$java" ]; then
 perl -pi -e 's/\.getCompound\(("[^"]+")\)/.getCompoundOrEmpty($1)/g' $java
fi
if [ -n "$java" ]; then
 perl -pi -e 's/projectile\.(AbstractArrow|ThrownTrident|Arrow|SpectralArrow)\b/projectile.arrow.$1/g; s/\b(\w*(?:List|Nbt|NBT|Tag)\w*)\.getFloat\((\w+)\)/$1.getFloatOr($2, 0f)/g' $java
fi
if [ -n "$java" ]; then
 perl -pi -e '
  s/vehicle\.(Minecart\w*|AbstractMinecart)\b/vehicle.minecart.$1/g;
  s/\.getIntArray\((\w+)\)\[/.getIntArray($1).orElseThrow()[/g;
  s/\.requires\(\(?(\w+)\)? -> \1\.hasPermission\(1\)\)/.requires(Commands.hasPermission(Commands.LEVEL_MODERATORS))/g;
  s/\.requires\(\(?(\w+)\)? -> \1\.hasPermission\(2\)\)/.requires(Commands.hasPermission(Commands.LEVEL_GAMEMASTERS))/g;
  s/\.requires\(\(?(\w+)\)? -> \1\.hasPermission\(3\)\)/.requires(Commands.hasPermission(Commands.LEVEL_ADMINS))/g;
  s/\.requires\(\(?(\w+)\)? -> \1\.hasPermission\(4\)\)/.requires(Commands.hasPermission(Commands.LEVEL_OWNERS))/g;
  s/\.(add|remove)RegionTicket\((TicketType\.\w+, [^;]*?), Unit\.INSTANCE\)/".".$1."TicketWithRadius(".$2.")"/ge;
  s/(BuiltinDimensionTypes\.\w+)\.location\(\)/$1.identifier()/g;
  s/\.dimension\(\)\.location\(\)/.dimension().identifier()/g;
 ' $java
fi
if [ -n "$java" ]; then
 perl -pi -e '
  next if /^import .*ChunkProgressListener;/ && ($_ = "");
  s/ChunkProgressListener \$\$\d+, //g;
  s/\b(\w*(?:List|Tag)\w*)\.getInt\((\w+)\)/$1.getIntOr($2, 0)/g;
  s/\b(endCrystal|crystal|entity)\.moveTo\(/$1.snapTo(/g;
 ' $java
fi
if [ -n "$java" ]; then
 perl -pi -e '
  s/entity\.monster\.(Zombie|Husk|Drowned|ZombieVillager|ZombifiedPiglin)\b/entity.monster.zombie.$1/g;
  s/\bMobEffects\.DIG_SLOWDOWN\b/MobEffects.MINING_FATIGUE/g;
  s/\.getProperties\(\)/.properties()/g;
  s/\b(chunk\w*)\.setBlockState\((.*), false\);/$1.setBlockState($2, 0);/g;
  s/\.getDouble\((\d+)\)/.getDoubleOr($1, 0.0)/g;
  s/\.getCompound\((\d+)\)/.getCompoundOrEmpty($1)/g;
  $_ = "" if /^\s*ChunkProgressListener \w+,\s*$/;
 ' $java
fi
if [ -n "$java" ]; then
 perl -pi -e '
  s/\b(compoundTag|tag|nbt)\.getBoolean\(((?:[^()]|\([^()]*\))*)\)(?!, false)/$1.getBooleanOr($2, false)/g;
  s/addCarver\(GenerationStep\.Carving\.\w+, /addCarver(/g;
 ' $java
fi
