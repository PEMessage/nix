{ inputs, ... }:
{
  flake.aspects.core-app = {
    nixos =
      { pkgs, ... }:
      let
        # force zh_CN locale for Chrome (crisper Chinese font rendering)
        chrome-zh = pkgs.google-chrome.overrideAttrs (old: {
          nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
          postFixup = (old.postFixup or "") + ''
            wrapProgram "$out/bin/google-chrome-stable" --set LANG zh_CN.UTF-8
          '';
        });
      in
      {
        disabledModules = [ "programs/clash-verge.nix" ];
        imports = [ "${inputs.nixpkgs-unstable}/nixos/modules/programs/clash-verge.nix" ];

        environment.systemPackages = with pkgs; [
          ghostty
          chrome-zh
          xclip
          wl-clipboard
        ];

        programs.clash-verge = {
          enable = true;
          group = "users";
          package = pkgs.unstable.clash-verge-rev;
          serviceMode = true;
          tunMode = true;
          autoStart = true;
        };

        programs.localsend = {
          enable = true;
          openFirewall = true;
        };
      };
  };
}
