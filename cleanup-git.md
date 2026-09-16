# Shrinking the `.git` folder of the dots repo

> Written: 2026-09-16 · Verified against the official [git-filter-repo manual](https://mankier.com/1/git-filter-repo) and [GitHub's docs](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)

## Problem

`gdu` shows `.git/` at **146 MiB** while the checked-out tree is only **~50 MiB**.

### Diagnosis (measured on this repo, 2026-09-16)

```
git count-objects -vH        # size-pack: 144.97 MiB (single packfile)
git ls-tree -r -l HEAD       # current tree: 260 files, 49.0 MiB
```

~135 MiB of the pack is **historical blob content**, mostly:

| Culprit | Size | Why it bloats the pack |
|---|---|---|
| `.config/anyrun/plugins/*.so` | ~40 MiB | Compiled plugin binaries, re-committed after every rebuild (each rebuild = a new incompressible blob; `librink.so` alone is 9.8 MiB) |
| Old real wallpaper PNGs (`Pictures/Wallpapers/`) | ~80 MiB | They were replaced by symlinks at the same paths, but every old multi-MB PNG blob stays in the pack. PNGs do not delta-compress |
| `.config/enchant/aspell/en-custom.rws` + `*.dic` | ~9 MiB | Compiled spell-check dictionaries — build artifacts |

**`git gc --aggressive` will NOT help** — the repo is already a single well-packed
packfile. The only real fix is rewriting history with `git filter-repo`
(the officially recommended tool; `filter-branch` is deprecated and BFG is unmaintained).

## Before you start

- **Back up first.** History rewriting is destructive:

  ```bash
  git clone --mirror git@github.com-aahsnr-configs:aahsnr-configs/dots.git ~/dots-backup.git
  ```

- Install the tool:

  ```bash
  sudo pacman -S git-filter-repo      # or: pip install --user git-filter-repo
  git filter-repo --version           # sanity check
  ```

- Commit or stash nothing pending — run from a clean working tree.

## The cleanup

Run from the repo root (`~/Git/configs/linux-system/dots`). All `filter-repo`
invocations need `--force` because this is not a fresh clone (documented safety
check); the mirror backup above is your undo button.

### Pass 1 — remove build-artifact paths from ALL history

```bash
git filter-repo --invert-paths \
  --path-glob '*.so' \
  --path-glob '*.rws' \
  --path-glob '*.dic' \
  --force
```

`filter-repo` prunes commits that become empty and **repacks/prunes automatically**
at the end — no manual `git gc` needed.

### Pass 2 — strip remaining oversized historical blobs

This removes the old real wallpaper PNG blobs. It is safe because after Pass 1
nothing in the current tree exceeds 1 MiB (wallpapers are tracked as symlinks,
configs are small):

```bash
git filter-repo --strip-blobs-bigger-than 1M --force
```

### Pass 3 (optional) — drop every deleted file from history

Keeps only paths that are currently tracked, removing any other historical
deleted files:

```bash
git filter-repo --paths-from-file <(git ls-files) --force
```

> Note: filtering by path keeps ALL historical versions of a tracked path, which
> is why Pass 2 (content-based) is needed for the old wallpaper blobs — they sat
> at the same paths as today's symlinks. Run the passes in this order.

### Re-attach the remote and force-push

`filter-repo` deliberately removes `origin` as a safety measure (see
"Why is my origin removed?" in its manual):

```bash
git remote add origin git@github.com-aahsnr-configs:aahsnr-configs/dots.git
git push --force --set-upstream origin main
```

### Prevent recurrence

The artifacts are regenerated/symlinked by the system setup, so never track them
again. Add to `.gitignore` and commit:

```gitignore
*.so
.config/anyrun/plugins/
.config/enchant/aspell/*.rws
*.dic
```

## Verify

```bash
git count-objects -vH                  # size-pack should be ~1-3 MiB
git log --oneline                      # history intact (hashes changed)
ls .config/anyrun/plugins/ 2>/dev/null # should be symlinks/absent, not tracked blobs
```

Then clone fresh into a scratch dir and confirm it is small and complete:

```bash
git clone git@github.com-aahsnr-configs:aahsnr-configs/dots.git /tmp/dots-test
du -sh /tmp/dots-test/.git
rm -rf /tmp/dots-test
```

## Caveats (important)

- **All commit hashes change.** Any other machine with a clone of this repo must
  be **re-cloned** (or `git fetch && git reset --hard origin/main` on a clean tree).
  An old clone that does `git pull && git push` will **resurrect the entire old
  bloated history** — GitHub calls this re-contamination.
- The `.so` / `.rws` / `.dic` files currently on disk become **untracked** after
  the rewrite. Keep them if the running setup uses them directly; they are simply
  no longer in git.
- Once everything is verified working, delete the backup: `rm -rf ~/dots-backup.git`
- If this repo were ever shared with collaborators, they must rebase (never merge)
  any local branches onto the rewritten history.

## Expected result

`.git`: **146 MiB → roughly 1-3 MiB** (the actual config content only).
