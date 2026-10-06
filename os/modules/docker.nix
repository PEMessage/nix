# Docker Engine + /etc/docker plumbing for headless server hosts (imported by
# os/server.nix). Compose projects are declared in os/services/compose.
{ config, lib, pkgs, ... }:
{
  virtualisation.docker = {
    enable = true;

    # Weekly reclaim of unused containers/networks/images.
    autoPrune = {
      enable = true;
      flags = [ "--all" ];
      dates = "weekly";
    };

    # docker.io is unreachable from these VMs; resolve it via these mirrors.
    # They are third-party proxies, so pin images by digest if you need
    # integrity guarantees.
    daemon.settings = {
      registry-mirrors = [
        "https://docker.m.daocloud.io"
        "https://docker.1ms.run"
      ];
    };
  };

  # Make the CLI available for interactive use; the systemd unit below uses the
  # store path directly.
  environment.systemPackages = [ pkgs.docker-compose ];
}
