# boxy.nix

A small Nix flake library for wrapping AI agent commands in a macOS `sandbox-exec` profile.

The exported `mkSandboxedAgent` helper creates a shell application that runs a chosen program with a restricted environment and the sandbox rules in `profiles/ai-agent.sb`. The sandbox allows access to the current workspace, common tool caches, agent config directories, and system paths needed by CLI tools.

## Usage

```nix
{
  nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
  inputs.sandboxed-agents.url = "github:bonofiglio/sandboxed-agents";
  inputs.sandboxed-agents.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { nixpkgs, sandboxed-agents, ... }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages.${system}.sandboxed-opencode =
        sandboxed-agents.lib.${system}.mkSandboxedAgent {
          name = "sandboxed-opencode"; # Set `opencode` here instead if you wanna keep using the muscle memory
          program = "${pkgs.opencode}/bin/opencode";
        };
    };
}
```

(optional) Set `AI_SANDBOX_WORKSPACE` to choose the writable workspace. If unset, the wrapper uses the current directory.
