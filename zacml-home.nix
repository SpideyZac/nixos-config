{ pkgs, nixpkgs, ... }:

{
  home.username = "zacml";
  home.homeDirectory = "/home/zacml";

  programs.git = {
    userName = "SpideyZac";
    userEmail = "zacmlesser-7@outlook.com";
  };

  home.stateVersion = "25.05";
}
