# vps cloud VM (KubeVirt), installed remotely with nixos-anywhere.
#
# Unlike the desktop hosts this pulls in only the "core" + "dev" groups and a
# home-manager user; no GUI / X.
{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "vps";

  # --- Boot ---------------------------------------------------------------
  # BIOS + GPT (see disk-config.nix). systemd-boot needs EFI, so GRUB it is.
  #
  # Do NOT set `boot.loader.grub.device(s)` here: because disk-config.nix has an
  # EF02 (BIOS boot) partition, disko already injects
  # `boot.loader.grub.devices = [ "/dev/vda" ]`. Setting it again makes
  # `mirroredBoots` contain the device twice and trips the assertion
  # "You cannot have duplicated devices in mirroredBoots".
  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = false;

  # --- Network ------------------------------------------------------------
  # DHCP on the virtio NIC, same as the cloud image did.
  networking.useDHCP = true;
  networking.firewall.enable = true;

  # --- Self-hosted DERP relay ---------------------------------------------
  # The public IP is deliberately NOT in git: hostFile is pushed in at deploy
  # time (see --extra-files ./secrets/vps) and read via systemd LoadCredential.
  # The provider's NAT maps public :10228 -> this VM's :10164 for BOTH DERP/TCP
  # and STUN/UDP, so `stun` just inherits `derp`.
  services.ipDerper = {
    enable = true;
    hostFile = "/var/lib/nixos-secrets/derper-host";
    derp.publicPort = 10228;
    derp.listenPort = 10164;
  };

  # --- SSH ----------------------------------------------------------------
  # Listen on 18622 on *all* interfaces. The cloud NAT forwards the public
  # endpoints -> guest :18622 (see the qiniu console / deploy secrets); port 22
  # is deliberately left free so a honeypot can take it over later.
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
      # The cloud NAT presents every inbound connection with the SAME source IP,
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

  # --- Small VM (1.9 GiB, no swap) ---------------------------------------
  # zram gives the updater/builder some breathing room without a swap file.
  zramSwap.enable = true;

  time.timeZone = "Asia/Shanghai";
  i18n.defaultLocale = "en_US.UTF-8";

  system.stateVersion = "26.05";
}
