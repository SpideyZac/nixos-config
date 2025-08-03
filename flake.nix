{
  description = "NixOS Configuration";

  # The dependencies for this flake
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    {
      nixosConfigurations = {
        # Define the NixOS configuration for the host 'zacml'
        zacml =
          let
            system = "x86_64-linux";
          in
          nixpkgs.lib.nixosSystem {
            inherit system;

            modules = [
              # Import the configuration for the host
              ./hosts/zacml

              # Import the home manager module
              home-manager.nixosModules.home-manager
              {
                # Use global packages and user packages (so that home-manager can access them)
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;

                # Import the home manager configuration for the user 'zacml'
                home-manager.users.zacml = import ./users/zacml/home.nix;

                # Tell home-manager our imported flake dependencies as well as the system
                home-manager.extraSpecialArgs = {
                  inherit inputs system;
                };
              }
            ];
          };
      };

    };
}
