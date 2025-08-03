{
  pkgs,
  lib,
  ...
}:
{
  # Import the nautilus core app from GNOME (file explorer)
  home.packages =
    with pkgs;
    lib.mkAfter [
      nautilus
    ];
}
