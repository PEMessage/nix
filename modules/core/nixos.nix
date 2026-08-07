{
  #Error during "tree-sitter build": Could not start dynamically linked executable: tree-sitter
  #NixOS cannot run dynamically linked executables intended for generic
  #linux environments out of the box. For more information, see:
  #https://nix.dev/permalink/stub-ld
  programs.nix-ld.enable = true;
}
