### 🔴 BUG #2 — `org-super-agenda` `:take` Syntax in Custom Commands (CRITICAL — Crashes Daily Dashboard)

**Location:** `Org Agenda Custom Commands` — the `ar/org-sa-daily-groups` variable

**Current (broken):**

```emacs-lisp
(:take (10 :deadline past :scheduled past)   ;; Overdue
(:take (7 :deadline (before "+7d"))           ;; Due Soon
(:take (15 :anything t)                       ;; Other Tasks
```

**Root cause:** The upstream `:take` dispatcher is defined as:

```emacs-lisp
(cl-defun org-super-agenda--group-dispatch-take (items (n group)) ...)
```

The destructuring pattern `(n group)` splits the argument into exactly two elements: `n` (integer) and `group` (a **list** of selectors) [[org-super-agenda.el source]]. With the flat syntax `(10 :deadline past :scheduled past)`, the destructuring yields `n=10` and `group=:deadline` (a bare symbol). The subsequent `org-super-agenda--group-dispatch` then attempts `(cl-loop for (selector args) on group by 'cddr ...)` on the symbol `:deadline`, producing `wrong-type-argument listp :deadline`.

The **global defaults** already use the correct nested syntax:

```emacs-lisp
(:take (15 (:anything t))   ;; ✅ n=15, group=(:anything t)
```

**Fix** — wrap the selectors in an inner list for all three `:take` occurrences in `ar/org-sa-daily-groups`:

```emacs-lisp
(:take (10 (:deadline past :scheduled past)))   ;; Overdue
(:take (7 (:deadline (before "+7d"))))           ;; Due Soon
(:take (15 (:anything t)))                       ;; Other Tasks
```

---

### 🟡 ISSUE #3 — `dirvish` Points to a Community Fork (Medium — Intentional but Fragile)

**Location:** `Dirvish` subsection

**Current:**

```emacs-lisp
:ensure (:host github :repo "latiagertrutis/dirvish" :files (:defaults "extensions/*.el"))
```

**Finding:** The official Dirvish repository is `alexluigit/dirvish` . The `latiagertrutis/dirvish` fork was created because the original maintainer went inactive for over a year . This is **intentional**, not a typo. However, community forks can diverge from the upstream API, and Elpaca recipe `:files` globs may break if the fork restructures its directory layout.

**Recommendation:** Add a comment documenting why the fork is used, and pin to a specific `:ref` commit hash for reproducibility.

---

### 🟡 ISSUE #4 — `denote-merge` Missing Space in `:ensure` (Low — Style)

**Location:** `Denote Merge` subsection

**Current:**

```emacs-lisp
:ensure(:host github :repo "protesilaos/denote-merge")
```

**Finding:** Syntactically valid Elisp (the `(` starts a new form after the keyword), but inconsistent with every other `:ensure` in the config which uses `:ensure (...)` with a space.

**Fix:**

```emacs-lisp
:ensure (:host github :repo "protesilaos/denote-merge")
```

---

### 🟢 Verified Correct (No Issues Found)

