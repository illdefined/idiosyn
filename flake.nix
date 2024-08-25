{
  description = "I do not have to explain myself";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nur.url = "github:nix-community/NUR";

    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.91.0.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    allow-import-form-derivation = true;

    extra-experimental-features = [ "pipe-operator" ];

    extra-substituters = [
      "https://colmena.cachix.org"
      "https://nix-community.cachix.org"
      "https://cache.kyouma.net"
    ];

    extra-trusted-public-keys = [
      "colmena.cachix.org-1:7BzpDnjjH8ki2CT3f6GdOk7QAzPOl+1t3LvTLXqYcSg="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.kyouma.net:Frjwu4q1rnwE/MnSTmX9yx86GNA/z3p/oElGvucLiZg="
    ];
  };

  outputs = { self, nixpkgs, ... }@inputs:
  let
    inherit (nixpkgs) lib;

    load = base: default: builtins.readDir base
      |> lib.filterAttrs (name: type: builtins.match "(regular|directory)" type != null)
      |> lib.mapAttrs' (name: type: {
          name = if type == "regular" then lib.removeSuffix ".nix" name else name;
          value =
            let path = if type == "directory" then "${name}/${default}.nix" else name;
            in import "${base}/${path}" inputs;
        });

    eachSystem = fun: lib.mapAttrs fun self.lib.platforms;
  in {
    lib = load ./lib "lib" // {
      inherit load;
    };

    overlays = load ./overlay "overlay";
    legacyPackages = eachSystem (system: platform:
      import nixpkgs {
        localSystem = builtins.currentSystem or platform;
        crossSystem = platform;
        overlays = [ self.overlays.default ];
        config.allowUnsupportedSystem = true;
      });

    packages = eachSystem (system: platform:
      let pkgs = self.legacyPackages.${system};
      in load ./package "package"
        |> lib.mapAttrs (name: pkg: self.legacyPackages.${system}.callPackage pkg { })
        |> lib.filterAttrs (name: pkg: lib.meta.availableOn platform pkg));

    nixosModules = load ./nixos/module "module";

    colmena = load ./nixos/config "configuration" // {
      meta = {
        nixpkgs = self.legacyPackages.x86_64-linux;
      };

      defaults = { name, config, ... }: {
        deployment = {
          allowLocalDeployment = true;
          targetHost = config.networking.fqdnOrHostName;
          targetUser = null;
        };
      };
    };

    nixosConfigurations =
      let hive = inputs.colmena.lib.makeHive self.outputs.colmena;
      in hive.nodes;

    homeModules = load ./home/module "module";
    homeConfigurations = load ./home/config "home";

    devShells = eachSystem (system: platform: load ./shell "shell"
      |> lib.mapAttrs (name: shell: self.legacyPackages.${system}.callPackage shell { })
      |> lib.filterAttrs (name: shell: lib.meta.availableOn platform shell));

    hydraJobs = {
      package = self.packages;
      shell = self.devShells;

      nixos = self.nixosConfigurations
        |> lib.concatMapAttrs (name: host: {
          ${host.pkgs.system} = {
            ${name} = host.config.system.build.toplevel;
          };
        });
    };
  };
}
