{ config, pkgs, ... }:

let
  varsFile = builtins.readFile ./vars.local.sh;
  internalIP = builtins.head (builtins.match ".*INTERNAL_IP=([0-9\\.]+).*" varsFile);
  externalPort = builtins.head (builtins.match ".*EXTERNAL_PORT=([0-9]+).*" varsFile);
  iface = builtins.head (builtins.match ".*INTERFACE=\"([a-zA-Z0-9_\\-]+)\".*" varsFile);
in
  {
    imports = [
      ./hardware-configuration.nix
    ];

    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    nixpkgs.config.allowUnfree = true;

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    networking.hostName = "laptop";
    networking.networkmanager.enable = true;
    networking.firewall.enable = false;

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

    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };
    services.openssh = {
      enable = true;
      ports = [ 2222 ];
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        AllowUsers = [ "mcserver" "zacml" ];
      };
    };
    services.systemd.services.upnp-port-mapping = {
      description = "UPnP Port Mapping for ${externalPort}";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "upnp-add-mapping" ''
          set -e
          echo "Creating UPnP port mapping: ${externalPort} -> ${internalIP}:${externalPort}"
          ${pkgs.miniupnpc}/bin/upnpc -a ${internalIP} ${externalPort} ${externalPort} TCP
          ${pkgs.miniupnpc}/bin/upnpc -a ${internalIP} ${externalPort} ${externalPort} UDP
        '';
        ExecStop = pkgs.writeShellScript "upnp-remove-mapping" ''
          echo "Removing UPnP port mapping: ${externalPort}"
          ${pkgs.miniupnpc}/bin/upnpc -d ${externalPort} TCP || true
          ${pkgs.miniupnpc}/bin/upnpc -d ${externalPort} UDP || true
        '';
      };
    };

    services.systemd.services.upnp-port-mapping-watchdog = {
      description = "UPnP Port Mapping Watchdog for ${externalPort}";
      after = [ "upnp-port-mapping.service" ];
      requires = [ "upnp-port-mapping.service" ];

      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "300"; # Check every 5 minutes
        ExecStart = pkgs.writeShellScript "upnp-watchdog" ''
          set -e
          
          while true; do
            echo "Checking UPnP port mapping status..."
            
            # List current mappings and check if ours exists
            if ! ${pkgs.miniupnpc}/bin/upnpc -l | grep -q "${externalPort}.*TCP.*${internalIP}"; then
              echo "Port mapping missing! Recreating..."
              ${pkgs.miniupnpc}/bin/upnpc -a ${internalIP} ${externalPort} ${externalPort} TCP
            else
              echo "Port mapping exists and is healthy"
            fi

            # Check if UDP mapping exists
            if ! ${pkgs.miniupnpc}/bin/upnpc -l | grep -q "${externalPort}.*UDP.*${internalIP}"; then
              echo "UDP port mapping missing! Recreating..."
              ${pkgs.miniupnpc}/bin/upnpc -a ${internalIP} ${externalPort} ${externalPort} UDP
            else
              echo "UDP port mapping exists and is healthy"
            fi

            sleep 300  # 5 minutes
          done
        '';
      };
    };

    services.systemd.timers.upnp-port-mapping-check = {
      description = "Timer for UPnP Port Mapping Check";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "2min";
        OnUnitActiveSec = "5min";
        Unit = "upnp-port-mapping-watchdog.service";
      };
    };
    users.users.zacml = {
      isNormalUser = true;
      description = "Zachary Lesser";
      extraGroups = [ "networkmanager" "wheel" ];
    };
    users.users.mcserver = {
      isNormalUser = true;
      description = "Minecraft Server";
      extraGroups = [ "networkmanager" "wheel" ];
    };

    environment.systemPackages = with pkgs; [
      git
      miniupnpc
      unzip
      wget
    ];

    programs.tmux.enable = true;

    system.stateVersion = "25.05"; # Did you read the comment?
  }
