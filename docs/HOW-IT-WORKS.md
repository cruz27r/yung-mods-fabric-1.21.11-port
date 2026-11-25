# How the build works

## The idea

We do not store anyone else's code. Each mod is described by two things:

1. `mods.txt`: the official repository and an **exact upstream commit** (so patches keep applying even if upstream changes).
2. `patches/<Mod>-1.21.11.patch`: our changes on top of that commit.

`build.sh` / `build.ps1` combine them on your machine:

```
git clone  https://github.com/YUNG-GANG/<Mod>.git
git checkout <pinned commit>
git apply patches/<Mod>-1.21.11.patch
./gradlew :Fabric:build
```

The jars end up in `dist/`. Copy them into your Minecraft `mods` folder.

## Requirements

- JDK 21 (the upstream build files use Java 21)
- Git
- Internet access for Gradle downloads (Minecraft, Fabric, Parchment mappings)
- First build takes a while; later builds are faster thanks to Gradle caches
- Minecraft 1.21.11, Fabric Loader 0.20.1 or newer, Fabric API 0.141.6+1.21.11 or newer

Some mods have extra runtime dependencies from upstream (for example Cloth Config and Mod Menu are optional config helpers). Check each upstream mod page for what it lists.

## Why YUNG's API is built first

Every Better* mod, Bridges, Extras and Menu Tweaks depend on YUNG's API. The script builds the API, installs it into your local Maven cache (`~/.m2`) with `publishToMavenLocal`, and the other builds pick it up from there. You also need the built API jar in your `mods` folder at runtime.

## Why signing is disabled

Upstream release builds are signed with the author's private key. Local builds cannot be, so `tools/no-signing.init.gradle` switches signing tasks off. This only affects the build on your machine.

## Building one mod

```
./build.sh YUNGs-Better-Dungeons        # builds the API first, then that mod
.\build.ps1 -Mods YUNGs-Better-Dungeons
```

## Fabric only

Upstream mods are "multi-loader" (Fabric and NeoForge from one codebase). We only target Fabric, and build the `:Fabric` project only.

## Troubleshooting

- `patch failed`: the pinned commit in `mods.txt` doesn't match your clone; do not edit patches by hand, re-clone.
- Gradle can't find Fabric Loom: you probably have an older Gradle wrapper, make sure the patch applied (it bumps Gradle to 8.14.3).
- Crash at world creation: please open an issue with the log. See [STATUS.md](../STATUS.md) for what has and has not been tested.
