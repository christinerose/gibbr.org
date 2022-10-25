{
  description = "A flake for building https://gibbr.org";

  inputs = {
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    # placeholder for private repo
    cv.url = "./empty-flake";
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
              ${if cv ? defaultPackage then "cp ${cv.defaultPackage.${system}}/*.pdf $out/resources/cv.pdf" else ""}
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

      nixosConfigurations."container" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ({ pkgs, ... }: {
            boot.isContainer = true;
            system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;
            networking.useDHCP = false;
            networking.firewall.allowedTCPPorts = [ 80 ];
            services.nginx = {
              enable = true;
              virtualHosts."_" = {
                  root = "${self.packages."x86_64-linux".default}";
                  extraConfig = ''
                  error_page 403 =404 /404.html;
                  error_page 404 /404.html;
                  '';
              };
            };
            system.stateVersion = "22.11";
          })
          ./gibbr.org-module.nix
        ];
      };
    };
}
