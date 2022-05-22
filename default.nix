{ pkgs ? import <nixpkgs> {  } }:
 
pkgs.stdenv.mkDerivation {
  name = "gibbr.org";

  src = ./.;

  buildInputs = with pkgs; [
    rsync
    pandoc
    perl
  ];

  installPhase = ''
    mkdir -p $out
    rsync -a --exclude '*.md' --exclude 'result' --exclude '.*' . $out
  '';
}
