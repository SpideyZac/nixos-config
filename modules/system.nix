{
  pkgs,
  lib,
  ...
}:
{
  # Enable experimental features for Nix
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  # Set up the Nix garbage collector to automatically delete old generations (older than 7 days)
  # This runs weekly
  nix.gc = {
    automatic = lib.mkDefault true;
    dates = lib.mkDefault "weekly";
    options = lib.mkDefault "--delete-older-than 7d";
  };

  # Allow unfree packages to be installed
  # This is necessary for some proprietary software
  nixpkgs.config.allowUnfree = true;

  # Set the timezone and locale settings
  time.timeZone = "America/Los_Angeles";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Set the system packages to be installed
  environment.systemPackages = with pkgs; [
    displaylink
    uv
  ];
}
