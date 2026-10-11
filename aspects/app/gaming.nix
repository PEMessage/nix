{ ... }:
{
  flake.aspects.gaming = {
    nixos = { ... }: {
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
      };
    };
  };
}