| Area                                                                                                                                                                  | Verification                                                        |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| `eglot-documentation-renderer 'markdown-ts-view-mode`                                                                                                                 | Valid Emacs 31 value; confirmed in `eglot.el` source and EGLOT-NEWS |
| `eglot-code-action-indications '(eldoc-hint)`                                                                                                                         | Valid; source shows `nearby`, `margin`, `eldoc-hint`, `left-fringe` |
| `ghostel` API (`ghostel-project`, `ghostel-send-key`, `ghostel-backward-kill-word`, `ghostel-eval-cmds`, `ghostel-pre-spawn-hook`, `ghostel-tramp-shell-integration`) | All confirmed in ghostel v0.45.0 source and docs                    |
| `evil-ghostel`, `ghostel-eshell`, `ghostel-compile`, `ghostel-comint`                                                                                                 | Bundled extensions, confirmed in ghostel repo                       |
| `denote-solo` API (`denote-solo-switch`, `denote-solo-directories`, `denote-solo-modeline-function`)                                                                  | Confirmed against README                                            |
| `denote-merge` repo `protesilaos/denote-merge`                                                                                                                        | Confirmed on GitHub and GNU ELPA                                    |
| `denote-explore` repo `pprevos/denote-explore`                                                                                                                        | Confirmed on GitHub                                                 |
| `denote-wordcloud` on MELPA                                                                                                                                           | Confirmed                                                           |
| `org-super-agenda` `:take` in **global defaults**                                                                                                                     | Correct nested syntax `(:take (15 (:anything t)))`                  |
| `org-modern-replace-stars`, `org-modern-checkbox`, `org-modern-block-name`, `org-modern-list`                                                                         | All correct types (list of strings, alist, alist, alist)            |
| `flyover` package                                                                                                                                                     | Confirmed real package                                              |
| `evil-ts-obj` repo `dvzubarev/evil-ts-obj`                                                                                                                            | Confirmed, requires Emacs 30.0.50+                                  |
| `eldoc-childframe` custom fork with `:ensure nil`                                                                                                                     | Correct for local `lisp/` file; load-path registered earlier        |
| `projection` package `mohkale/projection`                                                                                                                             | Confirmed on GitHub                                                 |
| `bufferlo` package                                                                                                                                                    | Confirmed real package                                              |

---

## Interactive Testing Guide

Below is a structured, section-by-section testing checklist. Execute each test in a **fresh Emacs instance** (`emacs -Q --load ~/.config/emacs/init.el`) unless noted otherwise. Record pass/fail for each.

---

### Phase 0: Pre-Flight

| #   | Test                        | Expected                                                     | How                             |
| --- | --------------------------- | ------------------------------------------------------------ | ------------------------------- |
| 0.1 | Emacs starts without errors | No `*Backtrace*` buffer, no error in `*Messages*`            | `emacs &` → check `*Messages*`  |
| 0.2 | Elpaca bootstrap completes  | `elpaca-process-queues` runs, no `*elpaca-bootstrap*` errors | Check `*Messages*` for "elpaca" |
| 0.3 | `elpaca-wait` unblocks      | Init file finishes reading                                   | Emacs becomes responsive        |
| 0.4 | `no-littering` paths active | `custom-file` points to `etc/custom.el`                      | `C-h v custom-file RET`         |
| 0.5 | Theme loads                 | Tokyo Night palette visible                                  | Visual check                    |

---

### Phase 1: Core Emacs

| #    | Test                        | Expected                                | How                                                                 |
| ---- | --------------------------- | --------------------------------------- | ------------------------------------------------------------------- |
| 1.1  | GC settings                 | `gc-cons-threshold` = 16MB post-startup | `C-h v gc-cons-threshold RET`                                       |
| 1.2  | UTF-8 coding                | `locale-coding-system` = `utf-8`        | `C-h v locale-coding-system RET`                                    |
| 1.3  | `save-place-mode` active    | Cursor restored on reopen               | Open file, move cursor, kill buffer, reopen                         |
| 1.4  | `recentf` active            | Recent files listed                     | `M-x recentf-open-files RET`                                        |
| 1.5  | `savehist` active           | Minibuffer history persists             | `M-x` → type partial → kill Emacs → restart → `M-x` → check history |
| 1.6  | `gcmh-mode` active          | `gcmh-mode` enabled (unless MPS build)  | `C-h v gcmh-mode RET`                                               |
| 1.7  | `blink-cursor-mode` off     | No blinking cursor                      | Visual check                                                        |
| 1.8  | `delete-selection-mode` on  | Typing replaces selection               | Select text → type → selection replaced                             |
| 1.9  | Trailing whitespace visible | Red trailing spaces in prog-mode        | Open `.py` file with trailing spaces                                |
| 1.10 | `auto-mode-case-fold` nil   | Case-sensitive mode matching            | `C-h v auto-mode-case-fold RET`                                     |

---

### Phase 2: Vim Emulation (Evil)

