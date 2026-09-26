# Podman + /etc/containers for headless server hosts (imported by os/server.nix).
# System-side plumbing only; containers are user-level Quadlets declared via
# home-manager `services.podman` (see os/services/*.nix).
{ config, lib, pkgs, ... }:
{
  virtualisation.podman = {
    enable = true;

    # `docker` -> podman alias. No Docker-API socket (it is root-equivalent).
    dockerCompat = true;

    # Weekly reclaim of unused containers/networks/images.
    autoPrune = {
      enable = true;
      flags = [ "--all" ];
      dates = "weekly";
    };
  };

  # Common /etc/containers config (storage.conf, policy.json, ...).
  virtualisation.containers.enable = true;
  virtualisation.containers.registries.search = [
    "docker.io"
    "quay.io"
    "ghcr.io"
  ];

  # docker.io is unreachable here; resolve it via these mirrors (drop-in).
  # Third-party proxies: pin images by digest if you need integrity.
  environment.etc."containers/registries.conf.d/00-mirrors.conf".text = ''
    [[registry]]
      location = "docker.io"
      [[registry.mirror]]
        location = "docker.m.daocloud.io"
      [[registry.mirror]]
        location = "docker.1ms.run"
  '';

  # Container logging defaults (drop-in, keeps the module's config intact).
  environment.etc."containers/containers.conf.d/00-common.conf".text = ''
    [containers]
    log_driver = "journald"

    [engine]
    events_logger = "journald"
  '';
}
