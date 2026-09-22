I'll start by pulling up what I have on this project, then dig into the files.Now let me verify key assumptions against upstream sources.Confirmed a guaranteed build-breaker. Let me write up the deliverable.I audited everything in the dump against upstream sources. One finding is a **guaranteed build failure** — I verified it against the pyprland repo directly. Note that the dump doesn't include `README.md`, `MIGRATION.md`, the wallpaper/plymouth binaries, or `00-default.just`, so a few gates I flag as "verify" rather than "broken."

---

## P0 — these fail the build today

### 1. `install-pyprland`: the Hyprland drop-in is unreachable → `built-apps-verify` hard-fails

The drop-in block sits **inside the `else`** branch, so it only runs when upstream ships no unit. I checked upstream: `systemd-unit/pyprland.service` returns HTTP 200 on `main`, so the `if` branch always wins, `/usr/lib/systemd/user/pyprland.service.d/` is never created, and Stage 9's gate

```
gate "Hyprland condition drop-in"  grep -rq 'XDG_CURRENT_DESKTOP=Hyprland' /usr/lib/systemd/user/pyprland.service.d/
```

fails every time. The comment in the script claims "A drop-in covers both the upstream-unit and inline-unit paths above" — it doesn't. Move it out:

```bash
else
  ...
  echo "  OK    inline pyprland.service written"
fi

# --- ALWAYS: gate the globally-enabled unit to Hyprland sessions ---
mkdir -p /usr/lib/systemd/user/pyprland.service.d
cat >/usr/lib/systemd/user/pyprland.service.d/10-halcyon-condition.conf <<'UNIT'
[Unit]
ConditionEnvironment=XDG_CURRENT_DESKTOP=Hyprland
UNIT
echo "  OK    ConditionEnvironment drop-in installed"
```

Two follow-ons: upstream's unit uses `ExecStart=pypr --debug "${XDG_STATE_HOME}/tmp/pypr.log"` (writes a debug log to `/tmp/pypr.log` when `XDG_STATE_HOME` is unset in the user manager — add an `Environment=` or override `ExecStart` in the same drop-in), and `ConditionEnvironment=` reads the _user manager's_ environment, so it only fires if the Hyprland session runs `dbus-update-activation-environment --systemd XDG_CURRENT_DESKTOP` (or `systemctl --user import-environment`). Worth asserting in your Hyprland config, otherwise pyprland silently never starts.

### 2. `nix-verify` checks a path `systemctl enable` never writes

```
gate "nix-daemon enabled"  test -e /usr/lib/systemd/system/multi-user.target.wants/nix-daemon.service
```

`install-nix` runs `systemctl enable nix-daemon 2>/dev/null || ln -sf /usr/lib/...`. `systemctl enable` succeeds in a build container and writes to **`/etc/systemd/system/multi-user.target.wants/`** — so the `||` fallback never runs and the gate tests a path that doesn't exist. Fix the gate:

```bash
gate "nix-daemon enabled"  systemctl is-enabled nix-daemon
```

Same class of bug is latent in `configure-system`, which enables `greetd.service`, `var-nix.service` and `nix.mount` with `2>/dev/null || true` and has **no** gate in `system-verify`. Add:

```bash
gate "greetd enabled"      systemctl is-enabled greetd.service
gate "var-nix enabled"     systemctl is-enabled var-nix.service
gate "nix.mount enabled"   systemctl is-enabled nix.mount
```

### 3. `80-halcyon.just` — `password-feedback` is a bash syntax error

