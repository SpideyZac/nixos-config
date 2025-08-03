{ config, pkgs, system, inputs, ... }:

{
  home.username = "zacml";
  home.homeDirectory = "/home/zacml";
 
  home.packages = with pkgs; [
    nautilus
    gnomeExtensions.dash-to-dock
    inputs.zen-browser.packages."${system}".default
  ];
  
  dconf = {
    enable = true;
    settings = {
      "org/gnome/shell" = {
        disable-user-extensions = false;
      
        favorite-apps = [
          "org.gnome.Terminal.desktop"
          "zen-beta.desktop"
          "org.gnome.Nautilus.desktop"
        ];

        enabled-extensions = [
	  pkgs.gnomeExtensions.dash-to-dock.extensionUuid
        ];
      };
      "org/gnome/shell/extensions/dash-to-dock" = {
        show-trash = false;
        multi-monitor = true;
      };
      "org/gnome/desktop/wm/preferences" = {
        button-layout = ":minimize,maximize,close";
      };
    };
  };
  
  home.stateVersion = "25.05";
}