| #    | Test                       | Expected                              | How                                                  |
| ---- | -------------------------- | ------------------------------------- | ---------------------------------------------------- |
| 2.1  | Evil loads                 | Normal state on startup               | Open file → cursor is block                          |
| 2.2  | State cursors              | Insert=bar, Normal=box, Visual=hollow | `i` → check cursor; `ESC` → check; `v` → check       |
| 2.3  | `evil-collection` active   | Vim bindings in help/dired            | Open `*Help*` → `j`/`k` scroll                       |
| 2.4  | `evil-commentary`          | `gcc` comments line                   | Open `.py` → `gcc` → line commented                  |
| 2.5  | `evil-surround`            | `ysiw"` wraps word in quotes          | `ysiw"` → word wrapped                               |
| 2.6  | `evil-snipe`               | `s` + 2 chars jumps                   | `s` → type 2 chars → jump                            |
| 2.7  | `evil-easymotion`          | `gs` prefix works                     | `gss` → Avy-style char jump                          |
| 2.8  | `evil-numbers`             | `C-a` increments number               | Put cursor on `42` → `C-a` → `43`                    |
| 2.9  | `evil-exchange`            | `gx` swaps regions                    | Select region → `gx` → select other → auto-swap      |
| 2.10 | `evil-goggles`             | Visual pulse on `dd`                  | `dd` → brief highlight flash                         |
| 2.11 | `evil-lion`                | `gl` aligns text                      | Select lines → `gl=` → aligned                       |
| 2.12 | `undo-fu`                  | `C-r` redoes                          | Edit → `u` → `C-r` → redo                            |
| 2.13 | `goto-chg`                 | `g;` jumps to last change             | Edit → move → `g;` → back to edit                    |
| 2.14 | Smart comment continuation | `o` continues comment                 | Type `# comment` → `ESC` → `o` → `# ` prefix appears |
| 2.15 | `evil-mc`                  | `M-d` creates multi-cursor            | Select word → `M-d` → next occurrence highlighted    |
| 2.16 | `evil-multiedit`           | `M-d` in visual state                 | `v` → select → `M-d` → multi-edit                    |

---

### Phase 3: General / Leader Keys

| #   | Test        | Expected                | How                          |
| --- | ----------- | ----------------------- | ---------------------------- |
| 3.1 | `SPC SPC`   | Opens `M-x`             | `SPC SPC` → command prompt   |
| 3.2 | `SPC :`     | Opens `eval-expression` | `SPC :` → eval prompt        |
| 3.3 | `SPC u`     | Universal argument      | `SPC u` → `C-u` active       |
| 3.4 | `SPC !`     | Shell command           | `SPC !` → shell prompt       |
| 3.5 | `which-key` | Popup after 0.7s idle   | `SPC` → wait → popup appears |

---

### Phase 4: Editor Behavior

