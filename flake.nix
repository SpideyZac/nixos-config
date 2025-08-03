{
  description = "NixOS Configuration";

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
        zacml =
          let
            system = "x86_64-linux";
          in
          nixpkgs.lib.nixosSystem {
            inherit system;

            modules = [
              ./hosts/zacml

              ./users/zacml/user.nix

              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;

                home-manager.users.zacml = import ./users/zacml/home.nix;

                home-manager.extraSpecialArgs = {
                  inherit inputs system;
                };
              }
            ];
          };
      };

    };
}
