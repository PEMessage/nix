# fix-gradle-console - repair the native library the Gradle wrapper drops in
# the user's cache.
#
# A wrapper-downloaded Gradle distribution extracts
# libnative-platform-curses.so into ~/.gradle/native without a RUNPATH, so a
# nixpkgs-built JDK's dlopen cannot resolve its NEEDED entries
# (libncursesw.so.6, libtinfo.so.6) and Gradle's rich console auto-detection
# falls back to plain. Give the cached .so a RUNPATH in place instead of
# pinning org.gradle.console=rich, which would also override the correct
# plain-console choice when output is piped or run by CI/an agent.
#
# The RUNPATH is rewritten whenever it differs from the expected one:
# --set-rpath is idempotent, and re-patching refreshes dangling store paths
# after a nixpkgs update or garbage collection. Because it works on whatever
# is currently in the cache, it is version-agnostic: a wrapper bump that ships
# a new native-platform version just creates a new cache directory.
#
# See https://britter.dev/blog/2026/10/20/poor-mans-gradle-console-fix/
{
  lib,
  writeShellApplication,
  patchelf,
  ncurses,
  stdenv,
}:
writeShellApplication {
  name = "fix-gradle-console";

  runtimeInputs = [ patchelf ];

  text = ''
    nativeDir="''${GRADLE_USER_HOME:-$HOME/.gradle}/native"
    rpath="${
      lib.makeLibraryPath [
        ncurses
        stdenv.cc.cc.lib
      ]
    }"

    if [ ! -d "$nativeDir" ]; then
      echo "No native cache at $nativeDir, nothing to fix." >&2
      exit 0
    fi

    patched=0
    while IFS= read -r -d "" so; do
      current="$(patchelf --print-rpath "$so")"
      if [ "$current" != "$rpath" ]; then
        echo "Patching $so"
        patchelf --set-rpath "$rpath" "$so"
        patched=$((patched + 1))
      fi
    done < <(find "$nativeDir" -name 'libnative-platform-curses.so' -type f -print0)

    echo "Patched $patched libraries. Rich console should work again."
  '';

  meta = with lib; {
    description = "Patch Gradle's cached native-platform curses library with a RUNPATH";
    homepage = "https://britter.dev/blog/2026/10/20/poor-mans-gradle-console-fix/";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "fix-gradle-console";
  };
}
