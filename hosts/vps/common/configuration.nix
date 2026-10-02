# Shared configuration for every self-hosted VPS host under hosts/vps/.
#
# A provider-specific host (hosts/vps/<provider>/configuration.nix) imports
# this file plus its own ./disk-config.nix and ./hardware-configuration.nix,
# and overrides whatever differs per provider: boot loader (BIOS vs UEFI), the
# public NIC used by the honeypot firewall (vps.publicInterface) and the DERP
# NAT ports.
#
# Like the desktop hosts this pulls in only the "core" + "basic" groups and a
# home-manager user; no GUI / X. os/server.nix adds the headless services.
{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    # disko itself; the actual layout lives in each host's ./disk-config.nix.
    inputs.disko.nixosModules.disko
  ];

  # --- Network ------------------------------------------------------------
  # DHCP on the virtio NIC, same as the cloud images did.
  networking.useDHCP = true;
  networking.firewall.enable = true;

  # --- SSH ----------------------------------------------------------------
  # Listen on 18622 on *all* interfaces. The public endpoint is NAT-forwarded
  # to guest :18622 (see the provider console); port 22 is deliberately left
  # free so the honeypot (os/server.nix) can take it over.
  # `openFirewall` defaults to true, so this port is opened automatically.
  services.openssh = {
    enable = true;
    ports = [ 18622 ];
    # Accept keys from ~/.ssh/authorized_keys. That file is pushed in at
    # install time (nixos-anywhere --extra-files), so no key lives in git.
    authorizedKeysInHomedir = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
      # Cloud NAT presents every inbound connection with the SAME source IP,
      # so unrelated SSH brute-force from the internet trips OpenSSH's
      # per-source penalty and locks us out too ("Connection closed" /
      # "Not allowed at this time"). Disable it; rely on keys + password auth.
      PerSourcePenalties = "no";
      # Accept env vars pushed by the client via `ssh -o SetEnv=...`, e.g. so
      # `ssh -R 7890:localhost:7890 -o SetEnv=http_proxy=http://localhost:7890`
      # makes tools on the server fetch through the client's proxy.
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

  # --- Secrets ------------------------------------------------------------
  # No password hashes or keys in this repo. `hashedPasswordFile` is read at
  # activation time from a file that the deploy step copies in:
  #   nixos-anywhere ... --extra-files ./secrets/vps
  # (./secrets is gitignored.) Remove the files / switch to agenix or sops-nix
  # if you later want them managed declaratively.
  users.users.root.hashedPasswordFile = "/var/lib/nixos-secrets/root.hash";

  users.users.pem = {
    isNormalUser = true;
    group = "pem";
    extraGroups = [ "wheel" "users" ];
    hashedPasswordFile = "/var/lib/nixos-secrets/pem.hash";
    # Keep this user's systemd services running after logout, so rootless
    # pods (containers declared with `podman.user = "pem"`) start at boot.
    linger = true;
  };
  users.groups.pem = { };

  # --- Small VM (no swap) -------------------------------------------------
  # zram gives the updater/builder some breathing room without a swap file.
  zramSwap.enable = true;

  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "en_US.UTF-8";

  system.stateVersion = "26.05";
}
