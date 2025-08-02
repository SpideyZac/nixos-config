{ config, pkgs, system, inputs, ... }:

{
  home.username = "zacml";
  home.homeDirectory = "/home/zacml";
  
  home.packages = with pkgs; [
    inputs.zen-browser.packages."${system}".default
  ];
  
  home.stateVersion = "25.05";
}
