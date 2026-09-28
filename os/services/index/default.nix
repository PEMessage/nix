# Static landing page (rootless podman nginx), as a home-manager service. Joins
# the `proxy` podman network under the name `index`, so the reverse proxy can
# route "/" to http://index:80; it publishes no host port.
{ config, lib, pkgs, ... }:
{
  options.services.index.enable = lib.mkEnableOption "static index page (rootless podman nginx)";

  config = lib.mkIf config.services.index.enable (
    let
      # Pulled at build time, same pattern as os/services/opencanary.nix.
      image = pkgs.dockerTools.pullImage {
        imageName = "library/nginx";
        finalImageName = "library/nginx";
        finalImageTag = "alpine";
        imageDigest = "sha256:1ed1b0e1d7652937d6cbdaf4018c7b6fc009a7dd6c3047351e2eddda745de43f";
        sha256 = "sha256-HVBasxshtevNUW7GNG0APuqIlTdvNRl1DUFnbufCtMY=";
        os = "linux";
        arch = "amd64";
      };
    in
    {
      services.podman = {
        enable = true;

        images.index = {
          image = "docker-archive:${image}";
          tag = "library/nginx:alpine";
        };

        containers.index = {
          description = "Static index page";
          image = "index.image";
          network = [ "proxy.network" ];
          # Default nginx config serves /usr/share/nginx/html.
          volumes = [ "${./src}:/usr/share/nginx/html:ro" ];
        };
      };
    }
  );
}
