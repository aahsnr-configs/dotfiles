Reviewed both files line-by-line and cross-checked against how `lsp-mode`, `treesit`, `corfu`, and the redisplay-adjacent minor modes actually behave. Here's what's actually happening, ranked by impact.

## Root cause #1 — LSP stack, not early-init.el

Your `early-init.el` is fine — `gc-cons-threshold` deferral, `file-name-handler-alist` suspension, `read-process-output-max` at 1MB, PGTK IM-context disabling, all standard and correctly ordered. It is not the source of the stutter.

The stutter is architectural, in `config.org`:

|               | Your personal config                                          | Your Doom Python setup ([[doom-emacs-python]]) |
| ------------- | ------------------------------------------------------------- | ---------------------------------------------- |
| LSP client    | `lsp-mode` (line 6232)                                        | `eglot`                                        |
| Python server | `lsp-pyright` → `basedpyright` (line 7143‑7145)               | `pyrefly`                                      |
| Diagnostics   | `flycheck` **+** `lsp-ui` both active (lines 6309‑6324, 6349) | `flymake` (native, single pipeline)            |

`lsp-mode` does materially more per-notification work than `eglot` (bigger JSON→plist marshalling surface, its own overlay/bookkeeping layer on top of what flycheck/lsp-ui already draw). On top of that, `basedpyright` is a Python/Node-class server; `pyrefly` is Meta's Rust engine explicitly built for "typecheck on every keystroke" (~1.8M LOC/sec, vs. basedpyright/pyright needing tens of seconds on large repos). With `corfu-auto-delay 0.24` and `corfu-auto-prefix 2` (line 4224‑4225), every couple of keystrokes fires a completion request through `lsp-completion-at-point` into `basedpyright` — if that request is slow, corfu blocks the redisplay path waiting on it, and _that's_ the stutter you feel that doesn't exist in your Doom+eglot+pyrefly setup.

**This is the single biggest lever.** Since `eglot` is built-in (no `packages.el` edit needed) and you already have a working `pyrefly`+`ruff` recipe in Doom, mirroring it here would likely close most of the gap by itself. I didn't touch `packages.el`, so if `flymake-ruff`/`eglot-booster` aren't already declared there, you'll need to add them yourself before this works.

## Confirmed bug (not a stutter cause, but worth fixing) — dead tree-sitter-auto settings

```
grep -n "treesit-enabled-modes\|treesit-auto-install-grammar" config.org
1276:  (treesit-enabled-modes t)
1274:  (treesit-auto-install-grammar 'always)
```

Both of these are set inside `(use-package treesit :straight (:type built-in) ...)` (line 1258). They are **not variables `treesit.el` defines** — they belong to the third-party `treesit-auto` package, which is never `use-package`'d anywhere in your file. `:custom` on an undefined symbol just does a bare `setq`; it silently creates a free-standing variable that nothing reads. There is no `major-mode-remap-alist` entry mapping `python-mode → python-ts-mode` anywhere either.

Net effect: your Python buffers are opening in plain `python-mode`, not `python-ts-mode`. `treesit-font-lock-level 4` (line 1279) is never exercised for Python — you're getting classic regex-based `font-lock-keywords`. This isn't causing your stutter (regex font-lock is generally _cheaper_ than depth-4 treesit queries), but it does mean the "AST-aware" framing in your electric-pair and indent-bars comments (lines 1310, 1905) doesn't actually apply to Python today. If you want tree-sitter Python, you need either `treesit-auto` as a real package, or explicitly:

```elisp
(add-to-list 'major-mode-remap-alist '(python-mode . python-ts-mode))
```

## Compounding factors in the redisplay path

These stack on top of #1 and are all things stock Doom either doesn't run, or runs more cheaply:

**1. `hl-line` around-advice runs on every command, in every buffer** (lines 2013‑2030):

```elisp
(define-advice global-hl-line-highlight (:around (fn) guard-excluded-modes)
  (if (derived-mode-p 'dired-mode 'magit-mode 'compilation-mode ... 'treemacs-mode) ; 15 modes
      (when global-hl-line-overlay (delete-overlay global-hl-line-overlay))
    (funcall fn)))
```

`global-hl-line-highlight` fires from `post-command-hook`, i.e. after essentially every self-insert while you type. This advice does a 15-way `derived-mode-p` walk before deciding whether to just call the original function — pure overhead on every keystroke, in every buffer, including the ones it's meant to exclude. Doom's equivalent normally just doesn't enable `hl-line` in those buffers in the first place, so there's no per-command branch to pay for.

Minimal fix — drop the global mode + advice, enable locally where you actually want it:

```elisp
;; Before: global-hl-line-mode + around-advice on every post-command
;; After: local hl-line-mode only where wanted — zero per-command cost elsewhere
(dolist (hook '(prog-mode-hook text-mode-hook conf-mode-hook org-mode-hook dired-mode-hook))
  (add-hook hook #'hl-line-mode))
```

**2. `colorful-mode` on `prog-mode` globally** (line 2053): scans buffer text for color literals on every fontification pass. Not something Doom enables by default. If you don't need it while typing Python, scope it to styling/markup modes only and drop `prog-mode` from the hook list (line 2051‑2053).

**3. `whitespace-mode` on `prog-mode`** (line 1826): even restricted to `space-before-tab space-after-tab indentation`, it's another `font-lock`-keyword contributor running on top of your primary syntax highlighting. `ws-butler` (already present, line 1840) covers the practical whitespace-hygiene need without the extra font-lock pass.

**4. `jit-lock-defer-time` disabled on a mistaken premise** (line 232‑234):

