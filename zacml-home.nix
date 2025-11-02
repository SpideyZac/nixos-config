{ pkgs, nixpkgs, ... }:

{
  home.username = "zacml";
  home.homeDirectory = "/home/zacml";

  programs.git = {
    settings = {
      name = "SpideyZac";
      email = "zacmlesser-7@outlook.com";
    };
  };

  home.stateVersion = "25.05";
}
