{
  pkgs,
  ...
}:
{
  imports = [
    /etc/nixos/hardware-configuration.nix
    ../../modules/system.nix
    ../../users/zacml/user.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "zacml";

  networking.networkmanager.enable = true;

  services.xserver.enable = true;
  services.xserver.videoDrivers = [
    "displaylink"
    "modesetting"
  ];

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.gnome.core-apps.enable = false;
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
  ];
  programs.gnome-terminal.enable = true;

  system.stateVersion = "25.05";
}
