{ ... }:
{
  flake.aspects.docker.nixos =
    { pkgs, ... }:
    {
      virtualisation.docker.enable = true;
      environment.systemPackages = [ pkgs.docker-compose ];
    };
}
