{
  description = "A flake for building https://gibbr.org";

  inputs = {
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    cv.url = "github:RyanGibb/cv";
    cv.inputs.nixpkgs.follows = "nixpkgs";
    cv.inputs.flake-utils.follows = "flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, cv, ... }:
    (flake-utils.lib.eachDefaultSystem
      (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in
        {
          packages.default = pkgs.stdenv.mkDerivation {
            name = "gibbr.org";

            src = self;

            buildInputs = [ pkgs.pandoc ];

            installPhase = ''
              mkdir -p $out
              ${pkgs.rsync}/bin/rsync -a --exclude '*.md' --exclude 'result' --exclude '.*' . $out
              cp ${cv.defaultPackage.${system}}/*.pdf $out/resources/cv.pdf
            '';
          };
          
          devShells.default = pkgs.mkShell {
            buildInputs = [ pkgs.pandoc ];
          };
        }
      )
    ) // {
      nixosModules.default = {
        imports = [ ./gibbr.org-module.nix ];
      };
    };
}
