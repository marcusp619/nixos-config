{
  description = "Multi-machine Nix config — AMD desktop + MacBook Pro 2017 NixOS + work MacBook macOS";

  inputs = {
    nixpkgs.url          = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    herdr.url = "github:ogulcancelik/herdr";
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, ... }@inputs:
  let
    personalUser = "mark";
    workUser     = "mpearyer"; # corp-managed account name on the work MacBook

    # Build a home-manager NixOS/Darwin inline module from a list of home modules.
    mkHmCfg = username: modules: {
      home-manager.useGlobalPkgs    = true;
      home-manager.useUserPackages  = true;
      home-manager.backupFileExtension = "hm-backup";
      home-manager.extraSpecialArgs = { inherit inputs username; };
      home-manager.users.${username} = { imports = modules; };
    };
  in {

    # ── AMD desktop (NixOS, x86_64) ──────────────────────────────────────────
    nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; username = personalUser; };
      modules = [
        ./hosts/desktop/configuration.nix
        home-manager.nixosModules.home-manager
        (mkHmCfg personalUser [
          ./home/common.nix
          ./home/personal-apps.nix
          ./home/desktop-apps.nix
        ])
      ];
    };

    # ── MacBook Pro 2017 running NixOS (x86_64) ───────────────────────────────
    nixosConfigurations.personal-macbook = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; username = personalUser; };
      modules = [
        ./hosts/personal-macbook/configuration.nix
        home-manager.nixosModules.home-manager
        (mkHmCfg personalUser [
          ./home/common.nix
          ./home/personal-apps.nix
        ])
      ];
    };

    # ── Work MacBook (macOS, nix-darwin) ──────────────────────────────────────
    darwinConfigurations.work-macbook = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = { inherit inputs; username = workUser; };
      modules = [
        ./hosts/work-macbook/darwin.nix
        home-manager.darwinModules.home-manager
        (mkHmCfg workUser [
          ./home/common.nix
          ./home/work-apps.nix
        ])
      ];
    };

  };
}
