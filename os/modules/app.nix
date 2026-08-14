{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    ghostty
    google-chrome
    xclip
  ];

  # Flatpak support (deskflow installed manually via flatpak).
  services.flatpak.enable = true;

  # Use the nixpkgs-unstable clash-verge module instead of the stable one:
  # stable's module sets ProtectSystem=strict without StateDirectory, so the
  # service cannot create /var/lib/clash-verge-service ("failed to create
  # desired state directory"). The unstable module ships StateDirectory.
  imports = [
    "${inputs.nixpkgs-unstable}/nixos/modules/programs/clash-verge.nix"
  ];
  disabledModules = [ "programs/clash-verge.nix" ];
  programs.clash-verge = {
    enable = true;
    # The group to grant access to clash-verge-rev’s service socket.
    group = "users";
    # latest from nixpkgs-unstable
    package = pkgs.unstable.clash-verge-rev;
    serviceMode = true;
    tunMode = true;
    autoStart = true;
  };

  programs.localsend = {
    enable = true;
    openFirewall = true;
  };
}
