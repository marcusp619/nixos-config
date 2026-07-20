# Hyprland login hang — debugging handoff

## Context

NixOS desktop (`~/nix-config`, GitHub `marcusp619/nixos-config`,
`nixosConfigurations.desktop` in `flake.nix`) pins `nixpkgs` to `nixos-26.05`,
which ships Hyprland **0.55.4**. The home-manager config at
`home/hyprland.nix` was written against an older Hyprland API and threw
config errors on startup:

- `decoration.drop_shadow` / `shadow_range` / `shadow_render_power` /
  `col.shadow` — removed since Hyprland 0.45, replaced by a nested
  `decoration.shadow { enabled, range, render_power, color }` block.
- Standalone `togglesplit` dispatcher — removed in Hyprland 0.54, replaced by
  `layoutmsg, togglesplit`.

## Fix applied

Branch `fix/hyprland-0.55-config`, open as **PR #14** against `main` (not yet
merged). Changes are in `home/hyprland.nix`:

- Lines ~76-93: nested `decoration.shadow { }` block instead of the flat
  options.
- Line ~136: `"${mod}, J, layoutmsg, togglesplit"` instead of
  `"${mod}, J, togglesplit"`.

`nix eval` on the generated `hyprland.conf` derivation succeeds (no Nix-level
errors). Could not `nix build` for `x86_64-linux` from macOS (no linux
builder configured), so the actual rendered config text has never been
directly inspected.

## The regression

After deploying this fix (`sudo nixos-rebuild boot --flake
~/nix-config#desktop`, reboot, select new generation), login hangs — screen
freezes at `Reached target Graphical Interface`, never reaches a usable
session.

## Diagnostics done so far

- Ctrl+Alt+Del triggers a *clean* systemd shutdown (services stop in order,
  no timeouts) — the OS is not hard-frozen, only the display/session is
  stuck.
- First hang: SDDM auto-selected the last-used session, **Plasma
  (Wayland)**, which crashed outright (`sddm[1575]: Authentication error:
  SDDM::Auth::ERROR_INTERNAL "Process crashed"`, `startplasma-wayland` exit
  code 1). Unrelated to Hyprland — a separate, pre-existing bug in the
  Plasma-Wayland fallback session.
- Second hang: explicitly selected **Hyprland (uwsm-managed)** this time.
  System journal (`journalctl -b -1`) showed a clean handoff — `uwsm`
  selected `hyprland.desktop`, created its systemd unit env dirs, logged
  `Starting hyprland.desktop and waiting while it is running...` — then
  **total silence** for ~2 minutes until forced reboot. No crash, no error
  logged anywhere in the system journal.
- Hypothesized the monitor mode (`monitor = [ ",5120x1440@240,auto,1" ]` — a
  curved 5120x1440 ultrawide at 240Hz) might be a DRM mode-set hang. Tested
  with `",preferred,auto,1"` (commit `daf6ac7`) — **still hung**, so
  resolution/refresh is ruled out. That diagnostic change was reverted
  (commit `3bc992a`); branch is back to just the two real fixes.
- User reports Hyprland **did** load successfully before (with the old
  broken shadow/togglesplit config, showing config-error banners) — meaning
  the base Hyprland/AMD GPU/SDDM stack worked prior to this fix, which
  weighs against "pre-existing GPU bug" and back toward our two-line diff
  (or something coincident with it) being implicated.

## Not yet gathered — do these first

1. `journalctl --user -b -1 --no-pager | tail -300` (run as the normal user,
   not root/sudo) — Hyprland's own startup output goes through the
   `wayland-wm@hyprland.desktop.service` **user** systemd unit via uwsm, not
   the system journal. This has never actually been pulled and should show
   exactly where Hyprland's startup stalls.
2. The actual rendered hyprland.conf:
   `find /nix/store -maxdepth 1 -iname "*hm_hyprhyprland.conf" -newermt "-2 days"`
   then `cat` the matching one, to confirm the nested `shadow { }` block and
   the `layoutmsg, togglesplit` bind actually rendered as valid hyprlang
   syntax rather than assuming home-manager's formatter handled it
   correctly.

## Safe fallback

A prior boot-loader generation (before this fix) boots fine into a working
session — use that to get a shell/gather logs, and use `nixos-rebuild boot`
(not `switch`) for any further tests so a bad generation never becomes
un-recoverable without a reboot-menu fallback.

---

*Temporary debugging doc — delete once the hang is resolved.*