The final `else` branch has no closing `fi`. I extracted the recipe body and ran `bash -n`: `line 35: syntax error: unexpected end of file`. `ujust --list` still passes (just doesn't parse recipe bodies), so `ujust-verify` waves it through and it ships broken. Add `fi` after the last `echo "enabled, restart terminal to see changes"`.

Add this to `just check` so it can't recur:

```bash
for f in system_files/shared/usr/share/ublue-os/just/*.just; do
    awk '/^ *#!\/usr\/bin\/(env )?bash/{p=1} p' "$f" | bash -n - || status=1
done
```

---

## P1 — builds, but ships broken or unverifiable

**`/usr/share/ublue-os/image-info.json` is never generated.** `bazzite-steam` (`jq -r '."image-name"'`), `bazzite-steam-firstrun` (`."base-image-name"`) and `83-halcyon-audio.just` all read it. `jq` on a missing file errors; with `set -e` absent in `bazzite-steam` it continues with an empty `IMAGE_NAME`, but `bazzite-steam-firstrun` will misbehave. Generate it in `image-info`:

```bash
install -d /usr/share/ublue-os
cat >/usr/share/ublue-os/image-info.json <<EOF
{ "image-name": "halcyon", "image-vendor": "aahsnr-work",
  "image-ref": "ostree-image-signed:docker://ghcr.io/aahsnr-work/halcyon",
  "image-tag": "latest", "base-image-name": "fedora-bootc",
  "fedora-version": "$(rpm -E %fedora)" }
EOF
```

…and gate it in `branding-verify`.

**Signed rebase doesn't work.** `halcyon-rebase.just` tells the user to `rpm-ostree rebase ostree-image-signed:docker://…`, but nothing installs `cosign.pub` into the image. That path needs the key at `/usr/etc/pki/containers/halcyon.pub`, a matching `sigstoreSigned` entry in `/etc/containers/policy.json`, and a `registries.d` entry pointing at the sigstore signature store — the ublue-os/config pattern. Right now the second half of your install instructions will fail with a policy error. Also: the recipe uses `bootc switch` in the unsigned path but tells the user `rpm-ostree rebase` for the signed one; on a bootc system use `bootc switch --enforce-container-sigpolicy`.

**`libdnf5.conf.d/99-halcyon-retries.conf` never takes effect.** I confirmed `/etc/dnf/libdnf5.conf.d/` is the real drop-in dir (libdnf5 `Base::load_config()` reads it before `dnf.conf`), but nothing copies the file there. Since it exists to survive Copr 504s, it has to land in the _first_ RUN:

```dockerfile
RUN --mount=type=bind,from=ctx,source=/,target=/ctx,ro \
    install -Dm0644 /ctx/libdnf5.conf.d/99-halcyon-retries.conf \
      /etc/dnf/libdnf5.conf.d/99-halcyon-retries.conf
```

Then drop the `! -name libdnf5.conf.d` exclusions in the Justfile — they're already no-ops, since `-type f` excludes directories.

**Bazzite-only dependencies in vendored ujust recipes.** These will all fail at runtime:

| Recipe                                                                       | Missing                                                                                                                            |
| ---------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| `regenerate-grub`, `grub-timeout`, `configure-grub`                          | `source /usr/libexec/bazzite-boot-remount` — not in the image                                                                      |
| `get-logs`                                                                   | `fpaste`, `wl-copy` (`wl-clipboard`) not installed                                                                                 |
| `toggle-i915-sleep-fix` (81-fixes)                                           | calls `rpm-ostree kargs` — doesn't exist on bootc; 80-halcyon was converted to `grubby`, 81 wasn't                                 |
| `toggle-bt-mic`, `wol`, `steam-icons`, `toggle-gigabyte-wake-fix` (81-fixes) | `ugum` (gum wrapper); 80-halcyon uses `Choose` — pick one, and install `gum` explicitly if you keep `ugum`                         |
| `fix-reset-steam`                                                            | calls `bazzite-steam --disable-firstrun`, which calls `bazzite-steam-firstrun`, which needs `zenity`/`kdialog` — neither installed |

Either ship `bazzite-boot-remount`/`fpaste`/`wl-clipboard`/`gum`, or delete the recipes. A cheap guard: add a gate in `ujust-verify` that greps every registered `.just` for `rpm-ostree`, `bazzite-boot-remount`, `ugum`, `fpaste` and fails on a hit.

**`bazzite-steam` assumes two Bazzite-only things.** `cardwire list --json` (fails silently → fine) and, on Wayland — which is always, on Hyprland — `LD_PRELOAD=/usr/lib/extest/libextest.so`. `extest` isn't installed, so every Steam launch preloads a nonexistent object. Guard it:

```bash
if [[ "$XDG_SESSION_TYPE" == "wayland" && -f /usr/lib/extest/libextest.so ]]; then
```

**`encrypt-repo` calls an undefined function.** `display_instructions()` calls `print_section`, which is only defined in `git-setup`. With `set -euo pipefail` this kills the script right after a successful git-crypt setup. Copy the `print_section` definition in (or drop the call). Secondary: `TEMP_FILES+=("$build_dir")` registers a _directory_, but `cleanup` only does `[[ -f "$f" ]] && rm -f` — the source build tree leaks.

**`hyprtheme` sets themes that aren't installed.** `Colloid-Purple-Dark-Catppuccin` and `Bibata-Modern-Ice` — only `papirus-icon-theme` is in `install-packages`. Either add the theme packages or make the script tolerate absence.

**`/etc/motd.d/motd.txt` ships a `TODO(user)` placeholder** to every login shell. Also `/etc/issue`+`issue.net` carry a corporate legal banner with a typo ("system personal" → "personnel") on what is a personal desktop.

---

## P2 — structural / correctness

**The static tree is COPY'd before every RPM install.** `COPY system_files/shared/ /` runs before Stage 1, so any RPM installed later that owns the same path silently overwrites your file. Concrete risk: the Fedora `nix` package restructured its tmpfiles in Oct 2025 ("use tmpfiles.d for nix-filesystem", "rename sysusers file to nix.conf") and `install-nix` runs at Stage 7 — your `/usr/lib/tmpfiles.d/nix.conf` is a plausible collision. Rename yours to `zz-halcyon-nix.conf` (also gets you correct sort ordering) and add a `grep` gate in `nix-verify` asserting your content survived. Same audit for `/etc/greetd/config.toml` vs. the greetd RPM (`packages-verify` does grep it, so you'd catch that one).

**`install-texlive` mirror inconsistency.** The tarball loop tries four mirrors, but `install-tl -repository` and the `tlmgr` call are hardcoded to `mirrors.mit.edu`. If MIT is the one that's down, you download from FAU then install from MIT and fail. Capture the winning mirror:

