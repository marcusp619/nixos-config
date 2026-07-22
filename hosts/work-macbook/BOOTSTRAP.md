# Bootstrapping Nix on a fresh work MacBook

Steps to go from a brand-new corp-provisioned Mac to a working `darwin-rebuild
switch` against this flake. Written after redoing this on an M1 -> M5 hardware
swap (2026-07-22), where the standard install path failed.

## Why this isn't a plain `nix run nix-darwin -- switch`

The standard/Determinate Nix installer mounts the Nix store on a dedicated
APFS volume via `diskutil apfs addVolume` against the real physical
container. On this machine, Kandji MDM + BeyondTrust EPM block that specific
operation — `diskutil mount "Nix Store"` fails with `SUIS premount
dissented` (a deprecated-but-still-enforced `SystemUIServer`
"harddisk-internal" mount policy). This is a device/policy thing, not a Nix
version or installer-choice thing — a previous M1 on this same flake had no
such policy applied and used the standard mechanism fine.

The fix: back `/nix` with a plain `hdiutil`-attached sparse disk image
instead of a native volume/container operation. `hdiutil attach` on a
file-backed image is a lower-privilege operation the same EPM policy doesn't
cover.

## 1. Create the synthetic mountpoint

```sh
printf 'nix\n' | sudo tee /etc/synthetic.conf
sudo /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -t
ls -la /nix   # should now exist as an empty directory; reboot if it doesn't yet
```

Must be a **bare** `nix` line (empty synthetic directory). A two-column
`nix\t<target>` entry creates a symlink instead — current Nix hard-rejects a
symlinked store path ("the path '/nix' is a symlink; this is not allowed").

## 2. Create the disk image and LaunchDaemon

```sh
sudo hdiutil create -type SPARSE -size 128g -fs APFS -volname "Nix Store" /var/nix-store.sparseimage

sudo tee /Library/LaunchDaemons/org.nixos.darwin-store.plist > /dev/null <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
        <key>Label</key>
        <string>org.nixos.darwin-store</string>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <false/>
        <key>ProgramArguments</key>
        <array>
                <string>/bin/sh</string>
                <string>-c</string>
                <string>/usr/bin/hdiutil attach -nobrowse -owners on -mountpoint /nix /var/nix-store.sparseimage</string>
        </array>
        <key>StandardErrorPath</key>
        <string>/var/log/darwin-store.log</string>
        <key>StandardOutPath</key>
        <string>/var/log/darwin-store.log</string>
</dict>
</plist>
EOF
sudo chown root:wheel /Library/LaunchDaemons/org.nixos.darwin-store.plist
sudo chmod 644 /Library/LaunchDaemons/org.nixos.darwin-store.plist
sudo launchctl bootstrap system /Library/LaunchDaemons/org.nixos.darwin-store.plist

mount | grep -i nix   # confirm disk5s1 (or similar) mounted at /nix
```

This LaunchDaemon re-attaches the image at `/nix` on every boot, same as the
standard installer's daemon would for a real volume — just pointed at a file
instead.

## 3. Install Nix without letting it manage volumes or default build-user IDs

```sh
NIX_VOLUME_CREATE=0 NIX_BUILD_GROUP_ID=750 NIX_FIRST_BUILD_UID=751 \
  sh <(curl -L https://nixos.org/nix/install) --daemon
```

- `NIX_VOLUME_CREATE=0` — skip the installer's own volume creation; use the
  `/nix` we already mounted in step 2.
- `NIX_BUILD_GROUP_ID=750` / `NIX_FIRST_BUILD_UID=751` — the installer's
  default (GID 350 / UID 351) collides with BeyondTrust's `_avectodaemon`
  and `_defendpoint` on this machine. Must match `ids.gids.nixbld` /
  `ids.uids.nixbld` in `darwin.nix`.

Open a new terminal afterward so `nix` is on `PATH`.

## 4. Bootstrap nix-darwin

Flakes/nix-command aren't enabled in `nix.conf` until after the first
switch, and `darwin-rebuild switch` needs root — but plain `sudo` resets
`PATH` so it won't find `nix`. Preserve it explicitly:

```sh
sudo env "PATH=$PATH" nix --extra-experimental-features "nix-command flakes" \
  run nix-darwin/nix-darwin-26.05#darwin-rebuild -- switch --flake ~/nix-config#work-macbook
```

After this succeeds once, plain `darwin-rebuild switch --flake
~/nix-config#work-macbook` works for subsequent rebuilds (still needs
`sudo`).
