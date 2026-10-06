# Deploys a Docker Compose project (static index + reverse proxy) and runs it
# as a systemd oneshot service.
#
# The project files are installed under /etc so the compose file can use normal
# relative bind mounts (`./index/...`, `./proxy/...`) the way any hand-written
# compose setup would. `docker compose up` pulls the images at start through the
# registry mirrors in /etc/docker/daemon.json.
{ config, lib, pkgs, ... }:
let
  projectDir = "/etc/docker-compose/vps";
in
{
  environment.etc = {
    "docker-compose/vps/docker-compose.yml".source = ./docker-compose.yml;
    "docker-compose/vps/index/index.html".source = ./index/index.html;
    "docker-compose/vps/proxy/default.conf".source = ./proxy/default.conf;
  };

  systemd.services.docker-compose-vps = {
    description = "Docker Compose project (index + reverse proxy)";
    wantedBy = [ "multi-user.target" ];
    after = [ "docker.service" "network-online.target" ];
    wants = [ "network-online.target" ];
    requires = [ "docker.service" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      WorkingDirectory = projectDir;
      ExecStart = "${pkgs.docker-compose}/bin/docker-compose up -d --remove-orphans";
      ExecStop = "${pkgs.docker-compose}/bin/docker-compose down";
      ExecReload = "${pkgs.docker-compose}/bin/docker-compose up -d --remove-orphans";
    };
  };
}