```bash
TARBALL="..."; TL_REPO="${mirror}"   # inside the loop, on success
...
"${INSTALLER}" -profile ... -repository "${TL_REPO}"
```

Also: the profile says `selected_scheme scheme-small` but two `echo`s claim `scheme-medium`. And `install-tl` failure is tolerated (`WARN … continuing`) while `built-apps-verify` hard-requires `pdflatex` — make the script fail loudly instead of deferring to a gate two steps later.

**`bazaar` is optional at install, mandatory at verify.** `install-packages` uses `|| true` for the ublue COPR install; `final-verify` gates `rpm -q … bazaar …`. Pick one.

**`Justfile build` computes a garbage version label.** `rpm -E %fedora` runs on the _runner_ (ubuntu-latest), where the macro is undefined, so `IMAGE_VERSION` becomes `%fedora.20260919`. Use the dotenv/ARG instead:

```bash
FEDORA_VERSION="${FEDORA_VERSION:-44}"
BUILD_ARGS+=("--build-arg" "IMAGE_VERSION=${FEDORA_VERSION}.$(date +%Y%m%d)")
```

Same file: `generate-build-tags` hardcodes `44` twice — derive it.

**`dnf5 -y copr enable -y <project>`** passes `-y` in the positional slot where dnf5's copr command expects an optional _chroot_. It appears to work because dnf5's parser consumes named args anywhere, but it's fragile. Use `dnf5 -y copr enable <project>`.

**`rmi` never writes `.trashinfo` files.** It creates `$XDG_DATA_HOME/Trash/info/` and leaves it empty, so trashed items can't be restored by any XDG trash manager — which the docstring explicitly promises. Write a `<name>.trashinfo` with `Path=` and `DeletionDate=` alongside each move.

**`install-kernel` payload-extracts `nvidia-settings`** without its GTK dependency chain, so the binary won't launch. Either drop it from the extraction list or install the GUI libs.

**The removals machinery is mostly dead code on a bare bootc base.** `guarded-removals`, `file-footprint`, `gnome-extensions`, `fonts-cleanup` were written against a Bazzite base. On `fedora-bootc:44` nearly every candidate is absent, `file-footprint` patches `80-bazzite.just` and `/usr/share/ublue-os/justfile` nine stages before `ublue-os-just` is installed, and `fonts-cleanup`'s header comment says "this script now runs AFTER the packages stage" when it actually runs first. That last one is dangerous: someone will trust the comment. Either prune these to what's real or fix the comments. Also `guarded-removals` uses bare `dnf`/`dnf repoquery` where everything else uses `dnf5`.

**Repo scoping.** negativo17's `fedora-nvidia` repo is enabled from Stage 2 through Stage 13, so any later `dnf5 install` can pull from it — that contradicts the stated per-use policy. Add `excludepkgs` or disable it right after `install-kernel`.

---

## P3 — hygiene

- `install-packages` includes `xorg-x11-server-Xorg` (Xwayland is a separate package; the full X server is dead weight on a Hyprland-only image), both `qt5ct` and `qt6ct`, and `pymol` — a large scientific package in a "lean" image.
- Verify these resolve on F44 before the next build: `dust` (Fedora's rust binary packages usually follow the crate name — this one is `du-dust` upstream and in Debian/Ubuntu; a mismatch fails Stage 6 outright), plus `atuin`, `tealdeer`, `uv`, `cava`, `chafa`. One-liner: `dnf5 repoquery --qf '%{name}\n' dust du-dust atuin tealdeer uv`.
- `remove-packages` strips `gamemode`, `install-packages` reinstalls it, and `guarded-removals` soft-warns if it's present. Three files with three opinions.
- CI's Copr wait-loop polls only `lionheartp/Hyprland` and `catpieleaf/kernel-p03`, but the build also consumes `ublue-os/packages` and `sneexy/zen-browser`.
- Stale doc paths: `python-packages/README.md` and `dump-to-markdown/README.md` still reference `recipes/modules/build-scripts.yml` and `files/scripts/…` from the BlueBuild era.
- `artifacthub-repo.yml` still has the placeholder UUID. `.github/dependabot.yml` covers only `github-actions` — add the `docker` ecosystem so the `fedora-bootc` base tag gets tracked.
- Build scripts are invoked two ways (`/ctx/remove-packages` needs the exec bit; `bash /ctx/install-obsidian` doesn't). Normalize, and add `chmod` verification or use `bash` consistently.

---

## AGENTS.md

Written and attached below. It encodes the invariants that are currently only implicit in comments — stage ordering, `install_weak_deps=False`, the repo enable/disable lifecycle, why the NVIDIA subpackages are `rpm2cpio`'d rather than installed, bootc's `/var` rules, and a "known traps" section covering the four bugs above so an agent doesn't reintroduce them. It also documents the `system_files` overwrite hazard and the `.just` syntax-check gap, since neither is discoverable from the code.

I can't apply the fixes to your tree from here — if you paste the repo in (or want a `git apply`-able patch series against `container`), I'll produce one.