| #    | Test                   | Expected                                | How                                                    |
| ---- | ---------------------- | --------------------------------------- | ------------------------------------------------------ |
| 4.1  | `super-save`           | Auto-saves on idle                      | Edit file → wait 60s → file saved                      |
| 4.2  | `org-auto-tangle`      | Tangles on org save                     | Open `config.org` → edit → save → `init.el` updated    |
| 4.3  | `nerd-icons`           | Icons render                            | `SPC d d` → file icons visible                         |
| 4.4  | Fonts                  | JetBrainsMono Nerd Font at 12.3pt       | `C-h v frame-font RET` (or visual)                     |
| 4.5  | `doom-themes`          | Tokyo Night active                      | Visual check                                           |
| 4.6  | `solaire-mode`         | Side windows have different bg          | Open Dirvish sidebar → bg differs                      |
| 4.7  | `transient`            | Transient menus work                    | `SPC d ?` → Dirvish dashboard                          |
| 4.8  | `ligature`             | `=>` renders as ligature                | Open `.js` file → type `=>` → ligature                 |
| 4.9  | `prettify-symbols`     | `lambda` → `λ` in elisp                 | Open `.el` file → type `lambda` → `λ`                  |
| 4.10 | `autorevert`           | Buffer syncs with disk                  | Edit file externally → buffer updates                  |
| 4.11 | `subword`              | `w` stops at camelCase                  | Open `.java` → `w` on `myVariable` → stops at `V`      |
| 4.12 | `display-line-numbers` | Relative line numbers in prog           | Open `.py` → line numbers visible                      |
| 4.13 | `hl-line`              | Active line highlighted                 | Visual check                                           |
| 4.14 | `rainbow-delimiters`   | Colored parens in code                  | Open `.el` → nested parens colored                     |
| 4.15 | `indent-bars`          | Vertical indent guides                  | Open `.py` → vertical bars visible                     |
| 4.16 | `move-text`            | `M-j`/`M-k` moves lines                 | `M-j` → line moves down                                |
| 4.17 | `ws-butler`            | Trailing whitespace trimmed on save     | Add trailing spaces → save → spaces removed            |
| 4.18 | `dtrt-indent`          | Indentation detected                    | Open file with 2-space indent → `tab-width` = 2        |
| 4.19 | `colorful-mode`        | Hex colors previewed                    | Open `.css` → `#ff0000` shows color swatch             |
| 4.20 | `doom-modeline`        | Custom modeline active                  | Visual check                                           |
| 4.21 | `avy`                  | `SPC y c` → char timer jump             | `SPC y c` → type char → jump                           |
| 4.22 | `ace-window`           | `SPC w w` (or configured) → window jump | Trigger ace-window → select window                     |
| 4.23 | `anzu`                 | Match count in modeline                 | `/` → search → "1 of 5" in modeline                    |
| 4.24 | `jinx`                 | Spell-check in org                      | Open `.org` → misspelled word underlined               |
| 4.25 | `helpful`              | `C-h f` shows rich docs                 | `C-h f find-file RET` → rich help buffer               |
| 4.26 | Smooth scrolling       | Pixel-precision scroll                  | Mouse wheel → smooth scroll                            |
| 4.27 | Tree-sitter            | `python-ts-mode` active                 | Open `.py` → `C-h v major-mode RET` → `python-ts-mode` |
| 4.28 | `electric-pair`        | Auto-pairing                            | Type `(` → `)` auto-inserted                           |
| 4.29 | `show-paren`           | Matching paren highlighted              | Put cursor on `)` → matching `(` highlighted           |
| 4.30 | Folding                | `za` toggles fold                       | Open code → `za` → fold/unfold                         |

---

### Phase 5: Completion Framework

| #    | Test                    | Expected                     | How                                          |
| ---- | ----------------------- | ---------------------------- | -------------------------------------------- |
| 5.1  | `vertico`               | Vertical completion dropdown | `C-x C-f` → dropdown appears                 |
| 5.2  | `orderless`             | Fuzzy matching               | `C-x C-f` → type `in.el` → matches `init.el` |
| 5.3  | `marginalia`            | Annotations in minibuffer    | `M-x` → descriptions next to commands        |
| 5.4  | `nerd-icons-completion` | Icons in completion          | `C-x C-f` → file icons in dropdown           |
| 5.5  | `consult-buffer`        | `SPC b b` → buffer switcher  | `SPC b b` → buffer list                      |
| 5.6  | `consult-line`          | Live grep in buffer          | `M-s l` → type → live matches                |
| 5.7  | `consult-ripgrep`       | Project-wide search          | `SPC p s` → type → async results             |
| 5.8  | `embark`                | `C-;` → context actions      | `C-;` → action menu                          |
| 5.9  | `corfu`                 | In-buffer completion popup   | Type `find-` in `.el` → popup                |
| 5.10 | `corfu-popupinfo`       | `M-h` shows docs             | In corfu popup → `M-h` → docs                |
| 5.11 | `cape`                  | `C-c p` prefix map           | `C-c p` → cape commands                      |
| 5.12 | `vertico-quick`         | `M-q` → Avy-style select     | In vertico → `M-q` → shortcuts               |
| 5.13 | `vertico-repeat`        | Repeat last completion       | `M-x vertico-repeat RET`                     |

