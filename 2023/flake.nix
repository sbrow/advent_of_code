{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # dolt.url = "github:sbrow/dolt";
    # phps.url = "github:fossar/nix-phps";
    # phps.inputs.nixpkgs.follows = "nixpkgs";

    flake-parts.url = "github:hercules-ci/flake-parts";
    #process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{ self
    , flake-parts
    , nixpkgs
    , nixpkgs-unstable
    # , phps
    # , process-compose-flake
    # , sbrow
    , treefmt-nix
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.treefmt-nix.flakeModule
        # inputs.process-compose-flake.flakeModule
      ];
      systems = [ "x86_64-linux" ];

      perSystem =
        { pkgs, system, inputs', ... }:
        let
          php = pkgs.php.buildEnv {
            extensions = ({ enabled, all }: enabled ++ (with all; [
              xdebug
            ]));
            extraConfig = ''
              ; xdebug 3
              xdebug.mode=debug
              xdebug.client_port=9000

              ; xdebug 2
              xdebug.remote_enable=1
            '';
          };
        in
        {
          _module.args.pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;

            overlays = [
              (final: prev: { unstable = inputs'.nixpkgs-unstable.legacyPackages; })
            ];
          };

          treefmt = {
            # Used to find the project root
            projectRootFile = "flake.nix";

            # Format nix files
            programs.nixpkgs-fmt.enable = true;

            # Format php files
            /*
          settings.formatter."pint" =
            {
              command = "./vendor/bin/pint";
              includes = [ "*[!.blade].php" ];
              excludes = [ "_ide_helper*.php" ];
            };

          # Format blade files
          settings.formatter."blade-formatter" = {
            command = "./bin/blade-formatter";
            options = [ "--write" ];
            includes = [ "*.blade.php" ];
          };
            */

            # Format js, json, and yaml files
            /*
            programs.prettier.enable = true;
            settings.formatter.prettier =
              {
                excludes = [
                  "public/**"
                  "resources/js/modernizr.js"
                  "storage/app/caniuse.json"
                  "*.md"
                ];
              };
            */

            # Format elm components
            #programs.elm-format.enable = true;

            # Override the default package
            #programs.terraform.package = nixpkgs.terraform_1;
          };

          devShells.default = pkgs.mkShell
            {
              buildInputs = with pkgs; [
                unstable.zig
                zls
              ];
            };
        };
    };
}
