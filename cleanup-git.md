# Shrinking an Oversized `.git` Folder

> Scenario: `gdu` shows `.git/` at ~150 MiB inside `~/Git/configs/linux-system/dots`, while the checked-out working tree is only ~51 MiB. This guide explains why that gap appears and how to close it safely.

## Why this happens

Git never deletes anything on its own. Every blob (file version) you've ever committed stays in `.git/objects/` forever, even after you delete the file, replace it with a symlink, or overwrite it with a smaller version. Your working tree only shows the _current_ snapshot, but `.git/` holds the full archive of every snapshot that ever existed. So a repo where large or frequently-changed binary files were committed and later removed — regenerated build artifacts, real wallpaper images later swapped for symlinks, compiled dictionaries, plugin `.so` files rebuilt every time — will keep all those old blobs packed away, and `git gc` on its own can't touch them because they're still reachable from history.

That's the mechanism behind the size gap: ~50 MiB of _current_ content, ~100 MiB of _historical_ content that Git is dutifully preserving because nothing has ever told it those old blobs are safe to forget.

## Step 1 — Diagnose before you touch anything

Don't guess at what's bloating the repo; measure it.

```bash
cd ~/Git/configs/linux-system/dots

# Quick top-level number: how big is the packfile, how many objects
git count-objects -vH
```

This gives you `size-pack` (the packed object store) and `size` (loose objects). If `size-pack` is most of the 150 MiB, the bloat is committed history, not staged garbage — `git gc` alone will not shrink it.

For a proper breakdown of _what_ is bloating it, use **git-sizer**, GitHub's own diagnostic tool:

```bash
# Arch: pacman -S git-sizer
# or:   go install github.com/github/git-sizer@latest
git-sizer --verbose
```

It reports commit count, tree size, and — most usefully — the biggest individual blobs in history, ranked with a concern rating (`*` to `*****`). This tells you exactly which files to target instead of rewriting history blind.

To list the actual largest objects and the paths they correspond to:

```bash
git rev-list --objects --all |
  git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' |
  sed -n 's/^blob //p' |
  sort -k2 -n -r |
  head -20
```

Common culprits in a dotfiles/config repo specifically:

| Pattern                                                                 | Why it bloats history                                                 |
| ----------------------------------------------------------------------- | --------------------------------------------------------------------- |
| Compiled plugin binaries (`*.so`, prebuilt shells)                      | Re-committed as a new incompressible blob every rebuild               |
| Real image files later replaced by symlinks (e.g. wallpapers)           | Every old multi-MB image blob stays; images don't delta-compress well |
| Compiled dictionaries/caches (`*.rws`, spell-check `.dic`, font caches) | Regenerated binary build artifacts that shouldn't be tracked at all   |
| Editor/IDE state or lockfiles rewritten frequently                      | Small individually, but many near-duplicate versions add up           |

## Step 2 — Decide if a history rewrite is the right call

Rewriting history changes every commit hash from the rewrite point forward. Before doing it, confirm:

- **Is this repo effectively yours alone**, or does it have other clones/forks that would need to be re-cloned afterward? For a personal dotfiles repo, this is usually a non-issue — but if you or anyone else has another machine with a clone that does `git pull`, that clone will silently _resurrect_ the full old history on its next push unless it's re-cloned first.
- `git gc --aggressive` **will not help** if the repo is already a single well-packed packfile (check `git count-objects -vH` — one packfile, no loose objects sitting around). Aggressive gc re-tunes delta compression on existing objects; it cannot delete blobs that history still reaches. The only real fix for “blobs that shouldn't exist anymore” is rewriting the commits that reference them.

If you're sure, continue.

## Step 3 — Back up first

This is destructive. Make an exact mirror clone before doing anything else — this is your undo button:

```bash
git clone --mirror <your-remote-url> ~/dots-backup.git
```

Keep it until you've verified the rewritten repo pushes and clones correctly.

## Step 4 — Install `git-filter-repo`