---

### Phase 6: Org Mode & Second Brain

| #    | Test                             | Expected                                | How                                           |
| ---- | -------------------------------- | --------------------------------------- | --------------------------------------------- |
| 6.1  | **Org file opens without error** | No `wrong-type-argument`                | Open any `.org` file                          |
| 6.2  | `org-modern` badges              | TODO/DONE rendered as pills             | Open `todo.org` → visual check                |
| 6.3  | `org-modern` stars               | `◉ ○ ✸` replace `*`                     | Open `.org` → heading stars replaced          |
| 6.4  | `org-modern` checkboxes          | `☑ ◧ ☐` render                          | `- [ ]` → `☐`, `- [X]` → `☑`                  |
| 6.5  | `org-modern` blocks              | `» «` replace `#+begin_src`             | Open config.org → block glyphs                |
| 6.6  | `org-hide-emphasis-markers`      | `*bold*` shows **bold** without markers | Open `.org` → visual check                    |
| 6.7  | `org-pretty-entities`            | `\alpha` → α                            | Type `\alpha` → rendered                      |
| 6.8  | `org-src-fontify-natively`       | Code in src blocks highlighted          | Open config.org → elisp blocks colored        |
| 6.9  | `org-return-follows-link`        | `RET` on link opens it                  | Put cursor on link → `RET`                    |
| 6.10 | `evil-org`                       | `RET` context-aware                     | On TODO heading → `RET` toggles state         |
| 6.11 | `org-agenda`                     | `SPC o a a` → agenda                    | `SPC o a a` → agenda buffer                   |
| 6.12 | **`org-super-agenda` daily**     | **Groups render without crash**         | `SPC o a d` → grouped agenda                  |
| 6.13 | `org-super-agenda` fold          | `TAB` on group header folds             | Click group header → `TAB` → fold             |
| 6.14 | `org-capture`                    | `SPC X` → smart dispatcher              | `SPC X` → capture menu                        |
| 6.15 | `org-capture` inbox              | `SPC X i` → quick inbox                 | `SPC X i` → capture buffer                    |
| 6.16 | `org-habit`                      | Habit graph in agenda                   | Open habits.org → add habit → check agenda    |
| 6.17 | `denote`                         | `SPC n n` → new note                    | `SPC n n` → title prompt → note created       |
| 6.18 | `denote-silo`                    | `SPC n S s` → silo dispatch             | `SPC n S s` → silo picker                     |
| 6.19 | `denote-solo`                    | `SPC n S l` → switch solo               | `SPC n S l` → solo picker                     |
| 6.20 | `denote-sequence`                | `SPC n q n` → new sequence              | `SPC n q n` → sequence note                   |
| 6.21 | `denote-journal`                 | `SPC n j` → journal entry               | `SPC n j` → journal note                      |
| 6.22 | `denote-menu`                    | `SPC n m m` → tabulated list            | `SPC n m m` → note list                       |
| 6.23 | `denote-explore`                 | `SPC n e c` → count notes               | `SPC n e c` → count in echo                   |
| 6.24 | `denote-wordcloud`               | `SPC n e W` → wordcloud                 | `SPC n e W` → wordcloud buffer                |
| 6.25 | `consult-denote`                 | `SPC n f` → find note                   | `SPC n f` → consult find                      |
| 6.26 | `org-transclusion`               | `SPC n T` → transclude                  | Create `[[denote:ID]]` link → `SPC n T`       |
| 6.27 | `org-tempo`                      | `<el TAB` → src block                   | Type `<el` → `TAB` → `#+begin_src emacs-lisp` |
| 6.28 | Transient template               | `<` at BOL → template menu              | `<` at beginning of line → transient          |
| 6.29 | Babel lazy-load                  | `C-c C-c` on src block executes         | Open config.org → `C-c C-c` on elisp block    |
| 6.30 | `org-auto-tangle`                | Save config.org → init.el updated       | Edit config.org → save → check init.el        |
| 6.31 | Heading zoom                     | config.org headings scaled              | Open config.org → headings larger             |
| 6.32 | `org-ellipsis`                   | `↴` shown for folded                    | Fold heading → ellipsis visible               |

