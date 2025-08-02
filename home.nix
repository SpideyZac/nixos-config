{ config, pkgs, system, inputs, ... }:

{
  home.username = "zacml";
  home.homeDirectory = "/home/zacml";
  
  home.packages = with pkgs; [
    inputs.zen-browser.packages."${system}".default
  ];
  
  programs.git = {
    enable = true;
    userName = "SpideyZac";
    userEmail = "zacmlesser-7@outlook.com";
  };
  
  home.stateVersion = "25.05";
}
