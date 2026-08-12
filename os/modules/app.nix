{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.system};
in
{
  environment.systemPackages = with pkgs; [
    ghostty
    google-chrome
    deskflow
    xclip
  ];

  programs.clash-verge = {
    enable = true;
    # The group to grant access to clash-verge-rev’s service socket.
    group = "users";
    # latest from nixpkgs-unstable
    package = unstable.clash-verge-rev;
    serviceMode = true;
    tunMode = true;
    autoStart = true;
  };

  programs.localsend = {
    enable = true;
    openFirewall = true;
  };
}
