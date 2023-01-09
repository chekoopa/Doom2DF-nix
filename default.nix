{ pkgs ? import <nixpkgs> {} }:

let
  drv = pkgs.callPackage ./release.nix { };
in 
  drv.doom2df

