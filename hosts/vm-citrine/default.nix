# Host-specific NixOS module for vm-citrine: volatile config (remote access,
# network) plus the sops secrets wiring. The host imports it in
# `flake.nixosConfigurations.vm-citrine` below, i.e. it enables itself.
{ inputs, config, ... }:
{
  flake.modules.nixos."host.vm-citrine" =
    { config, ... }:
    {
      imports = [
        # disko itself; the layout lives in _nixos/disk-config.nix.
        inputs.disko.nixosModules.disko
        ./_nixos/disk-config.nix
      ];

      # --- Network ----------------------------------------------------------
      # DHCP on the virtio NIC, same as the cloud image did.
      networking.useDHCP = true;
      networking.firewall.enable = true;

      # --- SSH --------------------------------------------------------------
      # Listen on 18622 on all interfaces; the provider NAT-forwards its public
      # endpoint (:18622) to guest :18622. `openFirewall` defaults
      # to true, so the port is opened automatically.
      #
      # No authorized_keys live in git: log in with the root/pem password,
      # whose hash comes from sops (see below).
      services.openssh = {
        enable = true;
        ports = [ 18622 ];
        settings = {
          PermitRootLogin = "yes";
          PasswordAuthentication = true;
          # Cloud NAT presents every inbound connection with the SAME source IP,
          # so unrelated SSH brute-force from the internet trips OpenSSH's
          # per-source penalty and locks us out too ("Connection closed" /
          # "Not allowed at this time"). Disable it and rely on the random
          # password instead.
          PerSourcePenalties = "no";
          # Accept env vars pushed by the client via `ssh -o SetEnv=...`, e.g.
          # so `ssh -R 7890:localhost:7890 -o SetEnv=http_proxy=...` makes
          # tools on the server fetch through the client's proxy.
          AcceptEnv = [
            "http_proxy"
            "HTTP_PROXY"
            "https_proxy"
            "HTTPS_PROXY"
            "socks5h_proxy"
            "SOCKS5H_PROXY"
            "no_proxy"
            "NO_PROXY"
          ];
        };
      };

      # --- Small VM (no swap) ------------------------------------------------
      # zram gives the builder some breathing room without a swap file.
      zramSwap.enable = true;

      # --- Secrets (sops) ----------------------------------------------------
      # `secret.yaml` is encrypted to this host's age key, which lives on the
      # host at /var/lib/sops-nix/key.txt (core secrets aspect) and is shipped
      # only at onboard time (script/onboard.sh). See the secrets repo README.
      sops.defaultSopsFile = ./secret.yaml;

      # neededForUsers: read before users are created, so hashedPasswordFile
      # points at a file that already exists.
      sops.secrets."root-password-hash".neededForUsers = true;
      sops.secrets."pem-password-hash".neededForUsers = true;

      users.users.root.hashedPasswordFile = config.sops.secrets."root-password-hash".path;
      users.users.pem.hashedPasswordFile = config.sops.secrets."pem-password-hash".path;
    };

  flake.nixosConfigurations.vm-citrine = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ./_nixos/configuration.nix
      config.flake.modules.nixos."host.vm-citrine"
      config.flake.modules.nixos."user.pem"
      config.flake.modules.nixos.server
    ];
  };
}
