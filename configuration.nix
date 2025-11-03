{ config, pkgs, ... }:

let
  varsFile = builtins.readFile /home/mcserver/nixos-config/vars.local.sh;
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
          AllowUsers = [ "mcserver" ];
        };
      };
    };

    users.users = {
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
      zulu25
    ];

    programs.tmux.enable = true;

    systemd.services = {
      upnp-port-mapping = {
        description = "UPnP Port Mapping Maintenance for ${toString externalPort}";
        after = [ "network-online.target" ];
        requires = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "simple";

          ExecStart = pkgs.writeShellScript "upnp-maintain-mapping" ''
            set -euo pipefail
            
            while true; do
              echo "Creating/refreshing UPnP port mapping: ${externalPort} -> ${internalIP}:${externalPort}"
              ${pkgs.miniupnpc}/bin/upnpc -a ${internalIP} ${externalPort} ${externalPort} TCP || true
              ${pkgs.miniupnpc}/bin/upnpc -a ${internalIP} ${externalPort} ${externalPort} UDP || true
              sleep 300
            done
          '';

          Restart = "always";
          RestartSec = 60;
        };
      };
      upnp-port-mapping-cleanup = {
        description = "UPnP Port Mapping Cleanup for ${toString externalPort}";
        before = [ "shutdown.target" ];
        wantedBy = [ "shutdown.target" ];
        
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          
          ExecStop = pkgs.writeShellScript "upnp-remove-mapping" ''
            set -euo pipefail
            echo "Removing UPnP port mapping: ${externalPort}"
            ${pkgs.miniupnpc}/bin/upnpc -d ${externalPort} TCP || true
            ${pkgs.miniupnpc}/bin/upnpc -d ${externalPort} UDP || true
          '';
        };
      };
      minecontrol = {
        description = "MineControl CLI in tmux";
        after = [ "network.target" ];
        requires = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "simple";
          User = "mcserver";
          WorkingDirectory = "/home/mcserver";

          ExecStart = pkgs.writeShellScript "start-minecontrol" ''
            set -euo pipefail

            SESSION=minecontrol
            TMUX=${pkgs.tmux}/bin/tmux

            if $TMUX has-session -t $SESSION 2>/dev/null; then
              $TMUX kill-session -t $SESSION
            fi

            $TMUX new-session -d -s $SESSION \
              "java -jar /home/mcserver/MineControlCli/mine-control-cli-2.2.4.jar"
            
            echo "Waiting for MineControl to initialize..."
            sleep 5
            
            echo "Sending 'ss' command to start server"
            $TMUX send-keys -t $SESSION "ss" C-m

            echo "Monitoring session for crashes..."
            while true; do
              if ! $TMUX has-session -t $SESSION 2>/dev/null; then
                echo "Session died unexpectedly, exiting to trigger systemd restart"
                exit 1
              fi

              OUT=$($TMUX capture-pane -pt $SESSION -S -20 -E -1 2>/dev/null | tail -n 1 || echo "")
              
              if [[ "$OUT" =~ "Press enter to exit" ]]; then
                echo "Detected 'Press enter to exit' - server has stopped!"
                echo "Pressing enter to clear prompt..."
                $TMUX send-keys -t $SESSION C-m
                
                sleep 2
                
                echo "Restarting server with 'ss' command..."
                $TMUX send-keys -t $SESSION "ss" C-m
                
                echo "Server restart initiated, continuing monitoring..."
              fi
              
              sleep 10
            done
          '';

          ExecStop = pkgs.writeShellScript "stop-minecontrol" ''
            set -euo pipefail

            SESSION=minecontrol
            TMUX=${pkgs.tmux}/bin/tmux

            if ! $TMUX has-session -t $SESSION 2>/dev/null; then
              echo "Session $SESSION does not exist, nothing to stop"
              exit 0
            fi

            echo "Sending stop command to tmux session $SESSION..."
            $TMUX send-keys -t $SESSION "stop" C-m

            echo "Waiting for the 'Press enter to exit...' prompt"
            TIMEOUT=60
            COUNT=0
            while [ $COUNT -lt $TIMEOUT ]; do
              OUT=$($TMUX capture-pane -pt $SESSION -S -20 -E -1 2>/dev/null | tail -n 1 || echo "")
              if [[ "$OUT" =~ "Press enter to exit" ]]; then
                echo "Prompt detected - sending Enter"
                $TMUX send-keys -t $SESSION C-m
                break
              fi
              COUNT=$((COUNT + 1))
              sleep 2
            done

            echo "Sending quit command"
            $TMUX send-keys -t $SESSION "quit" C-m || true

            echo "Waiting for session to terminate..."
            TIMEOUT=30
            COUNT=0
            while $TMUX has-session -t $SESSION 2>/dev/null && [ $COUNT -lt $TIMEOUT ]; do
              COUNT=$((COUNT + 1))
              sleep 2
            done

            if $TMUX has-session -t $SESSION 2>/dev/null; then
              echo "Session still exists after timeout, force killing"
              $TMUX kill-session -t $SESSION || true
            fi

            echo "Session $SESSION stopped"
          '';

          Restart = "on-failure";
          RestartSec = 10;
          TimeoutStopSec = 180;
        };
      };
    };

    system.stateVersion = "25.05"; # Did you read the comment?
  }
