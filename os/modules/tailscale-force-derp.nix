# Force Tailscale over DERP, plus the two things that make that usable in a
# throttled network:
#   1. FakeHTTP  - obfuscates TCP as HTTP so the ISP's whitelist upload throttle
#                  stops dropping the DERP connection (TCP).
#   2. BBR + fq + larger buffers - mitigates DERP's TCP-over-TCP cwnd collapse.
#
# Enable per host, e.g. in hosts/<host>/configuration.nix:
#   services.tailscaleForceDerp = { enable = true; interface = "enp3s0"; };
{ config, lib, pkgs, ... }:
let
  cfg = config.services.tailscaleForceDerp;
in
{
  options.services.tailscaleForceDerp = {
    enable = lib.mkEnableOption "Force Tailscale over DERP + FakeHTTP + BBR";

    interface = lib.mkOption {
      type = lib.types.str;
      example = "enp3s0";
      description = "Physical network interface that FakeHTTP operates on.";
    };

    fakeHost = lib.mkOption {
      type = lib.types.str;
      default = "test.ustc.edu.cn";
      description = "Whitelisted Host header FakeHTTP fakes, to bypass ISP upstream throttling.";
    };
  };

  config = lib.mkIf cfg.enable {
    # BBR + fq + bigger TCP buffers: the main fix for TCP-over-TCP over DERP.
    boot.kernelModules = [
      "tcp_bbr"
      "nfnetlink_queue"
    ];
    boot.kernel.sysctl = {
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.core.rmem_max" = 67108864;
      "net.core.wmem_max" = 67108864;
      "net.ipv4.tcp_rmem" = "4096 87380 67108864";
      "net.ipv4.tcp_wmem" = "4096 65536 67108864";
      "net.ipv4.tcp_mtu_probing" = 1;
      "net.ipv4.tcp_slow_start_after_idle" = 0;
    };

    # Disable UDP/direct; send all peer traffic over DERP. Start after FakeHTTP
    # so the DERP TCP handshake already gets the HTTP disguise.
    systemd.services.tailscaled = {
      after = [ "fakehttp.service" ];
      wants = [ "fakehttp.service" ];
      environment.TS_DEBUG_ALWAYS_USE_DERP = "1";
    };

    # Subnet router (forward LAN <-> tailnet). Manual, once, then approve the
    # route in the admin console:
    #   sudo tailscale set --advertise-routes=192.168.123.0/24 --snat-subnet-routes=false
    # LAN devices without Tailscale: route 100.64.0.0/10 via this host's LAN IP.
    services.tailscale.useRoutingFeatures = "server";

    # FakeHTTP: disguise TCP as HTTP (needs root + nfnetlink_queue + iptables).
    systemd.services.fakehttp = {
      description = "FakeHTTP (obfuscate TCP as HTTP to bypass ISP throttling)";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      path = [
        pkgs.iptables
        pkgs.kmod
      ];
      serviceConfig = {
        ExecStart = "${pkgs.fakehttp}/bin/fakehttp -4 -i ${cfg.interface} -z -h ${cfg.fakeHost}";
        Restart = "always";
        RestartSec = "3s";
      };
    };
  };
}
