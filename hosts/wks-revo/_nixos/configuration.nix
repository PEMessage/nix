# Host-specific configuration for wks-revo (the workstation formerly known as
# pro830). Feature stacks live in aspects and are composed via the `desktop`
# profile; this file keeps only machine-specific bits: boot loader, hardware,
# hostname, locale, and the host-pinned network tweaks.
{ ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "wks-revo";

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Shanghai";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "zh_CN.UTF-8/UTF-8"
  ];
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "zh_CN.UTF-8";
    LC_IDENTIFICATION = "zh_CN.UTF-8";
    LC_MEASUREMENT = "zh_CN.UTF-8";
    LC_MONETARY = "zh_CN.UTF-8";
    LC_NAME = "zh_CN.UTF-8";
    LC_NUMERIC = "zh_CN.UTF-8";
    LC_PAPER = "zh_CN.UTF-8";
    LC_TELEPHONE = "zh_CN.UTF-8";
    LC_TIME = "zh_CN.UTF-8";
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  programs.mosh = {
    enable = true;
    openFirewall = true;
  };

  # Force Tailscale over DERP + FakeHTTP + BBR (see the tailscale-force-derp
  # aspect).
  services.tailscaleForceDerp = {
    enable = true;
    interface = "enp3s0";
  };

  # This value defines the first version of NixOS installed on this machine.
  system.stateVersion = "26.05"; # Did you read the comment?
}
