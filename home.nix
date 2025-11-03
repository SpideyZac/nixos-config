{ pkgs, nixpkgs, ... }:

let
  mineControlJarUrl = "https://github.com/andre-carbajal/mine-control-cli/releases/download/v2.2.4/mine-control-cli-2.2.4.jar";
  mineControlJarSha256 = "b72d1547a42df73b94386505f8e38057a7df7fce4e9baab82868da600c0b4995";
  mineControlJar = pkgs.fetchurl {
    url = mineControlJarUrl;
    sha256 = mineControlJarSha256;
  };
in
  {
    home = {
      username = "mcserver";
      homeDirectory = "/home/mcserver";
      file = {
        "MineControlCli/minecontrol.properties".text = ''
          #MineControl CLI - User Configuration
          #Sat Nov 01 23:09:42 PDT 2025
          eula.auto-accept=true
          java.max-ram=4096M
          java.min-ram=2048M
          java.path=java
          paths.backups=/home/mcserver/MineControlCli/backups
          paths.servers=/home/mcserver/MineControlCli/servers
          potato-peeler.chunk-inhabited-time=200
          update.check-on-startup=true
        '';
        "MineControlCli/mine-control-cli-2.2.4.jar".source = mineControlJar;
      };
      stateVersion = "25.05";
    };
  }
