{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  chrome-zh = pkgs.google-chrome.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
    postFixup = (old.postFixup or "") + ''
      wrapProgram "$out/bin/google-chrome-stable" --set LANG zh_CN.UTF-8
    '';
  });
in {
  disabledModules = [ "programs/clash-verge.nix" ];
  imports = [
    "${inputs.nixpkgs-unstable}/nixos/modules/programs/clash-verge.nix"
    ./waynergy
  ];

  environment.systemPackages = with pkgs; [
    ghostty
    chrome-zh
    xclip
    wl-clipboard
  ];

  services.flatpak = {
    enable = true;
  };

  # TLS client certificate is generated once and stored at
  # ~/.config/waynergy/tls/cert (private key + cert PEM). To make it fully
  # reproducible, copy it into this repo and set:
  #   waynergy.tls.clientCertificate = ./secrets/waynergy-tls-cert;
  waynergy = {
    enable = config.programs.niri.enable;
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # Use the nixpkgs-unstable clash-verge module instead of the stable one:
  # stable's module sets ProtectSystem=strict without StateDirectory, so the
  # service cannot create /var/lib/clash-verge-service ("failed to create
  # desired state directory"). The unstable module ships StateDirectory.
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
