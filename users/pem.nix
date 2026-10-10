{ ... }:
{
  flake.aspects."user.pem".nixos =
    { pkgs, ... }:
    {
      users.users.pem = {
        isNormalUser = true;
        group = "pem"; # nixos-install prompt this !
        extraGroups = [
          # Enable 'sudo' for the user, backlight for brightnessctl.
          "wheel"
          "video"
          "users"

          # Enable uinput for waynergy
          "uinput"

          # Enable for /dev/ttyUSB0 access
          "dialout"
        ];
        packages = with pkgs; [
          tree
        ];
      };
      users.groups.pem = { }; # nixos-install prompt this !

      home-manager.users.pem = { };
    };
}
