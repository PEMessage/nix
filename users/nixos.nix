{ ... }:
{
  flake.aspects."user.nixos".nixos = {
    users.users.nixos.extraGroups = [ "dialout" ];
    home-manager.users.nixos = { };
  };
}
