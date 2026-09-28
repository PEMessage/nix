# Centralised reverse proxy (rootless podman nginx), as a home-manager service.
# It only renders the `locations` table from os/server.nix into nginx config
# (see ./nginx.nix); nothing is proxied by default.
#
# It joins the `proxy` podman network, so upstreams can be sibling containers
# reached by name, and publishes `port` on the host. Reachability is up to the
# caller (this module says nothing about who may connect).
{ config, lib, pkgs, ... }:
let
  cfg = config.services.reverseProxy;
in
{
  options.services.reverseProxy = {
    enable = lib.mkEnableOption "reverse proxy (rootless podman nginx)";

    port = lib.mkOption {
      type = lib.types.port;
      description = "Host port to listen on.";
    };

    locations = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        "/" = "http://index:80";
      };
      description = "URL path -> upstream, rendered into nginx `location` blocks.";
    };
  };

  config = lib.mkIf cfg.enable (
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

      # Mounted as the image's envsubst template, so `${NGINX_LOCAL_RESOLVERS}`
      # becomes podman's DNS address at container start.
      conf = pkgs.writeText "default.conf" (
        (import ./nginx.nix { inherit lib; }).render { inherit (cfg) port locations; }
      );
    in
    {
      services.podman = {
        enable = true;

        images.reverse-proxy = {
          image = "docker-archive:${image}";
          tag = "library/nginx:alpine";
        };

        containers.reverse-proxy = {
          description = "Reverse proxy";
          image = "reverse-proxy.image";
          network = [ "proxy.network" ];
          ports = [ "${toString cfg.port}:${toString cfg.port}" ];
          environment.NGINX_ENTRYPOINT_LOCAL_RESOLVERS = "1";
          volumes = [ "${conf}:/etc/nginx/templates/default.conf.template:ro" ];
        };
      };
    }
  );
}
