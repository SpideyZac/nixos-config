{
  lib,
  system,
  inputs,
  ...
}:
{
  # Import the zen-browser flake dependency
  home.packages = lib.mkAfter [
    inputs.zen-browser.packages."${system}".default
  ];
}
