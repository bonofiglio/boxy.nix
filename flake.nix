{
  description = "Flake library for creating sandboxed commands";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
    systems.url = "github:nix-systems/default-darwin";
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.systems.follows = "systems";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        agentSandboxProfile = ./profiles/ai-agent.sb;

        mkSandboxedAgent =
          {
            name,
            program,
          }:
          pkgs.writeShellApplication {
            inherit name;
            text = ''
              if [[ "$(uname -s)" != "Darwin" ]]; then
                printf '%s\n' '${name}: sandbox-exec is only available on macOS.' >&2
                exit 1
              fi

              sandbox_exec=/usr/bin/sandbox-exec
              if [[ ! -x "$sandbox_exec" ]]; then
                printf '%s\n' '${name}: /usr/bin/sandbox-exec was not found or is not executable.' >&2
                exit 1
              fi

              workspace="''${AI_SANDBOX_WORKSPACE:-$PWD}"
              if ! workspace="$(cd "$workspace" 2>/dev/null && pwd -P)"; then
                printf '%s\n' '${name}: AI_SANDBOX_WORKSPACE must point to an existing directory.' >&2
                exit 1
              fi

              home="''${HOME:-/var/empty}"
              path="''${PATH:-/usr/bin:/bin:/usr/sbin:/sbin}"
              shell="''${SHELL:-/bin/zsh}"
              user="''${USER:-}"
              logname="''${LOGNAME:-$user}"
              tmpdir=/tmp
              term="''${TERM:-dumb}"
              tty_device=/dev/null
              if tty_output="$(tty 2>/dev/null)" && [[ "$tty_output" != "not a tty" ]]; then
                tty_device="$tty_output"
              fi

              xdg_config_home="''${XDG_CONFIG_HOME:-$home/.config}"
              xdg_cache_home="''${XDG_CACHE_HOME:-$home/.cache}"
              xdg_data_home="''${XDG_DATA_HOME:-$home/.local/share}"
              xdg_state_home="''${XDG_STATE_HOME:-$home/.local/state}"
              claude_home="''${CLAUDE_CONFIG_DIR:-$home/.claude}"

              darwin_user_cache="$(getconf DARWIN_USER_CACHE_DIR)"
              darwin_user_temp="$(getconf DARWIN_USER_TEMP_DIR)"
              darwin_user_cache="/private''${darwin_user_cache%/}"
              darwin_user_temp="/private''${darwin_user_temp%/}"

              # Only propagate CLAUDE_CONFIG_DIR when the user explicitly set it
              claude_config_dir_env=()
              if [[ -n "''${CLAUDE_CONFIG_DIR:-}" ]]; then
                claude_config_dir_env=(CLAUDE_CONFIG_DIR="$claude_home")
              fi

              exec /usr/bin/env -i \
                "''${claude_config_dir_env[@]}" \
                __NIX_DARWIN_SET_ENVIRONMENT_DONE=1 \
                HOME="$home" \
                PATH="$path" \
                SHELL="$shell" \
                USER="$user" \
                LOGNAME="$logname" \
                PWD="$PWD" \
                TMPDIR="$tmpdir" \
                TERM="$term" \
                TERM_PROGRAM="''${TERM_PROGRAM:-}" \
                TERM_PROGRAM_VERSION="''${TERM_PROGRAM_VERSION:-}" \
                COLORTERM="''${COLORTERM:-}" \
                COLUMNS="''${COLUMNS:-}" \
                LINES="''${LINES:-}" \
                LANG="''${LANG:-}" \
                LC_ALL="''${LC_ALL:-}" \
                LC_CTYPE="''${LC_CTYPE:-}" \
                TZ="''${TZ:-}" \
                NIX_SSL_CERT_FILE="''${NIX_SSL_CERT_FILE:-}" \
                SSL_CERT_FILE="''${SSL_CERT_FILE:-}" \
                SSL_CERT_DIR="''${SSL_CERT_DIR:-}" \
                __CF_USER_TEXT_ENCODING="''${__CF_USER_TEXT_ENCODING:-}" \
                XDG_CONFIG_HOME="$xdg_config_home" \
                XDG_CACHE_HOME="$xdg_cache_home" \
                XDG_DATA_HOME="$xdg_data_home" \
                XDG_STATE_HOME="$xdg_state_home" \
                AI_SANDBOXED=1 \
                AI_SANDBOX_WORKSPACE="$workspace" \
                "$sandbox_exec" \
                -f "${agentSandboxProfile}" \
                -D "WORKSPACE=$workspace" \
                -D "TTY_DEVICE=$tty_device" \
                -D "GIT_XDG_CONFIG=$xdg_config_home/git" \
                -D "HOME_PROFILE=$home/.profile" \
                -D "HOME_BASH_PROFILE=$home/.bash_profile" \
                -D "HOME_BASHRC=$home/.bashrc" \
                -D "HOME_ZPROFILE=$home/.zprofile" \
                -D "HOME_ZSHENV=$home/.zshenv" \
                -D "HOME_ZSHRC=$home/.zshrc" \
                -D "HOME_KEYCHAINS=$home/Library/Keychains" \
                -D "DARWIN_USER_CACHE=$darwin_user_cache" \
                -D "DARWIN_USER_TEMP=$darwin_user_temp" \
                -D "CLAUDE_HOME=$claude_home" \
                -D "CLAUDE_JSON=$home/.claude.json" \
                -D "CLAUDE_XDG_CONFIG=$xdg_config_home/claude" \
                -D "CLAUDE_XDG_CACHE=$xdg_cache_home/claude" \
                -D "CLAUDE_XDG_DATA=$xdg_data_home/claude" \
                -D "CLAUDE_XDG_STATE=$xdg_state_home/claude" \
                -D "CLAUDE_DARWIN_APP_SUPPORT=$home/Library/Application Support/Claude" \
                -D "CLAUDE_DARWIN_CACHE=$home/Library/Caches/Claude" \
                -D "CLAUDE_DARWIN_LOGS=$home/Library/Logs/Claude" \
                -D "OPENCODE_XDG_CONFIG=$xdg_config_home/opencode" \
                -D "OPENCODE_XDG_CACHE=$xdg_cache_home/opencode" \
                -D "OPENCODE_XDG_DATA=$xdg_data_home/opencode" \
                -D "OPENCODE_XDG_STATE=$xdg_state_home/opencode" \
                -D "OPENCODE_DARWIN_APP_SUPPORT=$home/Library/Application Support/opencode" \
                -D "OPENCODE_DARWIN_CACHE=$home/Library/Caches/opencode" \
                -D "OPENCODE_DARWIN_LOGS=$home/Library/Logs/opencode" \
                -D "RUSTUP_HOME=$home/.rustup" \
                -D "CARGO_HOME=$home/.cargo" \
                -D "CARGO_REGISTRY=$home/.cargo/registry" \
                -D "CARGO_GIT=$home/.cargo/git" \
                -D "CARGO_PACKAGE_CACHE=$home/.cargo/.package-cache" \
                -D "NPM_CACHE=$home/.npm" \
                -D "NPM_RC=$home/.npmrc" \
                -D "PNPM_HOME=$home/Library/pnpm" \
                -D "PNPM_STORE=$xdg_data_home/pnpm" \
                -D "PNPM_CACHE=$xdg_cache_home/pnpm" \
                -D "PNPM_STATE=$xdg_state_home/pnpm" \
                -D "PNPM_CONFIG=$xdg_config_home/pnpm" \
                -D "YARN_HOME=$home/.yarn" \
                -D "YARN_BERRY=$home/.yarn/berry" \
                -D "YARN_CACHE=$home/Library/Caches/Yarn" \
                -D "YARN_CACHE_XDG=$xdg_cache_home/yarn" \
                -D "YARN_CONFIG=$xdg_config_home/yarn" \
                -D "YARN_RC=$home/.yarnrc" \
                -D "YARN_RC_YML=$home/.yarnrc.yml" \
                -D "COREPACK_CACHE=$xdg_cache_home/node" \
                -D "COREPACK_CACHE_DARWIN=$home/Library/Caches/node" \
                -- "${program}" "$@"
            '';
          };
      in
      {
        lib = {
          inherit mkSandboxedAgent;
        };
      }
    );
}
