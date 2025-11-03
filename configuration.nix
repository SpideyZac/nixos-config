{ config, pkgs, ... }:

let
  varsFile = builtins.readFile /home/zacml/nixos-config/vars.local.sh;
  internalIP = builtins.head (builtins.match ".*INTERNAL_IP=([0-9\\.]+).*" varsFile);
  externalPort = builtins.head (builtins.match ".*EXTERNAL_PORT=([0-9]+).*" varsFile);
  iface = builtins.head (builtins.match ".*INTERFACE=\"([a-zA-Z0-9_\\-]+)\".*" varsFile);
in
  {
    imports = [
      ./hardware-configuration.nix
    ];

    nix = {
      settings = {
        experimental-features = [ "nix-command" "flakes" ];
      };
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
      };
    };

    nixpkgs.config.allowUnfree = true;

    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    networking = {
      hostName = "laptop";
      networkmanager.enable = true;
      firewall.enable = false;
    };

    time.timeZone = "America/Los_Angeles";

    i18n = {
      defaultLocale = "en_US.UTF-8";
      extraLocaleSettings = {
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
    };

    services = {
      xserver.xkb = {
        layout = "us";
        variant = "";
      };
      openssh = {
        enable = true;
        ports = [ 2222 ];
        settings = {
          PermitRootLogin = "no";
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          AllowUsers = [ "mcserver" "zacml" ];
        };
      };
    };

    users.users = {
      zacml = {
        isNormalUser = true;
        description = "Zachary Lesser";
        extraGroups = [ "networkmanager" "wheel" ];
      };
      mcserver = {
        isNormalUser = true;
        description = "Minecraft Server";
        extraGroups = [ "networkmanager" "wheel" ];
      };
    };

    environment.systemPackages = with pkgs; [
      btop
      git
      miniupnpc
      unzip
      wget
    ];

    programs.tmux.enable = true;

    systemd.services = {
      upnp-port-mapping = {
        description = "UPnP Port Mapping for ${toString externalPort}";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "upnp-add-mapping" ''
            set -euo pipefail
            echo "Creating UPnP port mapping: ${externalPort} -> ${internalIP}:${externalPort}"
            ${pkgs.miniupnpc}/bin/upnpc -a ${internalIP} ${externalPort} ${externalPort} TCP
            ${pkgs.miniupnpc}/bin/upnpc -a ${internalIP} ${externalPort} ${externalPort} UDP
          '';
          ExecStop = pkgs.writeShellScript "upnp-remove-mapping" ''
            set -euo pipefail
            echo "Removing UPnP port mapping: ${externalPort}"
            ${pkgs.miniupnpc}/bin/upnpc -d ${externalPort} TCP || true
            ${pkgs.miniupnpc}/bin/upnpc -d ${externalPort} UDP || true
          '';
        };
      };
      upnp-port-mapping-watchdog = {
        description = "UPnP Port Mapping Watchdog for ${toString externalPort}";
        after = [ "upnp-port-mapping.service" ];
        requires = [ "upnp-port-mapping.service" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "simple";
          Restart = "always";
          RestartSec = 10;
          ExecStart = pkgs.writeShellScript "upnp-watchdog" ''
            set -euo pipefail

            while true; do
              echo "Checking UPnP port mapping status..."

              # TCP mapping
              if ! ${pkgs.miniupnpc}/bin/upnpc -l | grep -q "TCP.*${externalPort}->${internalIP}:${externalPort}"; then
                echo "TCP mapping missing! Recreating..."
                ${pkgs.miniupnpc}/bin/upnpc -a ${internalIP} ${externalPort} ${externalPort} TCP
              else
                echo "TCP mapping exists and is healthy"
              fi

              # UDP mapping
              if ! ${pkgs.miniupnpc}/bin/upnpc -l | grep -q "UDP.*${externalPort}->${internalIP}:${externalPort}"; then
                echo "UDP mapping missing! Recreating..."
                ${pkgs.miniupnpc}/bin/upnpc -a ${internalIP} ${externalPort} ${externalPort} UDP
              else
                echo "UDP mapping exists and is healthy"
              fi

              sleep 300
            done
          '';
        };
      };
    };

    system.stateVersion = "25.05"; # Did you read the comment?
  }
