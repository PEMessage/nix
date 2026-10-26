# AGENTS.md

NixOS + home-manager config for a personal fleet, organized **aspect-oriented
(Dendritic)**. This `main` branch is a fresh-history rewrite of `v1`.

## Stack

`flake.nix` uses `flake-parts`, plus:

- **`import-tree`** — auto-imports directories; no hand-written import lists.
  The only imports are `./aspects`, `./users`, `./profile`, `./hosts`.
- **`flake-aspects`** — defines `flake.aspects` and transposes it into
  `flake.modules.<class>.<aspect>`.

`debug = true` is set so nixd can resolve `flake.*` / `config.flake.*` paths.

## Concept: aspect

An aspect bundles one capability's **NixOS half** and **home-manager half**:

```nix
{ config, ... }:
{
  flake.aspects.<name> = {
    nixos = { pkgs, ... }: {
      # system side
      home-manager.sharedModules = [ config.flake.modules.homeManager.<name> ];
    };
    homeManager = { pkgs, ... }: {
      # user side
    };
  };
}
```

- `flake.aspects.<name>` becomes `flake.modules.nixos.<name>` and
  `flake.modules.homeManager.<name>`.
- Convention: the `nixos` half pulls in the matching user config via
  `home-manager.sharedModules`, so enabling a system feature also wires its user side.
- Aspect names may be quoted dotted strings, e.g. `"user.nixos"`, `"host.wks-revo"`.

## Secrets (sops)

- **Encrypted per-host secrets are committed**, one per host at
  `hosts/<host>/secret.yaml`, each encrypted to that host's own age key so a
  host can decrypt only its own. Wire it up with
  `sops.defaultSopsFile = ./secret.yaml;`, and tag anything read before users
  exist (e.g. `hashedPasswordFile`) `neededForUsers = true;`.
- **The keys are not.** A host's age key lives on the host at
  `/var/lib/sops-nix/key.txt` (see `aspects/core/secrets.nix`) and is kept in the
  separate `secrets` repo, encrypted to a root key that never enters VCS. It is
  copied onto a machine only at onboard time; day-to-day use never needs it.
- Key layout, tooling and workflows live in that repo's own README.

## Layout

| Dir | Role |
|---|---|
| `aspects/` | features, grouped by domain: `core/` `app/` `desktop/` `graphics/` `network/` |
| `profile/` | aggregation: bundles aspects into profiles |
| `users/` | one aspect per user (`user.nixos`, `user.pem`) |
| `hosts/` | per-host modules + `nixosConfigurations` entry |
| `pkgs/` | local packages (`callPackage`) |
| `script/` | ops scripts (e.g. `onboard.sh`) |
| `secrets/` | checkout of the separate secrets repo — gitignored here |

## Host slug

`<form>-<codename>`: `wks-` physical workstation, `vm-` virtual machine; the
codename is a gemstone, chemical element, color, or mythology name. E.g.
`vm-citrine`, `wks-onyx`.

## Composition

- **Profiles** only aggregate, e.g. `desktop.imports = [ core dev-tools fonts
  xserver core-app flatpak niri ];`. Chain: `core` → `desktop` → `desktop-extra`.
- **A host's `default.nix`** does three things:
  1. define `flake.modules.nixos."host.<h>"` (volatile host config: remote
     access, network tweaks);
  2. define `flake.modules.homeManager."host.<h>"` and wire it via the host
     module's `home-manager.sharedModules`;
  3. define `flake.nixosConfigurations.<h>` listing the modules to use.
- `hosts/<h>/_nixos/` holds only rarely-changing machine facts:
  `configuration.nix` (hand-written: boot loader, hostname, locale,
  `system.stateVersion`) plus the generated `hardware-configuration.nix`, which
  `configuration.nix` imports. Keep volatile config out.
- Users: a host imports `config.flake.modules.nixos."user.<u>"`; the user
  aspect holds a `home-manager.users.<u> = { };` placeholder (real config comes
  from the aspect's home half).

## Commands

```sh
# fast eval checks
nix flake check
nix eval .#nixosConfigurations --apply builtins.attrNames

# build / switch (switch needs root)
sudo nixos-rebuild build  --flake .#wks-revo
sudo nixos-rebuild switch --flake .#wks-revo
sudo nixos-rebuild switch --flake .#wsl
```

## Conventions

- Add a feature: create `aspects/<domain>/<name>.nix` with `flake.aspects.<name>`,
  then add it to a `profile/*.nix` `imports`. `import-tree` finds it automatically.
- Reference modules as `config.flake.modules.<class>.<name>`, not by path.
- Write module halves as functions (`nixos = { ... }: { ... }`), never a bare
  attrset — nixd only resolves options inside a lambda.
- Comments explain **why**, not what — many decisions (apollo clipboard patch,
  tailscale-force-derp FakeHTTP/BBR, niri/dms wiring) live only in comments.
- Local packages go in `pkgs/`; scripts in `script/` or inline `writeShellScriptBin`.