---

### Phase 7: Workflow Management

| #    | Test                   | Expected                    | How                                |
| ---- | ---------------------- | --------------------------- | ---------------------------------- |
| 7.1  | `dired`                | `SPC d d` → dired           | `SPC d d` → dired buffer           |
| 7.2  | `dirvish`              | Dirvish UI in dired         | `SPC d f` → dirvish layout         |
| 7.3  | `dirvish` sidebar      | `SPC d s` → 30% sidebar     | `SPC d s` → sidebar                |
| 7.4  | `dirvish` preview      | File preview on navigation  | Navigate files → preview pane      |
| 7.5  | `dirvish` dashboard    | `?` → transient             | In dirvish → `?` → dashboard       |
| 7.6  | `treemacs`             | Sidebar file tree           | `M-x treemacs RET` → tree          |
| 7.7  | `ibuffer`              | `SPC b i` → ibuffer         | `SPC b i` → grouped buffers        |
| 7.8  | `project`              | `SPC p p` → switch project  | `SPC p p` → project picker         |
| 7.9  | `project-find-file`    | `SPC p f` → find in project | `SPC p f` → file picker            |
| 7.10 | `tab-bar` / `bufferlo` | `SPC TAB TAB` → workspace   | `SPC TAB TAB` → workspace switcher |

---

### Phase 8: Version Control

| #   | Test              | Expected                         | How                                    |
| --- | ----------------- | -------------------------------- | -------------------------------------- |
| 8.1 | `magit-status`    | `SPC g s` (or `SPC p g`) → magit | Open git repo → `M-x magit-status RET` |
| 8.2 | `diff-hl`         | Fringe indicators                | Edit file → green/blue fringe bars     |
| 8.3 | `git-timemachine` | Step through history             | `M-x git-timemachine RET`              |

---

### Phase 9: Development Tools

| #    | Test                | Expected                        | How                                      |
| ---- | ------------------- | ------------------------------- | ---------------------------------------- |
| 9.1  | `eglot`             | LSP connects                    | Open `.py` → `M-x eglot RET` → connected |
| 9.2  | `eglot` completion  | Corfu popup with LSP candidates | Type `os.pa` → `path` in popup           |
| 9.3  | `eglot` diagnostics | Flymake underlines              | Introduce syntax error → red underline   |
| 9.4  | `flyover`           | Inline diagnostic overlay       | Hover over error → overlay message       |
| 9.5  | `eldoc`             | Signature in echo area          | Type `find-file` → signature shown       |
| 9.6  | `eldoc-childframe`  | Childframe popup (GUI only)     | Hover over symbol → childframe           |
| 9.7  | `xref`              | `M-.` → jump to definition      | `M-.` on symbol → jump                   |
| 9.8  | `apheleia`          | Format on save                  | Edit `.py` → save → formatted            |
| 9.9  | `consult-eglot`     | Workspace symbols               | `M-x consult-eglot-symbols RET`          |
| 9.10 | `peek`              | Inline definition panel         | `M-x peek-xref-definition RET`           |

---

### Phase 10: Ghostel Terminal

