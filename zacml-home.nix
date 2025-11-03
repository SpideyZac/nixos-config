{ pkgs, nixpkgs, ... }:

{
  home = {
    username = "zacml";
    homeDirectory = "/home/zacml";
    stateVersion = "25.05";
  };

  programs.git.settings = {
    name = "SpideyZac";
    email = "zacmlesser-7@outlook.com";
  };
}
