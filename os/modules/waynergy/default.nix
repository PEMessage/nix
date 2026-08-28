# waynergy - Synergy-protocol Wayland client (adapted from WillsonHaw/dotfiles).
# Huge thanks to: https://github.com/WillsonHaw/dotfiles/blob/main/nixos/modules/apps/waynergy/default.nix

{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.waynergy;

  # Reduce UINPUT_KEY_MAX from 256 to 247 to exclude BTN_0 (evdev 256) from
  # the uinput keyboard device's key bit field.  Without this, libinput
  # misclassifies the device as having pointer capability, dropping all
  # keyboard events and breaking compositor shortcuts (Super+key in Niri).
  waynergy-patched = pkgs.waynergy.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace src/wl_input_uinput.c \
        --replace-fail '#define UINPUT_KEY_MAX 256' '#define UINPUT_KEY_MAX 247'
    '';
  });
in
{
  options.waynergy = {
    enable = lib.mkEnableOption "the waynergy KVM client.";

    host = lib.mkOption {
      type = lib.types.str;
      default = "192.168.123.74";
      description = "Synergy/Barrier server to connect to.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 24800;
      description = "Server port.";
    };

    name = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName;
      description = "Client screen name as configured on the server.";
    };

    backend = lib.mkOption {
      type = lib.types.enum [
        "wlr"
        "kde"
        "uinput"
      ];
      default = "uinput";
      description = "Input backend.";
    };

    # Windows scan codes coincide with Linux evdev for the main block; waynergy
    # works in XKB keycodes (evdev + 8), so non-remapped keys need this offset.
    xkbKeyOffset = lib.mkOption {
      type = lib.types.int;
      default = 8;
      description = "Raw keymap offset for non-remapped keys (xkb_key_offset).";
    };

    tls = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable TLS. The server requires a client certificate.";
      };

      tofu = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Trust on first use for the server certificate hash.";
      };

      clientCertificate = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          TLS client certificate (private key + certificate in one PEM file,
          as waynergy loads the same file for both), installed to
          ~/.config/waynergy/tls/cert with mode 0600. When null the
          certificate is left unmanaged.

          Generate it once with openssl:

            openssl req -x509 -newkey rsa:2048 -keyout cert -out cert.pub \
              -days 3650 -nodes -subj "/CN=$(hostname)-waynergy-client"
            cat cert.pub >> cert && rm cert.pub && chmod 600 cert
            install -Dm600 cert ~/.config/waynergy/tls/cert

          and add the certificate to the server's trusted client certificates.
        '';
      };
    };

    systemdService = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Manage waynergy as a systemd user service (auto-start with the graphical session).";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      waynergy-patched
    ];

    home-manager.sharedModules = [
      (
        { ... }:
        {
          # one-command waynergy TLS client certificate generation
          script.waynergy-tls-init = ./waynergy-tls-init;

          xdg.configFile."waynergy/config.ini" = lib.mkForce {
          force = true;
          text = ''
          host=${cfg.host}
          port=${toString cfg.port}
          name=${cfg.name}
          backend=${cfg.backend}
          xkb_key_offset=${toString cfg.xkbKeyOffset}

          [tls]
          enable=${if cfg.tls.enable then "true" else "false"}
          tofu=${if cfg.tls.tofu then "true" else "false"}

          [raw-keymap]
          ; Extended Windows scan codes. Values are XKB keycodes (evdev + 8);
          ; offset_on_explicit=0 prevents double-offsetting them.
          offset_on_explicit=0
          ; F13-F24 use PS/2 scan codes 100-111 (0x64-0x6F). Adding offset 8 puts
          ; them in the navigation key range (e.g. F20=107+8=115=End), so map
          ; them explicitly.
          100=191
          101=192
          102=193
          103=194
          104=195
          105=196
          106=197
          107=198
          108=199
          109=200
          110=201
          111=202
          ; Extended E0-prefixed Windows scan codes.
          347=133
          508=134
          312=108
          285=105
          349=135
          327=110
          328=111
          329=112
          331=113
          333=114
          335=115
          336=116
          337=117
          338=118
          339=119
          311=107
          284=104
          309=106
          '';
        };

        xdg.configFile."waynergy/tls/cert" = lib.mkIf (cfg.tls.clientCertificate != null) {
          source = cfg.tls.clientCertificate;
          mode = "0600";
        };

        systemd.user.services.waynergy = lib.mkIf cfg.systemdService {
          Unit = {
            Description = "Waynergy Synergy protocol client";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
          };
          Service = {
            ExecStart = "${waynergy-patched}/bin/waynergy";
            Restart = "on-failure";
            RestartSec = "3";
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };
      }
      )
    ];
  };
}
