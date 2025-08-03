{
  pkgs,
  ...
}:
{
  # Import the default programs and tools for the user
  imports = [
    ../../home/programs
    ../../home/tools
  ];

  home.username = "zacml";
  home.homeDirectory = "/home/zacml";

  # GNOME dconf settings
  dconf = {
    enable = true;
    settings = {
      "org/gnome/shell" = {
        # Still allow the user to add extensions without having to define them in the config (dangerous)
        disable-user-extensions = false;

        # These are the applications that will be pinned to the dock
        favorite-apps = [
          "org.gnome.Terminal.desktop"
          "zen-beta.desktop"
          "org.gnome.Nautilus.desktop"
        ];

        # Enable the dash-to-dock extension
        enabled-extensions = [
          pkgs.gnomeExtensions.dash-to-dock.extensionUuid
        ];
      };
      "org/gnome/shell/extensions/dash-to-dock" = {
        # Disable the trash icon from the dock
        show-trash = false;
        # Enable multi-monitor support
        multi-monitor = true;
      };
      "org/gnome/desktop/wm/preferences" = {
        # Set the button layout for the window title bar (default is just a close button)
        button-layout = ":minimize,maximize,close";
      };
    };
  };

  # Set the state version for the home manager configuration
  home.stateVersion = "25.05";
}
