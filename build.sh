#!/usr/bin/env bash
# Builds the unofficial 1.21.11 Fabric port of YUNG's mods from the official sources + our patches.
# Needs: git, JDK 21 on PATH, internet. Output jars go to ./dist
# Usage: ./build.sh [ModName ...]   (default: every mod in mods.txt; YUNGs-API is always built first)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
WORK="$ROOT/work"; DIST="$ROOT/dist"; mkdir -p "$WORK" "$DIST"
command -v java >/dev/null || { echo "JDK 21 not found on PATH"; exit 1; }
java -version 2>&1 | grep -q 'version "21' || echo "WARNING: JDK 21 is expected; found: $(java -version 2>&1 | head -1)"

want=("$@")
build_one() {
  local name="$1" repo="$2" commit="$3" patch="$ROOT/patches/$1-1.21.11.patch"
  [ -f "$patch" ] || { echo "skip $name (no patch yet)"; return 0; }
  echo "=== $name"
  rm -rf "$WORK/$name"
  git clone --quiet "https://github.com/$repo.git" "$WORK/$name"
  git -C "$WORK/$name" checkout --quiet "$commit"
  git -C "$WORK/$name" apply --whitespace=nowarn "$patch"
  ( cd "$WORK/$name"
    chmod +x gradlew
    if [ "$name" = "YUNGs-API" ]; then
      ./gradlew :Common:publishToMavenLocal :Fabric:publishToMavenLocal -q --no-daemon -I "$ROOT/tools/no-signing.init.gradle" -x :Common:javadoc -x :Fabric:javadoc
    fi
    ./gradlew :Fabric:build -q --no-daemon -I "$ROOT/tools/no-signing.init.gradle" )
  cp "$WORK/$name"/Fabric/build/libs/*-Fabric-*[0-9].jar "$DIST"/
}

# Order matters: the API must be built and published locally first.
while IFS='|' read -r name repo commit; do
  case "$name" in ''|\#*) continue;; esac
  if [ ${#want[@]} -gt 0 ] && [ "$name" != "YUNGs-API" ] && ! printf '%s\n' "${want[@]}" | grep -qx "$name"; then continue; fi
  build_one "$name" "$repo" "$commit"
done < "$ROOT/mods.txt"
echo; echo "Done. Jars in $DIST"
