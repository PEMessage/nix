# dms: DankMaterialShell — a complete Wayland desktop shell
# (panel, launcher, notification center, clipboard, lock screen).
{ config, lib, pkgs, inputs, ... }:
let
  user = config.home.userName;
in
{
  imports = [
    inputs.dms.nixosModules.default
  ];

  programs.dank-material-shell = {
    enable = true;
    # Autostart is handled by niri's spawn-at-startup below instead of the
    # systemd unit, matching the pattern noctalia used here.
  };

  # The graphical session can't read gsettings (no schemas in the session's
  # XDG_DATA_DIRS), so GTK/Qt fall back to the hardcoded default icon theme
  # "Adwaita". Installing the theme makes that fallback resolve; without it,
  # themed icons (e.g. the fcitx5 tray icon) render as black/pink checkered
  # placeholders.
  environment.systemPackages = [
    pkgs.adwaita-icon-theme
  ];

  # The NixOS module enables these services with mkDefault. On WSL hosts they
  # are useless (WSL2 does not expose power/geolocation hardware to Linux), so
  # disable them there; a plain assignment overrides the upstream mkDefault.
  # `config.wsl.enable or false` also keeps hosts that never import the
  # nixos-wsl module (e.g. pro830) from failing to evaluate.
  services.power-profiles-daemon.enable = !(config.wsl.enable or false);
  services.accounts-daemon.enable = !(config.wsl.enable or false);
  services.geoclue2.enable = !(config.wsl.enable or false);

  home-manager.users.${user} =
    { ... }:
    {
      programs.niri.settings = {
        # Start the shell with niri.
        spawn-at-startup = [
          {
            argv = [
              "dms"
              "run"
            ];
          }
        ];

        # Let the DMS wallpaper render behind windows instead of as a layer
        # that fights with the backdrop. See
        # https://danklinux.com/docs/dankmaterialshell/compositors#layer-rules
        layer-rules = [
          {
            matches = [
              {
                namespace = "^quickshell$";
              }
            ];
            place-within-backdrop = true;
          }
        ];

        # Niri binds that talk to DMS via its IPC.
        binds = {
          # Mod+D opens the DMS launcher.
          "Mod+D" = {
            hotkey-overlay = {
              title = "Open DMS Launcher";
            };
            action.spawn = [ "dms" "ipc" "call" "spotlight" "toggle" ];
          };
          # Mod+Alt+L locks the screen via DMS.
          "Mod+Alt+L" = {
            hotkey-overlay = { title = "Lock the Screen"; };
            action.spawn = [ "dms" "ipc" "call" "lock" "lock" ];
          };

          # Open the DMS clipboard panel.
          "Mod+V" = {
            hotkey-overlay = { title = "Open DMS Clipboard"; };
            action.spawn = [ "dms" "ipc" "call" "clipboard" "toggle" ];
          };
        };
      };
    };
}