| #     | Test               | Expected                     | How                                                  |
| ----- | ------------------ | ---------------------------- | ---------------------------------------------------- |
| 10.1  | `ghostel` opens    | `M-x ghostel RET` → terminal | `M-x ghostel RET`                                    |
| 10.2  | Shell integration  | Prompt tracking              | `cd /tmp` → `C-c C-n`/`C-c C-p` navigate prompts     |
| 10.3  | `ghostel-project`  | Project terminal             | `SPC p e` (or configured) → terminal in project root |
| 10.4  | `evil-ghostel`     | Evil states in terminal      | In ghostel → `ESC` → normal state                    |
| 10.5  | `ghostel-send-key` | `M-p`/`M-n` history          | In ghostel → `M-p` → previous history                |
| 10.6  | `ghostel-compile`  | Compile in ghostel           | `M-x ghostel-compile RET` → `make`                   |
| 10.7  | `ghostel-eshell`   | Visual commands in ghostel   | In eshell → `htop` → ghostel buffer                  |
| 10.8  | Semi-char mode     | `C-c C-j` → semi-char        | In ghostel → `C-c C-j`                               |
| 10.9  | Copy mode          | `C-c C-t` → copy mode        | In ghostel → `C-c C-t` → select → `y`                |
| 10.10 | TRAMP terminal     | Remote shell                 | `M-x ghostel RET` → `C-x C-f /ssh:host: RET`         |

---

### Phase 11: Eshell

| #    | Test                   | Expected                      | How                                     |
| ---- | ---------------------- | ----------------------------- | --------------------------------------- |
| 11.1 | `eshell` opens         | `SPC p e` or `M-x eshell RET` | `M-x eshell RET`                        |
| 11.2 | Prompt with git branch | `(main)` shown in prompt      | In git repo → eshell → branch in prompt |
| 11.3 | `eshell/clear`         | Clears scrollback             | `clear RET` → scrollback cleared        |
| 11.4 | Visual commands        | `htop` → ghostel buffer       | `htop RET` → ghostel                    |
| 11.5 | `eshell-up`            | `bd` → parent dir             | `bd RET` → up one dir                   |
| 11.6 | `eshell-z`             | `z proj` → jump to frequent   | `z proj RET` → jump                     |
| 11.7 | Syntax highlighting    | Commands colored              | Type `ls` → colored                     |
| 11.8 | `eshell-did-you-mean`  | Typo suggestion               | `gti status RET` → "did you mean git?"  |

---

### Phase 12: Regression — The Two Confirmed Bugs

| #    | Test                          | Expected (BEFORE fix)                        | Expected (AFTER fix)   |
| ---- | ----------------------------- | -------------------------------------------- | ---------------------- |
| 12.1 | Open any `.org` file          | `wrong-type-argument listp native` backtrace | File opens cleanly     |
| 12.2 | `SPC o a d` (Daily Dashboard) | `wrong-type-argument listp :deadline` crash  | Grouped agenda renders |
| 12.3 | `SPC o a a` (Default Agenda)  | Works (global defaults use correct syntax)   | Works                  |
| 12.4 | `SPC o a w` (Weekly Review)   | Works (no `:take` in weekly groups)          | Works                  |
| 12.5 | `SPC o a e` (Effort-Based)    | Works (no `:take` in effort groups)          | Works                  |

---

### Summary of Required Fixes

| Priority | File Location                        | Current                                     | Fix                                            |
| -------- | ------------------------------------ | ------------------------------------------- | ---------------------------------------------- |
| 🔴 P0    | `Core Configuration` `:custom`       | `(org-highlight-latex-and-related 'native)` | `(org-highlight-latex-and-related '(native))`  |
| 🔴 P0    | `ar/org-sa-daily-groups` Overdue     | `:take (10 :deadline past :scheduled past)` | `:take (10 (:deadline past :scheduled past))`  |
| 🔴 P0    | `ar/org-sa-daily-groups` Due Soon    | `:take (7 :deadline (before "+7d"))`        | `:take (7 (:deadline (before "+7d")))`         |
| 🔴 P0    | `ar/org-sa-daily-groups` Other Tasks | `:take (15 :anything t)`                    | `:take (15 (:anything t))`                     |
| 🟡 P2    | `Denote Merge` `:ensure`             | `:ensure(:host ...)`                        | `:ensure (:host ...)`                          |
| 🟡 P2    | `Dirvish` recipe                     | No `:ref` pin                               | Add `:ref "<commit-hash>"` for reproducibility |

I am locked in the READ-ONLY planning state. Awaiting explicit `GREEN LIGHT` to execute the rewrite.
