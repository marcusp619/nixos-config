{ config, pkgs, lib, ... }:
{
  # Work-mac-only tooling and shell config. Inventory of what this replaces
  # (and what was pruned) lives in hosts/work-macbook/INVENTORY.md.

  home.packages = with pkgs; [
    # containers — colima VM provides the docker engine on macOS
    colima
    lima
    docker
    docker-buildx
    docker-compose
    qemu
    mkcert
    hey

    # aws
    awscli2
    ssm-session-manager-plugin # required by the `coda` tunnel below
    aws-vault
    chamber
    aws-sam-cli

    # terraform — global for now; move to per-project devShells eventually
    terraform

    # node
    nodejs_24
    pnpm
    typescript
    typescript-language-server
    vscode-langservers-extracted

    # go
    go
    gopls
    gotools # goimports et al
    air
    go-migrate
    golangci-lint
    sqlc

    # rust — rustup manages toolchains as before
    rustup
    cargo-watch
    cargo-expand
    sqlx-cli
    taplo

    # python
    python3

    # lua (LazyVim toolchain)
    lua-language-server

    # db clients — servers run in containers
    mariadb.client # mysql wire-compatible; nixpkgs dropped mysql-client
    postgresql
    redis

    # misc — newrelic-cli isn't in nixpkgs; it comes from homebrew.brews
    git-filter-repo
    wget
  ];

  home.sessionVariables = {
    DOCKER_HOST = "unix://${config.home.homeDirectory}/.colima/docker.sock";
  };

  home.sessionPath = [
    "$HOME/go/bin"
    "$HOME/.cargo/bin"
  ];

  # AWS profiles/regions/SSO URLs only — no secrets. Credentials and SSO
  # token cache stay local per machine, set up manually after activation.
  home.file.".aws/config".source =
    config.lib.meta.createSymlink "home/files/aws/config";

  programs.zsh.initContent = ''
    # Shared helper — fuzzy-pick a subdir and cd into it (requires fzf)
    _pick_dir() {
      local search_path="$1"
      local selected
      selected=$(find "$search_path" -mindepth 1 -maxdepth 1 -type d | xargs -I{} basename {} | fzf)
      [[ -n "$selected" ]] && cd "$search_path/$selected"
    }

    work() { _pick_dir "$HOME/Documents/insurance-workspace"; }
    acu()  { _pick_dir "$HOME/Documents/acu-workspace"; }

    alias ipa='cd $HOME/Documents/insurance-workspace/insurance-partner-api/'

    # tfe — filter insurance-workspace TFE repos by name, then pick one
    tfe() {
      local folders=("$HOME/Documents/insurance-workspace/tfe_rv-insurance" "$HOME/Documents/insurance-workspace/tfe_rv-coverage")
      local options=() counter=1
      for folder in "''${folders[@]}"; do
        if [[ "$folder" == *"$1"* ]]; then
          echo "$counter. $folder"; options[$counter]=$folder; ((counter++))
        fi
      done
      if [[ $counter -eq 1 ]]; then echo "No matching folders found"; return 1; fi
      echo -n "Enter selection: "; read choice
      if [[ $choice -gt 0 && $choice -lt $counter ]]; then
        cd "''${options[$choice]}"
      else
        echo "Invalid selection"; return 1
      fi
    }

    # AWS — login and start the Comcast proxy tunnel in one shot
    coda() {
      aws sso login --profile sso-coda-nonprod && \
      aws ssm start-session --profile sso-coda-nonprod \
        --target i-034e9c036b6244ffd \
        --document-name AWS-StartPortForwardingSessionToRemoteHost \
        --parameters '{"host":["proxyweb-int.comcast.com"],"portNumber":["443"],"localPortNumber":["4443"]}'
    }
  '';
}
