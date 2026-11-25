# YUNG's mods: unofficial Fabric port to Minecraft 1.21.11

Unofficial patches that let [YUNG's mods](https://github.com/YUNG-GANG) build for **Minecraft 1.21.11 on Fabric**.

> **Not affiliated with YUNG (YUNGNICKYOUNG) or YUNG-GANG.** All mod code, art and data belong to their authors.
> This repository contains only the *changes* we made, plus build tooling and documentation. It contains no upstream source and no compiled mod files.
> If you want the official versions, use the links in [docs/UPSTREAM.md](docs/UPSTREAM.md).

## Why this exists

YUNG's official repositories publish one branch per Minecraft version. At the time of writing there is a `1.21.4` branch and a `26.1.2` branch, but **no `1.21.11` branch** (Better Caves has `1.21.1` and `26.1.2`). Players on 1.21.11 therefore had no matching build. This project adapts the `1.21.4` code (the `1.21.1` code for Better Caves) to the 1.21.11 Minecraft API.

If you play on `26.1.2`, use the official builds instead.

## What is covered

| Mod | Upstream branch used | Status |
|-----|----------------------|--------|
| YUNG's API | `1.21.4` | builds, see [STATUS.md](STATUS.md) |
| YUNG's Menu Tweaks | `1.21.4` | builds |
| Remaining mods | see [STATUS.md](STATUS.md) | in progress |

"Builds" means it compiles and packages. It does **not** mean it has been tested in a running game. See [STATUS.md](STATUS.md) for what has been checked.

Not included: YUNG's Cave Biomes (its license is "All Rights Reserved", so we do not redistribute changes to it) and YUNG's Better Portals (it only exists for old Forge versions).

## How to use it

You build the mods yourself. This keeps us from redistributing anyone else's compiled work, and lets you check exactly what you are running.

Requirements: Git, JDK 21, and an internet connection. Run:

```
./build.sh        # macOS / Linux
.\build.ps1       # Windows PowerShell
```

The script clones each official repository at the right branch, applies the patch from `patches/`, builds the Fabric jar, and copies the results to `dist/`. Copy the jars you want into your `mods` folder. You also need Fabric Loader 0.20.1+ and Fabric API 0.141.6+1.21.11 or newer.

Details: [docs/HOW-IT-WORKS.md](docs/HOW-IT-WORKS.md).

## How the port was done

[docs/PORTING-GUIDE.md](docs/PORTING-GUIDE.md) lists every Minecraft API change we had to adapt to, with before/after examples, so you can port other mods the same way.

## License

The patches are derivative works of LGPL-3.0 code and are distributed under **LGPL-3.0**. See [LICENSE](LICENSE) and [docs/UPSTREAM.md](docs/UPSTREAM.md).