`git filter-repo` is the tool the Git project itself now recommends in place of `git filter-branch`, which is officially deprecated (slow, and has correctness gotchas the maintainers have stated can't be fixed backward-compatibly). It's also generally preferred over the older **BFG Repo-Cleaner** for anything beyond simple "strip files bigger than X" jobs — BFG is still maintained and fine for that narrow case, but `filter-repo` handles path-based, content-based, and size-based rewrites in one coherent tool, and it's what GitHub's own docs point to alongside BFG for scrubbing sensitive or oversized data from history.

```bash
sudo pacman -S git-filter-repo      # Arch
# or: pip install --user git-filter-repo
git filter-repo --version
```

`filter-repo` refuses to run on a repo that isn't a fresh clone unless you pass `--force` — this is a deliberate safety rail, not a bug, since your working copy isn't a fresh clone. The mirror backup from Step 3 is what makes `--force` safe to use here.

## Step 5 — Run the rewrite

Work from the repo root. Three passes, in this order:

### Pass 1 — Drop known build-artifact patterns from all history

```bash
git filter-repo --force --invert-paths \
  --path-glob '*.so' \
  --path-glob '*.rws' \
  --path-glob '*.dic'
```

Adjust the glob list to match what `git-sizer` / the `rev-list` command from Step 1 actually flagged for _your_ repo — don't copy this list blindly.

### Pass 2 — Strip oversized historical blobs by content, regardless of path

This catches files that sat at a path that's _currently_ small or symlinked (like a wallpaper path that now points to `/usr/share/...` but used to hold a real 5 MB PNG):

```bash
git filter-repo --force --strip-blobs-bigger-than 1M
```

Only run this once Pass 1 confirms nothing _currently tracked_ legitimately exceeds that threshold — check with:

```bash
git ls-tree -r -l HEAD | awk '$4 > 1000000 {print $4, $5}' | sort -n
```

If something legitimate is over 1M (e.g. a genuinely large but wanted file), raise the threshold or exclude that path explicitly.

### Pass 3 (optional) — Drop every file that no longer exists in the tree

```bash
git filter-repo --force --paths-from-file <(git ls-files)
```

This keeps _only_ currently-tracked paths' full history and drops anything else ever committed and later deleted. Use with care — it also removes history for legitimately-renamed-away files unless you've set up path renames first.

`filter-repo` automatically prunes commits that become empty, repacks the result, and rewrites in a single pass — no manual `git gc` is needed afterward, though running one won't hurt:

```bash
git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

## Step 6 — Re-attach the remote and push

`filter-repo` deliberately removes the `origin` remote as a safety measure (documented in its own FAQ, "Why is my origin removed?") so you can't accidentally push a half-checked rewrite:

```bash
git remote add origin <your-remote-url>
git push --force --set-upstream origin main
```

## Step 7 — Prevent recurrence

Whatever caused the bloat, stop tracking it going forward. Add to `.gitignore`:

```gitignore
*.so
*.rws
*.dic
```

And regenerate/symlink those artifacts from your setup scripts instead of committing them (they already appear to be handled this way for wallpapers in this dotfiles setup — extend the same pattern to any other regenerable binary).

If a real binary genuinely needs to stay in version control long-term (not just a one-off leftover), consider **Git LFS** — it stores the file externally and keeps only a pointer in the repo, which avoids this problem entirely for files that are supposed to be tracked.

## Step 8 — Verify

```bash
git count-objects -vH        # size-pack should have dropped sharply
git log --oneline            # history intact; hashes are new
git-sizer --verbose          # re-confirm nothing big remains in history
```

Then clone fresh into a scratch directory to confirm the remote is actually smaller and everything still works:

```bash
git clone <your-remote-url> /tmp/dots-test
du -sh /tmp/dots-test/.git
rm -rf /tmp/dots-test
```

For a hosted remote (GitHub/GitLab), note that the _server-side_ size won't necessarily drop the instant you force-push — the host runs its own garbage collection on its schedule. On GitHub specifically, if the number doesn't come down after a while, their support can trigger a GC manually.

## Caveats, stated plainly

- **All commit hashes change** from the rewrite point onward. Any other machine with a clone of this repo must be **re-cloned**, not pulled — a stale clone that does `git pull && git push` will resurrect the entire pre-rewrite history on the remote.
- Files removed by the rewrite become **untracked** in your current working copy afterward (they're simply gone from git, not from disk, unless you separately delete them).
- If this repo is ever shared with collaborators, they must **rebase**, never merge, any local branches onto the rewritten history.
- Once you've verified everything works, delete the backup mirror: `rm -rf ~/dots-backup.git`.

## Quick reference: full command sequence

```bash
cd ~/Git/configs/linux-system/dots

# 1. Diagnose
git count-objects -vH
git-sizer --verbose

# 2. Backup
git clone --mirror <remote-url> ~/dots-backup.git

# 3. Rewrite (adjust patterns to what step 1 actually found)
git filter-repo --force --invert-paths --path-glob '*.so' --path-glob '*.rws' --path-glob '*.dic'
git filter-repo --force --strip-blobs-bigger-than 1M

# 4. Re-attach remote and push
git remote add origin <remote-url>
git push --force --set-upstream origin main

# 5. Verify
git count-objects -vH
git clone <remote-url> /tmp/dots-test && du -sh /tmp/dots-test/.git && rm -rf /tmp/dots-test
```

Expected result: `.git` should drop from ~150 MiB to roughly the size of your actual tracked content plus a small history overhead — typically a few MiB for a config-file-sized repo, not another 100 MiB of leftover binaries.
