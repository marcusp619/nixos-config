{ config, ... }:
{
  # config.lib.meta.createSymlink "home/files/nvim" — mutable symlink into
  # this repo's checkout at ~/nix-config, so in-place edits land back in git.
  lib.meta = {
    createSymlink = path:
      config.lib.file.mkOutOfStoreSymlink
        "${config.home.homeDirectory}/nix-config/${path}";
  };
}
