{
  description = "Multi-machine Nix config — AMD desktop + MacBook Pro 2017 NixOS + M1 MacBook macOS";

  inputs = {
    nixpkgs.url     = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    herdr.url = "github:ogulcancelik/herdr";
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, ... }@inputs:
  let
    username = "mark";

    hmModule = {
      home-manager.useGlobalPkgs    = true;
      home-manager.useUserPackages  = true;
      home-manager.extraSpecialArgs = { inherit inputs username; };
      home-manager.users.${username} = import ./home/common.nix;
    };
  in {

    # ── AMD desktop (NixOS, x86_64) ──────────────────────────────────────────
    nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs username; };
      modules = [
        ./hosts/desktop/configuration.nix
        home-manager.nixosModules.home-manager
        hmModule
      ];
    };

    # ── MacBook Pro 2017 running NixOS (x86_64) ───────────────────────────────
    nixosConfigurations.personal-macbook = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs username; };
      modules = [
        ./hosts/personal-macbook/configuration.nix
        home-manager.nixosModules.home-manager
        hmModule
      ];
    };

    # ── Work MacBook (macOS, nix-darwin) ──────────────────────────────────────
    darwinConfigurations.work-macbook = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = { inherit inputs username; };
      modules = [
        ./hosts/work-macbook/darwin.nix
        home-manager.darwinModules.home-manager
        hmModule
      ];
    };

  };
}
