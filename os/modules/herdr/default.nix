# herdr - patched to emit classic 16-color SGR for palette indices 0-15.
#
# herdr re-encodes every palette color as 38;5;N (256-color form) when
# re-emitting SGR to the host terminal. Windows Terminal's bold-as-bright only
# brightens classic 16-color SGR (30-37/90-97), so bold text stayed normal color
# with bold font weight instead of becoming bright. Emitting classic 16-color
# SGR for indices 0-15 lets the host terminal apply its own bold-is-bright policy.
# See refs/herdr-bold-bright-issue.md.
#
# Uses herdr 0.8.2 (nixpkgs-unstable still ships 0.8.0, so version, src, and the
# precomputed cargoDeps/zigDeps are overridden below; the rest of the upstream
# recipe is inherited from pkgs.unstable.herdr).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  herdr-src = pkgs.unstable.fetchFromGitHub {
    owner = "herdrdev";
    repo = "herdr";
    tag = "v0.8.2";
    hash = "sha256-sEGIN3dLZasaHob3EHscWBCIQHflMQVchYmzgsETDk4=";
  };

  # buildRustPackage precomputes the vendored deps (cargoDeps) and bakes the
  # zigDeps path into the build script at finalAttrs-fixpoint time, so bumping
  # cargoHash/zigDeps.hash alone via overrideAttrs has no effect. Instead we
  # rebuild those precomputed values for 0.8.2 and re-point postConfigure at the
  # new zigDeps. All other recipe attrs (nativeBuildInputs, postInstall, meta,
  # doCheck, ...) are inherited from the original package.
  herdr-cargoDeps = pkgs.unstable.rustPlatform.fetchCargoVendor {
    src = herdr-src;
    name = "herdr-0.8.2-vendor";
    hash = "sha256-4VThqPwYYEsGvaOKjBeL6XAC5bnNWB6oUMWP/uXc/UQ=";
  };

  herdr-zigDeps = pkgs.unstable.zig_0_15.fetchDeps {
    pname = "herdr";
    version = "0.8.2";
    src = "${herdr-src}/vendor/libghostty-vt";
    fetchAll = true;
    hash = "sha256-PnM+hZIlLyQwK8vJgd/Bhjt1lNIz06T8FahwliRmMrY=";
  };

  # herdr-patched is defined at top-level scope so it can be shared between the
  # package list and any future service config (mirrors waynergy.nix's pattern).
  herdr-patched = pkgs.unstable.herdr.overrideAttrs (old: {
    version = "0.8.2";
    src = herdr-src;
    cargoDeps = herdr-cargoDeps;
    zigDeps = herdr-zigDeps;

    postConfigure = ''
      export ZIG_GLOBAL_CACHE_DIR=$(mktemp -d)
      cp -rL ${herdr-zigDeps} "$ZIG_GLOBAL_CACHE_DIR/p"
      chmod -R u+w "$ZIG_GLOBAL_CACHE_DIR/p"
    '';

    postPatch = (old.postPatch or "") + ''
      substituteInPlace src/protocol/render_ansi.rs \
        --replace-fail \
          '0x01 => format!("38;5;{}", val & 0xFF), // Indexed' \
          '0x01 => match val & 0xFF {
              0x00 => "30".to_owned(), // Black
              0x01 => "31".to_owned(), // Red
              0x02 => "32".to_owned(), // Green
              0x03 => "33".to_owned(), // Yellow
              0x04 => "34".to_owned(), // Blue
              0x05 => "35".to_owned(), // Magenta
              0x06 => "36".to_owned(), // Cyan
              0x07 => "37".to_owned(), // Gray (light gray)
              0x08 => "90".to_owned(), // DarkGray
              0x09 => "91".to_owned(), // LightRed
              0x0A => "92".to_owned(), // LightGreen
              0x0B => "93".to_owned(), // LightYellow
              0x0C => "94".to_owned(), // LightBlue
              0x0D => "95".to_owned(), // LightMagenta
              0x0E => "96".to_owned(), // LightCyan
              0x0F => "97".to_owned(), // White
              idx => format!("38;5;{idx}"),
          },'
      substituteInPlace src/protocol/render_ansi.rs \
        --replace-fail \
          '0x01 => format!("48;5;{}", val & 0xFF), // Indexed' \
          '0x01 => match val & 0xFF {
              0x00 => "40".to_owned(),  // Black
              0x01 => "41".to_owned(),  // Red
              0x02 => "42".to_owned(),  // Green
              0x03 => "43".to_owned(),  // Yellow
              0x04 => "44".to_owned(),  // Blue
              0x05 => "45".to_owned(),  // Magenta
              0x06 => "46".to_owned(),  // Cyan
              0x07 => "47".to_owned(),  // Gray (light gray)
              0x08 => "100".to_owned(), // DarkGray
              0x09 => "101".to_owned(), // LightRed
              0x0A => "102".to_owned(), // LightGreen
              0x0B => "103".to_owned(), // LightYellow
              0x0C => "104".to_owned(), // LightBlue
              0x0D => "105".to_owned(), // LightMagenta
              0x0E => "106".to_owned(), // LightCyan
              0x0F => "107".to_owned(), // White
              idx => format!("48;5;{idx}"),
          },'
    '';
  });
in
{
  options.herdr = {
    enable = lib.mkEnableOption "herdr (patched for classic 16-color SGR)";
  };

  config = lib.mkIf config.herdr.enable {
    environment.systemPackages = [ herdr-patched ];
  };
}