```elisp
;; Defers syntax highlighting by 50ms to prevent font-lock and LSP tokens from blocking the main thread.
;; COMMENT: No longer needed for lsp-mode
;; (setq jit-lock-defer-time 0.05)
```

This is incorrect — `jit-lock-defer-time` defers _fontification_, which competes with your keystrokes for the main thread regardless of which LSP client is attached; it isn't an LSP-specific knob. Disabling it removes a genuine defense against typing-induced redisplay stalls. Worth re-enabling:

```elisp
(setq jit-lock-defer-time 0.05)
```

**5. Two diagnostics UIs stacked** (`flycheck` line 6349 + `lsp-ui` line 6309): both maintain their own overlays/fringe indicators on the same buffer. Not a per-keystroke cost directly (checks are `save`/`mode-enabled` only, line 6363), but it's extra overlay bookkeeping layered on top of #1 that Doom's single-pipeline `flymake` setup doesn't carry.

## Suggested order of operations

1. Re-enable `jit-lock-defer-time` (line 232‑234) — zero risk, one-line change.
2. Replace the `hl-line` global+advice pattern with scoped local hooks — removes a genuine per-keystroke tax.
3. Drop `prog-mode` from `colorful-mode` and `whitespace-mode` hooks, or move them behind an idle timer.
4. The big one: try `eglot` + `pyrefly` for Python instead of `lsp-mode` + `lsp-pyright`/`basedpyright`, matching your Doom setup — this is where I'd expect the largest felt difference, since it's the same asymmetry you already validated works well in Doom.
5. Separately (correctness, not perf): either wire up real `treesit-auto` or add the `major-mode-remap-alist` entry if you actually want tree-sitter-backed Python highlighting.

Want me to draft the concrete `eglot`+`pyrefly`+`ruff` block for the Python section (mirroring your Doom config) so you can drop it in place of the current `lsp-pyright` block?

You're right to push back — let me correct the record rather than double down.

## Where I was wrong

I claimed lsp-mode-vs-eglot was the root cause. That doesn't survive contact with Doom's actual source. Doom's `:tools lsp` module, when the `+eglot` flag isn't set, wires up lsp-mode + corfu almost identically to your personal config: when the corfu completion module is active, Doom sets lsp-completion-provider to none and hooks lsp-completion-mode onto lsp-mode-hook — that's the same two lines you have at 6244/6278. Doom's own docs are candid that lsp-mode is more featureful and beginner-friendly than eglot, but that comes at a baseline performance cost — but that cost applies equally to both your setups, since both use lsp-mode. It can't explain a difference between them. I retract that conclusion.

One thing I can't resolve from the files alone: my notes said your Doom Python setup uses eglot+pyrefly, but your message implies your Doom setup uses lsp-mode without stutter. Those don't reconcile — **could you confirm which LSP client and Python server your Doom config actually runs (eglot+pyrefly, or lsp-mode+something)?** If it's lsp-mode+pyrefly, the server itself (not the client) becomes a much stronger suspect, since pyrefly is a different order of magnitude faster than basedpyright/pyright on large candidate/diagnostic requests. I'll update my notes once you confirm.

## What actually looks new and different

**`flycheck-annotate-mode` (line 6352) is a brand-new feature** — shipped in Flycheck 38, ~July 2026: it shows error messages inline next to the code they refer to, in the spirit of VS Code's Error Lens and the inline diagnostics of Neovim, Helix and Zed, obsoleting the old third-party `flycheck-inline` package. This is recent enough that it's very unlikely to be in whatever Doom baseline you're comparing against — it's something this config opted into on top. Inline/below-style annotation overlays that live in the buffer and must be tracked through redisplay are a plausible, concrete source of felt typing lag, independent of which LSP client is running. Worth testing in isolation: comment out line 6352's `flycheck-annotate-mode` hook and see if the stutter changes.

**The `hl-line` advice has a much cheaper native replacement.** Since Emacs 28, `hl-line.el` ships `global-hl-line-modes`, which restricts the global mode to a mode list _declaratively_ — no `post-command-hook` advice needed at all. One real-world Doom-adjacent config does exactly this: (setq global-hl-line-modes '(prog-mode dired-mode)). Your version instead wraps `global-hl-line-highlight` — which already runs on every command via `post-command-hook` — in a 15-way `derived-mode-p` check every single time. Swap:

```elisp
;; Before: global-hl-line-mode + around-advice re-checked on every command
;; After: native scoping, checked once per mode/buffer switch, not per keystroke
(setq global-hl-line-modes '(prog-mode conf-mode org-mode dired-mode))
(global-hl-line-mode 1)
```

and drop the `define-advice` and the two `evil-visual-state` hooks entirely (line 2013-2034) — `global-hl-line-modes` already covers exclusion, and you can add a `(add-hook 'evil-visual-state-entry-hook #'global-hl-line-unhighlight)` back only if you still want the visual-selection behavior.

**`colorful-mode` and `whitespace-mode` on `prog-mode`** (lines 2053, 1826) remain plausible secondary contributors — extra font-lock-keyword passes over the same buffer text — though I want to flag I haven't been able to directly verify Doom's default editor module _doesn't_ run equivalents, so treat this one as lower-confidence than the two above.

The dead `treesit-auto` variables (line 1274/1276) stand as before — a real bug, but not a stutter cause.

## The honest next step

I've done what static reading can do. To actually isolate this rather than keep guessing, run Emacs's built-in profiler while reproducing the stutter:

```elisp
(profiler-start 'cpu)
;; ... type in a Python buffer for ~15 seconds ...
(profiler-report)
```

That'll show exactly which function is eating time — `lsp-completion-at-point`, `flycheck-annotate`-something, `global-hl-line-highlight`, `colorful--change`, or something none of us have named yet. Want me to walk through reading that report once you have it?
