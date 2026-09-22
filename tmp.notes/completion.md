```org
* TODO Completion Framework
** TODO Orderless
=orderless= provides a flexible, space-separated completion style where each component can match anywhere in the candidate, in any order. This configuration implements a highly optimized, Doom Emacs-inspired dispatcher system while ensuring strict compatibility with Emacs' native file and TRAMP completion engines.

*Architectural Decisions & Edge Cases Handled*

1. *The TRAMP & File Completion Trap:*
   The official =orderless= README suggests overriding the =file= category with only =partial-completion=. However, doing so completely strips =orderless= and =basic= from file completions. This breaks fuzzy file matching and, more critically, breaks TRAMP (SSH) hostname resolution, which strictly requires the =basic= style to be tried /first/. We explicitly define =(file (styles basic partial-completion orderless))= to guarantee that TRAMP works, wildcards work, and fuzzy matching works simultaneously.

2. *Strict Global Matching Styles:*
   We explicitly set =orderless-matching-styles= to =(orderless-regexp orderless-literal)=. We intentionally omit =orderless-flex= and =orderless-initialism= from the global defaults. Enabling them globally makes the search too broad, causing performance stuttering in large candidate lists (like =consult-ripgrep=) and returning excessive noise. You must explicitly opt-in to fuzzy matching using the =~= and =%= prefixes defined in our dispatchers.

3. *Explicit Affix Dictionary & Annotation Matching:*
   Standard =orderless= does not natively map Vim-like affixes without configuration. We explicitly define =orderless-affix-dispatch-alist= to create a predictable, documented dictionary:
   - =!= :: Exclude candidates containing this term (=orderless-without-literal=).
   - == = :: Match this term exactly, no regex (=orderless-literal=).
   - =%= :: Match initialisms, e.g., =ffb= matches =find-file-buffer= (=orderless-initialism=).
   - =~= :: Fuzzy match, allowing typos (=orderless-flex=).
   - =,= :: Must start with this literal string (=orderless-literal-prefix=).
   - =&= :: Search only the Marginalia annotation (e.g., typing =kill &command= filters out variables and buffers). Includes a failsafe to =orderless-literal= if =orderless-annotation= is unavailable.

4. *The Consult "Tofu" Disambiguation Problem:*
   =consult= appends invisible Unicode characters ("tofu") to buffer names to guarantee uniqueness in the minibuffer. Because of this, standard regex end-of-string anchors (like =$=) fail because the string actually ends with =\u{100000}=.
   - *The Condition (O(1) Parsing):* We use native, O(1) string functions (=string-suffix-p=, =string-prefix-p=) to check if the user typed a dispatcher like =$= or =.ext=. This completely eliminates regex engine overhead during the parsing phase.
   - *The Payload (Regex Injection):* We are mathematically forced to use =orderless-regexp= for the output payload to dynamically inject Consult's regex character class (=consult--tofu-regexp=). We also carefully escape literal dots (=\\.=) so they don't act as regex wildcards, and use the correct string escape (="*\\'"=) to generate the regex end-of-string anchor.

#+begin_src emacs-lisp
(use-package orderless
  :custom
  ;; Set the global completion styles. `basic` is included as a fallback
  ;; to ensure commands relying on dynamic completion tables work correctly.
  (completion-styles '(orderless basic))

  ;; CRITICAL FIX: Explicitly include `basic`, `partial-completion`, and `orderless` for files.
  ;; - `basic` MUST be first for TRAMP (SSH) hostname resolution to work.
  ;; - `partial-completion` allows wildcards and partial paths (e.g., `~/.c/e/p.el`).
  ;; - `orderless` ensures fuzzy matching still works when finding files.
  (completion-category-overrides '((file (styles basic partial-completion orderless))))

  ;; Disable default category overrides to prevent other packages from
  ;; silently injecting conflicting styles.
  (completion-category-defaults nil)

  ;; Emacs 31+: partial-completion behaves like substring.
  (completion-pcm-leading-wildcard t)

  ;; Explicitly declare strict global matching styles.
  ;; We intentionally omit `orderless-flex` and `orderless-initialism` here to prevent performance stuttering and excessive noise in large candidate lists.
  (orderless-matching-styles '(orderless-regexp orderless-literal))

  :config
  ;; ==========================================
  ;; EXPLICIT AFFIX DICTIONARY
  ;; ==========================================
  ;; We explicitly define the dictionary so your Vim-like affixes are
  ;; predictable, documented, and mathematically guaranteed to exist.
  (setq orderless-affix-dispatch-alist
        `((?! . orderless-without-literal)  ; Exclude candidates containing this term
          (?= . orderless-literal)          ; Match this term exactly, no regex
          (?% . orderless-initialism)       ; Match `ffb` to `find-file-buffer`
          (?~ . orderless-flex)             ; Fuzzy match, allowing typos
          (?, . orderless-literal-prefix)   ; Must start with this literal string
          ;; Annotation matching (Emacs 29+). Searches Marginalia metadata.
          ;; Failsafe to `orderless-literal` if on an ancient Orderless version.
          (?& . ,(if (fboundp 'orderless-annotation)
                     'orderless-annotation
                   'orderless-literal))))

  ;; ==========================================
  ;; THE CONSULT "TOFU" DISPATCHER
  ;; ==========================================
  ;; Consult appends invisible Unicode characters ("tofu") to buffer names to guarantee uniqueness. Standard regex `$` fails because the string actually ends with `\u{100000}`. This dispatcher dynamically injects Consult's regex character class into the payload.
  (defun ar/orderless-disambiguation-dispatch (word _index _total)
    "Handle disambiguation suffixes for Consult and file extensions."
    ;; The Payload: We are forced to use regex here because Consult's tofu characters are defined as a regex character class.
    ;; FIX: Corrected string escape from "*\'" to "*\\'" to properly generate the regex end-of-string anchor `\'` instead of a literal apostrophe.
    (let ((tofu-re (if (boundp 'consult--tofu-regexp)
                       (concat consult--tofu-regexp "*\\'")
                     "\\'")))
      (cond
       ;; Ensure $ works with Consult commands (exact end-of-string match)
       ;; Uses O(1) `string-suffix-p` instead of regex for the condition.
       ((string-suffix-p "$" word)
        `(orderless-regexp . ,(concat (substring word 0 -1) tofu-re)))

       ;; File extensions (e.g., `.org`)
       ;; Uses native O(1) `string-prefix-p` instead of regex for the condition.
       ((and (or minibuffer-completing-file-name
                 (derived-mode-p 'eshell-mode))
             (string-prefix-p "." word))
        ;; Because we are forced to return `orderless-regexp` to handle the tofu characters, the literal dot `.` becomes a regex wildcard.
        ;; We MUST escape it as `\\.` so it only matches a literal dot.
        `(orderless-regexp . ,(concat "\\." (substring word 1) tofu-re))))))

  ;; ==========================================
  ;; DISPATCHER REGISTRATION
  ;; ==========================================
  ;; We chain the built-in `orderless-affix-dispatch` (which handles the
  ;; dictionary and backslash escaping natively) with our custom Tofu dispatcher.
  ;; Component separator remains the default Spacebar (" +"), mimicking web search engines and preserving muscle memory.
  (setq orderless-style-dispatchers
        '(orderless-affix-dispatch
          ar/orderless-disambiguation-dispatch)))
#+end_src

** TODO Vertico
=VERTical Interactively COmpletion= serves as the minimalist, high-performance UI for the Emacs minibuffer. Rather than relying on a static, one-size-fits-all dropdown, this configuration transforms =vertico= into a deeply integrated, context-aware navigation engine by leveraging its bundled extensions.

1. *The Context-Aware UI (=vertico-multiform=):*
Instead of forcing every command into a 10-line vertical dropdown, =vertico-multiform= acts as a traffic controller to dynamically adapt the UI based on the executed command:
- =vertico-buffer=: Used for massive document structures (=consult-imenu=, =consult-outline=, =consult-line-multi=). It temporarily hijacks the main editing window to provide a full-screen overview of the codebase.
- =vertico-grid=: Used for =consult-yasnippet=. Snippet names are short and uniform; a multi-column grid eliminates unnecessary vertical scrolling.
- =vertico-unobtrusive=: Can be used for =execute-extended-command= (=M-x=) to completely hide the candidate list and render only the top match inline next to the prompt, reclaiming screen space. (Currently disabled in favor of the standard 10-line dropdown).

2. *The Evil/Vim Minibuffer Trap (Crucial):*
When =vertico-buffer= takes over the main window, keyboard focus remains in the minibuffer to allow continuous filter query typing. Forcing the minibuffer into =evil-normal-state= to enable =j=/=k= scrolling is a catastrophic error; it breaks the type-to-filter paradigm and forces the user to press =i= before typing any search character.
*The Fix:* The minibuffer is intentionally left in =insert= state, relying strictly on native arrow keys (=<up>= and =<down>=) for candidate navigation. By avoiding =hjkl= bindings entirely in the =vertico-map=, flawless scrolling muscle memory is preserved without ever interrupting the ability to type or risking conflicts with search queries.

3. *Avy-Style Jumping (=vertico-quick=):*
For workflows heavily reliant on =avy= for buffer navigation, the muscle memory is wired for "look at the screen, type 1 or 2 characters, jump." The =vertico-quick= extension implements this exact algorithm natively inside the minibuffer, independent of the external =avy= package. Pressing =M-q= overlays jump-characters next to every candidate, allowing instant selection of distant items in long lists without repetitive keystrokes.

4. *The Safety Net (=vertico-repeat=):*
When popup managers or custom keybindings intercept =C-g=, it is easy to accidentally abort complex queries (e.g., =consult-ripgrep= or =find-file=). The =vertico-repeat= extension records the exact state of the last completion session, allowing instant resurrection of cancelled queries.

5. *Load-Order Guarantee:*
Standard Emacs configurations often place extension requires in the =:config= block while binding their functions in =:bind=. Because =:bind= evaluates before =:config= during startup, this causes fatal =void-function= errors. All =require= statements for Vertico extensions are strictly placed in the =:init= block to guarantee functions are loaded into memory before keybindings are wired.

6. *Popper & TRAMP Non-Interference:*
- =vertico-buffer= utilizes the main window rather than a dedicated popup buffer, ensuring popup management regex filters completely ignore it (resulting in zero UI flickering).
- =completion-category-overrides= remains unaltered here, as the =orderless= configuration correctly handles TRAMP and file paths.

7. *Group Navigation:*
To prevent repetitive keystrokes when skipping over long lists of candidates, =C-<down>= and =C-<up>= are mapped to =vertico-next-group= and =vertico-previous-group=. This allows instant teleportation between candidate categories (e.g., jumping from "Open Buffers" directly to "Recent Files" in =consult-buffer=).

8. *Visual Transforms:*
A robust =cl-defmethod= approach is used to dynamically colorize candidates based on their category. Directories are tinted with a distinct face so they do not blend in with regular files, and enabled minor/major modes are highlighted in =font-lock-constant-face= when using =M-x=, allowing for instant visual scanning.

9. *Embark Grid Synergy:*
To replace the legacy =which-key= hack for Embark actions, =vertico-multiform= is instructed to render the =embark-keybinding= category as a multi-column grid. This provides a searchable action menu that integrates seamlessly with Orderless filtering.

#+begin_src emacs-lisp
(use-package vertico
  :custom
  ;; Reserve exactly 10 lines of vertical space for the minibuffer dropdown. Setting this to a fixed number prevents the UI from visually 'jumping' up and down as the candidate list shrinks and grows while typing.
  (vertico-count 10)

  ;; Disable dynamic resizing. The minibuffer will always occupy 'vertico-count' lines. Note: This variable is mathematically ignored when 'vertico-unobtrusive' is active (e.g., during M-x), because unobtrusive mode bypasses the vertical rendering engine entirely.
  (vertico-resize nil)

  ;; Allow cycling from the bottom of the list back to the top.
  (vertico-cycle t)

  :init
  ;; LOAD ORDER GUARANTEE
  ;; We MUST require these extensions here in ':init' (before ':bind' and ':hook' evaluate). If we defer them to ':config', Emacs will throw 'void-function' errors on startup when it tries to map the keys.
  (require 'vertico-directory)
  (require 'vertico-quick)
  (require 'vertico-repeat)
  (require 'vertico-multiform)
  (require 'vertico-buffer)
  (require 'vertico-grid)
  (require 'vertico-unobtrusive)

  ;; Enable the core Vertico engine
  (vertico-mode)

  :bind (:map vertico-map
              ;; Ido-like Directory Navigation
              ;; Allows seamless filesystem traversal. 'RET' enters the directory instead of selecting it as a file; 'DEL' goes up a directory.
              ("RET" . vertico-directory-enter)
              ("DEL" . vertico-directory-delete-char)
              ("M-DEL" . vertico-directory-delete-word)

              ;; ----------------------------------------
              ;; Group Navigation (Proposal B)
              ;; ----------------------------------------
              ;; Jump between candidate groups (e.g., from "Buffers" to "Recent Files")
              ;; using arrow keys instead of hjkl.
              ("C-<down>" . vertico-next-group)
              ("C-<up>" . vertico-previous-group)

              ;; ----------------------------------------
              ;; Vertico-Quick (Avy-style Minibuffer Jumps)
              ;; ----------------------------------------
              ;; Overlays 1-or-2 character tags next to candidates.
              ;; M-q: Jump to candidate and select it.
              ;; M-Q: Jump to candidate, select it, and exit minibuffer.
              ;; M-i: Jump to candidate and insert it (without exiting).
              ("M-q" . vertico-quick-jump)
              ("M-Q" . vertico-quick-exit)
              ("M-i" . vertico-quick-insert))

  :hook (;; ----------------------------------------
         ;; Directory Path Shadowing
         ;; ----------------------------------------
         ;; When typing a path like '/ssh:server:/etc/', Emacs shadows the local
         ;; path. This hook cleans up the visual display of the shadowed path.
         (rfn-eshadow-update-overlay . vertico-directory-tidy)

         ;; ----------------------------------------
         ;; Session Recovery Safety Net
         ;; ----------------------------------------
         ;; Saves the current minibuffer state on every setup, allowing
         ;; 'vertico-repeat' to resurrect accidentally cancelled queries.
         (minibuffer-setup . vertico-repeat-save))

  :config
  ;; ==========================================
  ;; 1. CORE MINIBUFFER SAFEGUARDS
  ;; ==========================================
  ;; Prompt Intangibility: Prevents the cursor from wandering behind the
  ;; read-only prompt text (e.g., 'Find file: ') when using C-a or backward
  ;; motions. Corrupting the prompt text breaks the completion engine.
  (setq minibuffer-prompt-properties
        '(read-only t cursor-intangible t face minibuffer-prompt))
  (add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)

  ;; Recursive Minibuffers: Allows opening a minibuffer *inside* a minibuffer.
  ;; E.g., pressing 'M-x' or evaluating Elisp while in the middle of a
  ;; 'consult-ripgrep' search, without cancelling the search.
  (setq enable-recursive-minibuffers t)

  ;; Depth Indicator: Changes the prompt to '[1] M-x' or '[2] Find file:'
  ;; when inside nested recursive minibuffers so you don't get lost.
  (minibuffer-depth-indicate-mode 1)

  ;; ==========================================
  ;; 2. ENABLE GLOBAL EXTENSION MODES
  ;; ==========================================
  ;; Note: 'vertico-grid', 'vertico-buffer', 'vertico-quick', and
  ;; 'vertico-unobtrusive' do NOT have global modes (or are triggered
  ;; dynamically). Only 'vertico-multiform' has a global mode.
  (vertico-multiform-mode 1)

  ;; ==========================================
  ;; 3. MULTIFORM RULES (Context-Aware UI)
  ;; ==========================================
  ;; Dictates which display mode to temporarily activate per command.
  ;; (You can manually toggle these on the fly in the minibuffer using
  ;; M-B for buffer, M-G for grid, M-U for unobtrusive, etc.)
  (setq vertico-multiform-commands
        '(;; Code Navigation: Take over main window (Helm/Ivy style)
          (consult-imenu buffer)
          (consult-outline buffer)
          (consult-line-multi buffer)

          ;; Snippets: Multi-column grid (optimal for short, uniform names)
          (consult-yasnippet grid)

          ;; M-x: Unobtrusive (hide list, show top match inline to save space).
          ;; COMMENT OUT the next line if you prefer the standard 10-line dropdown for M-x.
          ;; (execute-extended-command unobtrusive)
          ))

  ;; File category: Keep default vertical (best for long paths + Marginalia).
  ;; We do not override the 'file' category here; Orderless handles it.
  ;; (setq vertico-multiform-categories '((file vertical)))

  ;; ==========================================
  ;; 4. FUTURE-PROOFING FOR LSP-MODE
  ;; ==========================================
  ;; When we configure consult-lsp or xref-find-references later, we will
  ;; add rules here to dictate whether LSP diagnostics open in a grid, buffer, etc.
  ;; (add-to-list 'vertico-multiform-commands '(consult-lsp-diagnostics buffer))

  ;; ==========================================
  ;; 5. VISUAL TRANSFORMS (Proposal C)
  ;; ==========================================
  ;; Dynamically apply text properties to candidates based on their category.
  (defvar +vertico-transform-functions nil)

  (cl-defmethod vertico--format-candidate :around
    (cand prefix suffix index start &context ((not +vertico-transform-functions) null))
    (dolist (fun (ensure-list +vertico-transform-functions))
      (setq cand (funcall fun cand)))
    (cl-call-next-method cand prefix suffix index start))

  (defun +vertico-highlight-directory-fn (file)
    "If FILE ends with a slash, highlight it as a directory."
    (when (string-suffix-p "/" file)
      ;; We use `dired-directory` to guarantee zero `void-face` errors,
      ;; as `dired-directory` is built into Emacs.
      (add-face-text-property 0 (length file) 'dired-directory 'append file))
    file)

  (defun +vertico-highlight-enabled-mode-fn (cmd)
    "If MODE is enabled, highlight it as font-lock-constant-face."
    (let ((sym (intern cmd)))
      (with-current-buffer (nth 1 (buffer-list))
        (if (or (eq sym major-mode)
                (and (memq sym minor-mode-list)
                     (boundp sym)
                     (symbol-value sym)))
            (add-face-text-property 0 (length cmd) 'font-lock-constant-face 'append cmd)))
      cmd))

  ;; Apply directory highlighting to the `file` category.
  (add-to-list 'vertico-multiform-categories
               '(file (+vertico-transform-functions . +vertico-highlight-directory-fn)))

  ;; Apply mode highlighting to `M-x` (execute-extended-command).
  (add-to-list 'vertico-multiform-commands
               '(execute-extended-command (+vertico-transform-functions . +vertico-highlight-enabled-mode-fn)))

  ;; ==========================================
  ;; 6. EMBARK GRID SYNERGY
  ;; ==========================================
  ;; Render Embark's action menu as a searchable, multi-column grid.
  ;; This completely replaces the fragile, legacy which-key indicator hack.
  (add-to-list 'vertico-multiform-categories '(embark-keybinding grid))
  )
#+end_src

** TODO Marginalia
=marginalia= enriches Emacs' minibuffer completions with rich, contextual metadata (annotations). When paired with =vertico= and =consult=, it transforms a simple list of strings into a deeply informative dashboard, showing file sizes, modification dates, command keybindings, and variable types directly in the completion UI.

1. *Absolute Timestamps for Developer Precision:*
   By default, Marginalia uses relative time for recent files (e.g., '2 hours ago', '3 days ago'). We set 'marginalia-max-relative-age' to '0'. This forces Marginalia to always display exact, absolute timestamps (e.g., '2026-07-04 14:30'). Relative timestamps are ambiguous; absolute timestamps provide the mathematical precision required when scanning recent files or buffer lists to determine exactly when a file was last touched.

2. *Right-Edge Alignment:*
   We set 'marginalia-align' to 'right'. This keeps the primary candidate names (file names, command names) strictly left-aligned for fast vertical scanning, while pushing the secondary metadata (file sizes, dates, docstrings) to the far right edge of the minibuffer. This creates a clean, tabular-like UI that prevents long annotations from visually colliding with the candidate names.

#+begin_src emacs-lisp
(use-package marginalia
  ;; Enable Marginalia globally on startup.
  :hook (after-init . marginalia-mode)
  :config
  ;; Force absolute timestamps (e.g., '2026-07-04') instead of relative
  ;; timestamps (e.g., '2 days ago'). Setting this to 0 means any file
  ;; older than 0 seconds uses absolute time, providing mathematical
  ;; precision when scanning recent files or buffers.
  (setq marginalia-max-relative-age 0
        ;; Align annotations to the right edge of the minibuffer.
        ;; This keeps candidate names left-aligned for fast scanning,
        ;; while pushing metadata (sizes, dates, types) to the periphery,
        ;; creating a clean, tabular-like UI that prevents visual collisions.
        marginalia-align 'right))
#+end_src

** TODO Nerd Icons Completion
Adds Nerd Font icons to minibuffer completion candidates. We hook it directly into =marginalia= so the icons render cleanly alongside the rich metadata annotations.
#+begin_src emacs-lisp
(use-package nerd-icons-completion
  :after marginalia
  :config
  (nerd-icons-completion-mode)
  (add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup))
#+end_src

** TODO Consult
=consult= provides search and navigation commands built on Emacs' native =completing-read= API. It replaces standard Emacs commands with asynchronous, interactive, and preview-enabled alternatives. This configuration strictly integrates =consult= with =persp-mode= for workspace isolation and =projectile= for project root detection, while optimizing the preview engine for performance and visual clarity.

1. *Strict Projectile Reliance:*
   By default, =consult= falls back to Emacs' native =project.el= to detect project roots. We explicitly override =consult-project-function= to rely solely on =projectile-project-root=. This ensures that =consult-ripgrep= and =consult-find= strictly respect Projectile's known projects and caching mechanisms, preventing accidental searches in random =.git= directories outside of your workflow.

2. *Vim-Style Line Search:*
   We set =consult-line-start-from-top= to =t=. By default, =consult-line= only shows matches below the current cursor position. Setting this to =t= forces it to search the entire buffer from top to bottom (mimicking Vim's =/= search behavior), while still intelligently highlighting the match closest to your cursor as the default selection.

3. *Hidden Files & Git Exclusion:*
   We configure =consult-ripgrep-args= and =consult-fd-args= to include the =--hidden= flag, allowing you to search configuration files (like =.env=, =.github/=, =.gitignore=). Crucially, we append =--glob '!.git'= (for ripgrep) and =--exclude .git= (for fd) to strictly ignore the massive =.git/objects= directory, preventing your async searches from freezing. We also dynamically link =consult-fd= to the exact =fd= or =fdfind= executable you already detected in your Projectile configuration.

4. *Live Preview Font-Locking:*
   When scrolling through =consult-ripgrep= or =consult-line= candidates, Consult temporarily loads the file to show a live preview. We add =hl-todo-mode= to =consult-preview-allowed-hooks= so your =TODO=, =FIXME=, and =HACK= tags remain beautifully color-coded during the preview. This is mathematically safe because Consult's internal =consult-fontify-max-size= (default 1MB) automatically disables font-lock for massive files, preventing any CPU stuttering.

5. *Persp-Mode Buffer Isolation:*
   We completely replace the default =consult-buffer-sources= list with a custom =consult--source-persp-file-visiting-buffer= source. This guarantees that =consult-buffer= strictly shows file-visiting buffers from your current =persp-mode= workspace, alongside recent files and bookmarks. We include a safe =let= guard to prevent fatal =wrong-type-argument= crashes when querying buffers from the global =nil= ("main") perspective.

#+begin_src emacs-lisp
(use-package consult
  :bind (;; Buffer switching
         ([remap switch-to-buffer] . consult-buffer)
         ([remap switch-to-buffer-other-window] . consult-buffer-other-window)
         ([remap switch-to-buffer-other-frame] . consult-buffer-other-frame)
         ([remap project-switch-to-buffer] . consult-project-buffer)
         ;; Navigation
         ([remap goto-line] . consult-goto-line)
         ([remap imenu] . consult-imenu)
         ([remap yank-pop] . consult-yank-pop)
         ([remap bookmark-jump] . consult-bookmark))
  :hook (completion-list-mode . consult-preview-at-point-mode)
  :init
  ;; Improve register preview with consult
  (setq register-preview-delay 0.5
        register-preview-function #'consult-register-format)
  (advice-add #'register-preview :override #'consult-register-window)
  ;; Use Consult for xref locations with preview
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)
  :config
  ;; ==========================================
  ;; 1. CORE CONSULT TWEAKS & PROPOSALS
  ;; ==========================================
  ;; Vim-style search: Start `consult-line` from the top of the buffer
  ;; instead of the current cursor position. This provides a full document
  ;; overview while still highlighting the match closest to point.
  (setq consult-line-start-from-top t)

  ;; Hidden files & .git exclusion for ripgrep and GNU find.
  ;; We preserve Consult's upstream default flags (like --max-columns and
  ;; --path-separator) to prevent cross-platform parsing crashes, and
  ;; safely append our --hidden and .git exclusion requirements.
  (setq consult-ripgrep-args "rg --null --line-buffered --color=never --max-columns=1000 --path-separator / --smart-case --no-heading --line-number --hidden --glob '!.git'"
        consult-find-args "find . -not -path '*/.git/*'")

  ;; Safely configure consult-fd-args using the executable detected in the
  ;; Projectile config. We omit `--full-path` so candidates render as clean
  ;; relative paths in the minibuffer instead of ugly absolute paths.
  ;; We pass a list instead of a string to bypass shell quoting entirely.
  ;; TODO replace with projectile alternative
  ;; (with-eval-after-load 'projectile
  ;;   (when (boundp 'ar/fd-executable)
  ;;     (setq consult-fd-args (list ar/fd-executable "--color=never" "--hidden" "--exclude" ".git"))))

  ;; Allow `hl-todo-mode` during live previews.
  ;; When scrolling through `consult-ripgrep` or `consult-line` results,
  ;; your TODO/FIXME/HACK tags will remain beautifully color-coded.
  ;; Safeguarded by `consult-fontify-max-size` (default 1MB), so massive
  ;; files won't cause preview stuttering.
  (with-eval-after-load 'hl-todo
    (add-to-list 'consult-preview-allowed-hooks 'hl-todo-mode)
    (add-to-list 'consult-preview-allowed-hooks 'global-hl-todo-mode))

  ;; TODO: Replace with projectile/persp-mode alternatives
  ;; ==========================================
  ;; 2. STRICT PROJECTILE & PERSP-MODE INTEGRATION
  ;; ==========================================
  ;; Strict Projectile reliance: Ensure consult only uses Projectile for
  ;; project root detection, ignoring Emacs' native project.el.
  ;; `ignore-errors` ensures that if Projectile hasn't found a project root,
  ;; it returns `nil` gracefully instead of throwing a `user-error`.
  ;; (autoload 'projectile-project-root "projectile")
  ;; (setq consult-project-function (lambda (_) (ignore-errors (projectile-project-root))))

  ;; (with-eval-after-load 'persp-mode
  ;;   ;; Define custom perspective buffer source for file-visiting buffers only
  ;;   (defvar consult--source-persp-file-visiting-buffer
  ;;     `(:name     "Persp Buffers"
  ;;       :narrow   ?p
  ;;       :category buffer
  ;;       :face     consult-buffer
  ;;       :history  buffer-name-history
  ;;       :state    ,#'consult--buffer-state
  ;;       :default  t
  ;;       :items
  ;;       ,(lambda ()
  ;;          ;; SAFE PERSP CHECK: `persp-buffers` is a struct accessor and will crash if passed 'nil' (the global perspective). We guard against this.
  ;;          (let ((persp (get-current-persp)))
  ;;            (consult--buffer-query
  ;;             :sort 'visibility
  ;;             :predicate (lambda (buf)
  ;;                          (and (buffer-file-name buf)
  ;;                               (if persp
  ;;                                   (memq buf (persp-buffers persp))
  ;;                                 t))) ; Fallback for nil perspective
  ;;             :as #'buffer-name))))
  ;;     "Perspective buffer source showing only file-visiting buffers in current perspective.")

  ;;   ;; Override default sources to use our custom persp source + recent files + bookmarks
  ;;   (setq consult-buffer-sources
  ;;         '(consult--source-persp-file-visiting-buffer
  ;;           consult--source-recent-file
  ;;           consult--source-bookmark
  ;;           consult--source-hidden-buffer)))

  ;; ==========================================
  ;; 3. PREVIEW & NARROWING CONFIGURATION
  ;; ==========================================
  ;; Configure preview behavior for optimal performance
  (consult-customize
   consult-line consult-line-multi consult-imenu consult-imenu-multi
   :preview-key 'any
   consult-theme
   :preview-key '(:debounce 0.2 any)
   consult-buffer consult-recent-file
   :preview-key '(:debounce 0.4 any)
   consult-ripgrep consult-git-grep consult-grep consult-find consult-fd
   :preview-key '(:debounce 0.4 any)
   consult-goto-line consult-mark consult-global-mark
   consult-outline consult-bookmark
   :preview-key '(:debounce 0.4 any))

  ;; Configure narrowing
  (setq consult-narrow-key "<")
  (define-key consult-narrow-map (vconcat consult-narrow-key "?") #'consult-narrow-help))
#+end_src

** TODO Consult Dir
=consult-dir= provides commands to insert directories into the minibuffer prompt, jump to recent directories, and switch contexts seamlessly while in the middle of a =find-file= operation.

Upon strictly reviewing the =consult-dir= source code, it is evident that the package already possesses robust, built-in support for Projectile and external search tools. Writing custom glue code to inject a new source is redundant and mathematically unnecessary. Furthermore, the =consult-projectile= package is officially obsolete, unmaintained, and redundant since Projectile natively uses =completing-read= (which Vertico intercepts).

Instead of writing fragile custom functions or relying on abandoned packages, we configure =consult-dir='s native API:

1. *Projectile Integration:* We set =consult-dir-project-list-function= to =#'consult-dir-projectile-dirs=. This tells the built-in project source to pull directly from your =projectile-known-projects= list, completely bypassing Emacs' native =project.el=.
2. *Fd Integration:* We set =consult-dir-jump-file-command= to =#'consult-fd=. When you use =consult-dir-jump-file= to search inside a chosen directory, it will use your lightning-fast =fd= executable instead of the slower GNU =find=.

#+begin_src emacs-lisp
(use-package consult-dir
  :defer t
  :custom
  ;; TODO Replace with projectile alternative
  ;; NATIVE PROJECTILE INTEGRATION:
  ;; Instruct consult-dir's built-in project source to use Projectile's
  ;; known projects list instead of Emacs' native project.el.
  ;; (consult-dir-project-list-function #'consult-dir-projectile-dirs)

  ;; NATIVE FD INTEGRATION:
  ;; When using 'consult-dir-jump-file' to asynchronously search inside
  ;; a chosen directory, use `consult-fd` instead of `consult-find`
  ;; for exponentially faster file discovery.
  (consult-dir-jump-file-command #'consult-fd))
#+end_src

** TODO Embark
=embark= provides context-dependent actions, comparable to a right-click context menu, for both the minibuffer and regular buffers. It allows the execution of arbitrary commands on the currently selected candidate or the target at point.

1. *Modern Action Discovery (Vertico Grid Synergy):*
   Legacy =which-key= integrations for Embark are fragile, rely on undocumented internal APIs, and cause UI flickering. In a modern completion stack leveraging Vertico, the optimal implementation is to use =vertico-multiform= to render the =embark-keybinding= category as a multi-column grid (configured in the Vertico section). This provides a searchable action menu that can be instantly filtered using =orderless=. To support this, =embark-indicators= is configured to use the =embark-minimal-indicator=, keeping the echo area clean and unobtrusive while relying on the Vertico grid and the =embark-help-key= (=C-h=) for action discovery.

2. *Safe Deferred Autoloading:*
   Core interactive commands (=embark-act=, =embark-bindings=, =embark-export=, =embark-collect=) are explicitly declared in the =:bind= keyword of the =use-package= declaration. This guarantees Emacs registers them for deferred autoloading, preventing =void-function= errors during startup before the package is fully loaded into memory.

3. *Actionable Keybinding Discovery:*
   The built-in =describe-bindings= (=C-h b=) generates a static, read-only help buffer. By remapping this to =embark-bindings=, the help buffer becomes an interactive command launcher. Pressing the =embark-act= key on any binding in the list allows immediate execution or action upon it, transforming passive documentation into an active workflow tool.

4. *Doom-Inspired Keybindings (Vanilla Syntax):*
   Doom Emacs keybindings are replicated using native =use-package= =:bind= declarations, avoiding external keybinding managers like =general.el= or Doom's proprietary =map!= macro for this specific block. =C-;= is mapped to =embark-act= globally and in the minibuffer. =C-c C-;= and =C-c C-l= are mapped to =embark-export= and =embark-collect= in the minibuffer.
   - The Doom-specific =+vertico/embark-export-write= wrapper is omitted, as vanilla =embark-export= natively handles writable exports (via =wgrep=, =wdired=, or Emacs 31's =grep-edit-mode=).
   - The explicit =(require 'consult)= found in Doom's config is omitted, as the dedicated =embark-consult= block below handles the integration cleanly via deferred loading.

#+begin_src emacs-lisp
(use-package embark
  :bind
  ;; Doom Emacs style global bindings implemented via native use-package syntax.
  ;; C-; acts as a right-click context menu at point.
  (("C-;" . embark-act)
   ([remap describe-bindings] . embark-bindings)
   ;; Minibuffer specific bindings for acting, exporting, and collecting.
   :map minibuffer-local-map
   ("C-;" . embark-act)
   ("C-c C-;" . embark-export)
   ("C-c C-l" . embark-collect))

  :init
  ;; Prevent which-key from intercepting C-h after a prefix, allowing
  ;; Embark's completing-read interface to handle prefix help instead.
  (setq which-key-use-C-h-commands nil
        prefix-help-command #'embark-prefix-help-command)

  :config
  ;; ==========================================
  ;; 1. UI & DISPLAY CLEANUP
  ;; ==========================================
  ;; Hide the mode line of the Embark live/completions buffers for a cleaner UI.
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none))))

  ;; ==========================================
  ;; 2. INDICATORS
  ;; ==========================================
  ;; The minimal indicator is used to keep the echo area clean. Action discovery
  ;; is handled natively by the Vertico multiform grid (configured in the
  ;; Vertico section) and the `embark-help-key` (C-h).
  (setq embark-indicators
        '(embark-minimal-indicator
          embark-highlight-indicator
          embark-isearch-highlight-indicator)))
#+end_src

** TODO Embark Consult
=embark-consult= provides deep integration between Embark and Consult, enabling powerful export and preview workflows.

This package provides exporters for several Consult commands. For example, it allows the use of =embark-export= on a =consult-ripgrep= search to generate a native =grep-mode= buffer (which can be edited with =wgrep= or Emacs 31's =grep-edit-mode=). It also hooks =consult-preview-at-point-mode= into =embark-collect-mode=, meaning if a search is snapshot into an Embark Collect buffer, moving the cursor over the results will live-preview the files in the main window.

#+begin_src emacs-lisp
(use-package embark-consult
  :defer t
  :after (embark consult)
  :hook
  ;; Enable live preview of files when navigating an Embark Collect buffer
  ;; that was generated from a Consult search (like consult-ripgrep).
  (embark-collect-mode . consult-preview-at-point-mode))
#+end_src

** TODO Embark Org
=embark-org= is an official extension bundled directly within the =embark= package repository and distributed via GNU ELPA. It teaches Embark how to recognize Org-mode's Abstract Syntax Tree (AST) elements as actionable targets.

Without this extension, Embark treats Org buffers as plain text. By loading =embark-org=, specialized target finders and keymaps are automatically injected into Embark's internal registries.
- *Links:* Pressing =embark-act= on an Org link allows opening it, copying the URL, copying the description, or exporting the link as Markdown.
- *Source Blocks:* Execution of the babel block, tangling, copying contents, or narrowing directly from the minibuffer becomes available.
- *Tables:* A dedicated keymap is provided to move rows/columns, evaluate formulas, or sort the table.
- *Headings:* Refiling, scheduling, archiving, or inserting a link to the heading can be performed without moving the cursor.

Because =embark-org= is bundled with the main =embark= package, it does not require a separate package installation. The =:ensure nil= keyword explicitly prevents the package manager from attempting to download a non-existent standalone package. It simply needs to be required after both parent packages are loaded, which automatically registers its targets and keymaps without any manual glue code.

#+begin_src emacs-lisp
(use-package embark-org
  :ensure nil
  :after (embark org))
#+end_src

** TODO Corfu
=corfu= provides a minimalistic, highly performant in-buffer completion UI using child frames. It serves as the direct in-buffer counterpart to the =vertico= minibuffer UI. This configuration strictly adheres to the architectural boundary that Corfu must never enter the minibuffer, while leveraging upstream extensions to create a cohesive, IDE-grade completion stack.

1. *Protocol Compliance (Explicit Minibuffer Confinement):*
The system protocol strictly mandates that Corfu is confined to buffer editing and MUST NEVER be enabled in the minibuffer, as it fundamentally conflicts with =vertico=. While =global-corfu-mode= implicitly leaves the minibuffer disabled by default, relying on implicit defaults violates defensive programming paradigms. =global-corfu-minibuffer= is explicitly set to =nil= to mathematically guarantee confinement.

2. *Load-Order Physics & Bundled Extensions (=ensure nil=):*
Corfu's extensions (=corfu-quick=, =corfu-popupinfo=, =corfu-history=) reside in separate Elisp files within the same upstream repository. Because the global configuration sets =use-package-always-ensure= to =t=, declaring these extensions without =:ensure nil= forces =package.el= to query ELPA/MELPA for non-existent standalone packages, resulting in fatal startup errors. Furthermore, placing their activation or keybindings directly inside the main =corfu= =use-package= block violates =use-package= load-order physics, causing shadowed autoloads and =void-function= errors. To guarantee mathematical safety and preserve lazy-loading, each extension is declared in its own isolated =use-package= block with =:after corfu= and =:ensure nil=.

3. *Upstream Synergy: Avy-Style Jumping (=corfu-quick=):*
To maintain muscle-memory synergy with =vertico-quick=, the =corfu-quick= extension is loaded. Pressing =M-q= overlays 1-or-2 character jump tags next to every candidate in the popup, allowing instant selection of distant items without repetitive arrow-key navigation. Unlike =corfu-history= or =corfu-popupinfo=, =corfu-quick= consists purely of standalone interactive commands and does not require a minor mode. The bindings are strictly aligned with the capitalization logic of the completion stack: =M-q= performs the lesser action (insert and keep open), while =M-Q= performs the final action (complete and close).

4. *Upstream Synergy: Manual Documentation (=corfu-popupinfo=):*
The =corfu-popupinfo= extension renders LSP and Elisp docstrings in a floating child frame adjacent to the completion menu. However, automatic hover triggers cause UI flickering and spam the LSP server with =completionItem/resolve= network requests. To preserve typing fluidity, the automatic delay is disabled (=corfu-popupinfo-delay nil=), and the popup is strictly bound to a manual toggle (=M-h=).

5. *TAB-and-Go Safety Net & LSP Integration:*
=corfu-preselect= is set to ='prompt=. This ensures that accidentally hitting =RET= inserts exactly what was typed, rather than blindly committing the first LSP candidate. Additionally, the =lsp-capf= category is explicitly overridden to inherit the global =completion-styles=, guaranteeing that =orderless= filters LSP candidates correctly.

6. *Cleanup & Scope Reduction:*
The =read-extended-command-predicate= variable is an Emacs core setting that belongs in the =Basic Completion= block; it is excluded here to prevent conceptual bleeding. Eshell-specific =RET= filters and =persistent-scratch= advices are removed as they fall outside the scope of this specific buffer-editing workflow.

#+begin_src emacs-lisp
(use-package corfu
  :init
  (global-corfu-mode)
  :custom
  ;; PROTOCOL COMPLIANCE: Explicit Minibuffer Confinement
  ;; Corfu is strictly confined to buffer editing. It MUST NEVER be enabled
  ;; in the minibuffer, as it conflicts with Vertico.
  (global-corfu-minibuffer nil)

  (corfu-cycle t)
  (corfu-auto t)
  (corfu-quit-at-boundary 'separator)
  (corfu-quit-no-match 'separator)
  (corfu-count 16)
  (corfu-max-width 120)
  ;; TAB-and-Go safety net: Preselect the prompt so accidental RET inserts
  ;; exactly what was typed, rather than blindly committing the first LSP candidate.
  (corfu-preselect 'prompt)
  (corfu-on-exact-match nil)
  ;; 0.2s delay prevents GC stutter when using Orderless with auto-completion.
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 2)
  (global-corfu-modes '((not erc-mode
                             eshell-mode
                             circe-mode
                             help-mode
                             gud-mode
                             vterm-mode
                             ghostel-mode
                             ghostel-compile-view-mode)
                        t))
  :custom-face
  (corfu-border ((t (:inherit region :background unspecified))))
  :bind (:map corfu-map
         ("TAB"       . corfu-next)
         ("<tab>"     . corfu-next)
         ("S-TAB"     . corfu-previous)
         ("<backtab>" . corfu-previous)
         ("RET"       . corfu-insert)
         ("<escape>"  . corfu-quit))
  :config
  ;; Let Orderless' completion style also apply to `lsp-mode' completions
  (add-to-list 'completion-category-overrides
               `(lsp-capf (styles ,@completion-styles)))

  ;; Always close the popup on leaving insert state or saving
  (add-hook 'evil-insert-state-exit-hook #'corfu-quit)
  (add-hook 'before-save-hook #'corfu-quit))

;; ==========================================
;; CORFU EXTENSIONS (Isolated for Load-Order Safety)
;; ==========================================
;; Bundled extensions require `:ensure nil` because `use-package-always-ensure`
;; is globally enabled. They are isolated in separate blocks to prevent
;; use-package from generating shadowed autoloads that cause void-function errors.

(use-package corfu-history
  :ensure nil
  :after corfu
  :config
  (corfu-history-mode 1)
  (with-eval-after-load 'savehist
    (add-to-list 'savehist-additional-variables 'corfu-history)))

(use-package corfu-popupinfo
  :ensure nil
  :after corfu
  :bind (:map corfu-map
         ;; UPSTREAM SYNERGY: corfu-popupinfo (Manual Trigger)
         ;; M-h toggles the documentation popup for the selected candidate.
         ("M-h" . corfu-popupinfo-toggle))
  :config
  (corfu-popupinfo-mode 1)
  ;; Documentation is ONLY shown on keybinding (M-h), never automatically.
  ;; Setting the delay to nil prevents the automatic hover trigger, avoiding
  ;; UI flicker and LSP network spam.
  (setq corfu-popupinfo-delay nil))

(use-package corfu-quick
  :ensure nil
  :after corfu
  :bind (:map corfu-map
         ;; UPSTREAM SYNERGY: corfu-quick (Avy-style Selection)
         ;; M-q overlays jump-characters next to every candidate.
         ;; Aligned with Vertico's capitalization logic:
         ;; M-q (lesser action): Insert candidate but keep popup open.
         ;; M-Q (final action): Insert candidate and close popup.
         ("M-q" . corfu-quick-insert)
         ("M-Q" . corfu-quick-complete)))
#+end_src

** TODO Basic Completion
This subsection configures the foundational, native Emacs completion variables found in =simple.el= and =minibuffer.el=. While packages like =corfu= and =vertico= provide the visual UI, they ultimately rely on these core Emacs settings to dictate when and how the underlying completion engine is triggered.

1. *The Indent-Then-Complete Paradigm (=tab-always-indent=):*
By setting =tab-always-indent= to ='complete=, the =TAB= key adopts a dual-role behavior. If the code is not properly indented, =TAB= indents it. If the code is already indented, =TAB= triggers =completion-at-point=, summoning the Corfu popup. This creates a seamless, context-aware workflow where indentation and code completion share a single keystroke.

2. *Dictionary Spam Prevention (=text-mode-ispell-word-completion=):*
By default, Emacs binds =M-TAB= (and sometimes =TAB= in text modes) to =ispell-complete-word=, which triggers a synchronous dictionary lookup. In modern workflows utilizing asynchronous Capfs (Completion at Point Functions) like =cape-dict= or LSP servers, this legacy behavior causes UI stuttering and unwanted dictionary popups. Setting this to =nil= disables the legacy Ispell integration.

3. *Context-Aware =M-x= Decluttering (=read-extended-command-predicate=):*
The =M-x= (=execute-extended-command=) menu often contains hundreds of commands that are entirely irrelevant to the current major mode (e.g., =magit-status= in a Python buffer). By setting the predicate to =#'command-completion-default-include-p=, Emacs filters the =M-x= candidate list to only show commands that explicitly declare compatibility with the current buffer's major mode, drastically reducing visual noise.
#+begin_src emacs-lisp
(use-package emacs
  :ensure nil
  :custom
  ;; INDENT-THEN-COMPLETE:
  ;; If the line is not indented, TAB indents it. If it is already indented,
  ;; TAB triggers `completion-at-point', summoning the Corfu popup.
  (tab-always-indent 'complete)

  ;; DICTIONARY SPAM PREVENTION:
  ;; Disables the legacy synchronous Ispell dictionary lookup on M-TAB/TAB
  ;; in text modes. Modern Capfs (like cape-dict or LSP) handle this
  ;; asynchronously without blocking the main thread.
  (text-mode-ispell-word-completion nil)

  ;; CONTEXT-AWARE M-x DECLUTTERING:
  ;; Filters the `M-x' candidate list to only show commands that are
  ;; explicitly compatible with the current major mode, hiding irrelevant
  ;; commands and drastically reducing visual noise.
  (read-extended-command-predicate #'command-completion-default-include-p))
#+end_src

** TODO Nerd Icons Corfu
=corfu= intentionally omits native icon rendering to maintain its minimalistic, high-performance footprint. Instead, it exposes a margin-formatter API (=corfu-margin-formatters=) that allows external packages to inject visual glyphs into the completion popup.

=nerd-icons-corfu= bridges this gap by mapping LSP and Tree-sitter completion categories (e.g., variables, functions, classes, snippets) to their corresponding Nerd Font glyphs. This creates visual parity with the minibuffer, where =nerd-icons-completion= renders identical icons next to =vertico= candidates.

*Load-Order Physics:* The formatter function (=#'nerd-icons-corfu-formatter=) must be registered in the =:init= block. If deferred to =:config=, the registration will occur after Corfu has already initialized its rendering engine, causing the first few completion popups to render without icons until the internal cache is invalidated.

#+begin_src emacs-lisp
(use-package nerd-icons-corfu
  :after corfu
  :init
  ;; Register the Nerd Icons formatter with Corfu's margin API.
  ;; This MUST happen in `:init' so the formatter is available the very
  ;; first time Corfu renders a popup, preventing missing-icon flicker.
  (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))
#+end_src

** TODO Cape
=cape= (Completion At Point Extensions) provides a suite of modular Completion at Point Functions (Capfs) and transformer utilities. It acts as the backend engine for =corfu=, supplying candidates from diverse sources like file paths, dictionary words, shell history, and buffer text.

This configuration strictly implements a /Lean Pipeline Architecture/ optimized for a heavy IDE workflow (Python, C/C++, Rust, Web Dev, and Bash). The =completion-at-point-functions= hook is evaluated by Emacs on almost every keystroke. Adding heavy or overly aggressive Capfs to this global hook causes micro-stutters and completion boundary shadowing (where the first Capf to return a candidate halts the engine, hiding subsequent candidates).

1. *The Lean Global Pipeline (Defensive Boundary Guards):*
Only lightweight Capfs with strict internal boundary guards are added to the global hook:
- =cape-elisp-block=: Natively handles Elisp completion inside Org and Markdown source blocks with zero overhead outside of them.
- =cape-file=: Wrapped in =cape-capf-inside-string=. This mathematically restricts file path completion to trigger /only/ when the cursor is inside a string literal. This is critical for Python, C/C++, Rust, and Web Dev, preventing =cape-file= from aggressively hijacking the completion boundary when typing standard code operators like division (=/=), regex, or object access (=.=).
- =cape-dabbrev=: Wrapped in =cape-capf-prefix-length= with a minimum threshold of 2 characters. This prevents Dabbrev from scanning all open buffers and spamming the UI when only a single character has been typed.

2. *The Bash/Shell Hybrid Approach:*
While string-literal restriction is mathematically perfect for compiled and interpreted programming languages, shell scripts (Bash) frequently utilize unquoted file paths (e.g., =cp src/ dest/=). To support this without polluting the global pipeline, the unwrapped =cape-file= Capf is injected exclusively into the buffer-local hooks of =sh-mode= and =bash-ts-mode=.

3. *Context-Specific Local Hooks (=cape-history=):*
=cape-history= is computationally expensive and only relevant in environments with an active history ring. It is strictly relegated to =comint-mode-hook= (powering history completion for inferior Python, Rust, and Node REPLs) and =minibuffer-setup-hook=.

4. *On-Demand Specialized Capfs (=cape-prefix-map=):*
Heavy or highly specific Capfs (=cape-line=, =cape-emoji=, =cape-dict=, =cape-keyword=, =cape-tex=) are completely removed from the automatic global pipeline. They are exposed on-demand via the =cape-prefix-map= bound to =C-c p=, guaranteeing zero typing stutter while providing instant mnemonic access to the entire Cape arsenal.

5. *LSP & Comint Merging Engine (=cape-wrap-nonexclusive= & =cape-wrap-noninterruptible=):*
By default, Emacs Capfs are exclusive (the first to return wins) and interruptible (aborted if the user types during computation). LSP network requests are inherently slow.
- =cape-wrap-noninterruptible= shields =lsp-completion-at-point= from =quit= signals triggered by =input-pending-p=, forcing the main thread to wait for the network payload and preventing the "stutter-and-vanish" popup bug.
- =cape-wrap-nonexclusive= tells the completion engine to accept LSP/Comint results but continue evaluating the rest of the Capf list, merging network candidates with local Dabbrev and File candidates into a single, unified Corfu popup.
#+begin_src emacs-lisp
(use-package cape
  ;; Bind prefix keymap providing all Cape commands under a mnemonic key.
  ;; Exposes heavy Capfs (cape-line, cape-emoji, cape-dict, etc.) on-demand
  ;; without adding their runtime cost to the automatic global pipeline.
  :bind ("C-c p" . cape-prefix-map)
  :init
  ;; ==========================================
  ;; THE LEAN GLOBAL PIPELINE
  ;; ==========================================
  ;; Only Capfs that are lightweight and possess strict internal boundary
  ;; guards belong in the global hook. Heavy or overly aggressive Capfs
  ;; are relegated to the on-demand `cape-prefix-map` (C-c p) to prevent
  ;; runtime overhead and completion boundary shadowing.

  ;; 1. Elisp in Org/Markdown blocks (Native AST guard)
  (add-hook 'completion-at-point-functions #'cape-elisp-block)

  ;; 2. File completion (Strictly confined to string literals globally)
  ;; Protects Python, C/C++, Rust, and Web Dev from `cape-file` hijacking
  ;; division operators (/), regex, or object access (.) in normal code.
  (add-hook 'completion-at-point-functions (cape-capf-inside-string #'cape-file))

  ;; 3. Dabbrev (Buffer words)
  ;; Wrapped in `cape-capf-prefix-length` to require at least 2 characters,
  ;; preventing UI spam and expensive cross-buffer scans on single keystrokes.
  (setq cape-dabbrev-check-other-buffers t)
  (add-hook 'completion-at-point-functions (cape-capf-prefix-length #'cape-dabbrev 2))

  :config
  ;; ==========================================
  ;; CONTEXT-SPECIFIC LOCAL HOOKS
  ;; ==========================================
  ;; `cape-history` is restricted to environments with an active history ring
  ;; to prevent global overhead. Powers history completion for inferior
  ;; Python, Rust, Node REPLs, and the minibuffer.
  (add-hook 'comint-mode-hook
            (lambda () (add-hook 'completion-at-point-functions #'cape-history nil t)))
  (add-hook 'minibuffer-setup-hook
            (lambda () (add-hook 'completion-at-point-functions #'cape-history nil t)))

  ;; Bash/Shell scripts: Enable unwrapped `cape-file` locally.
  ;; Shell scripts frequently use unquoted file paths (e.g., `cp src/ dest/`).
  ;; Adding it locally here bypasses the global `inside-string` restriction
  ;; without polluting the global pipeline for Python/Rust/C++.
  (add-hook 'sh-mode-hook
            (lambda () (add-hook 'completion-at-point-functions #'cape-file nil t)))
  (add-hook 'bash-ts-mode-hook
            (lambda () (add-hook 'completion-at-point-functions #'cape-file nil t)))

  ;; ==========================================
  ;; LSP & COMINT INTEGRATION (Typing Safeguards)
  ;; ==========================================
  ;; By default, Emacs Capfs are exclusive (the first to return wins) and
  ;; interruptible (aborted if the user types during computation).
  ;; LSP network requests and Comint history lookups are slow. Without these
  ;; wrappers, LSP completions block the main thread (causing UI stutter) and
  ;; exclusive behavior prevents Cape's Dabbrev/File candidates from merging
  ;; with LSP candidates.

  (with-eval-after-load 'lsp-mode
    ;; `cape-wrap-noninterruptible`: Shields LSP from `quit` signals triggered
    ;; by `input-pending-p`, forcing the main thread to wait for the network
    ;; payload and preventing the "stutter-and-vanish" popup bug.
    (advice-add #'lsp-completion-at-point :around #'cape-wrap-noninterruptible)
    ;; `cape-wrap-nonexclusive`: Tells the completion engine to accept LSP
    ;; results but continue evaluating the rest of the Capf list, merging
    ;; LSP candidates with Dabbrev and File candidates.
    (advice-add #'lsp-completion-at-point :around #'cape-wrap-nonexclusive))

  ;; Apply non-exclusive merging to Comint and Pcomplete (Shell)
  ;; so shell history and file paths merge with native shell completions.
  (advice-add #'comint-completion-at-point :around #'cape-wrap-nonexclusive)
  (advice-add #'pcomplete-completions-at-point :around #'cape-wrap-nonexclusive))
#+end_src

** TODO Dabbrev
=dabbrev= (Dynamic Abbreviation) provides native, buffer-scanning word completion. While modern setups often rely on =cape-dabbrev= for asynchronous integration with the Corfu UI, the underlying =dabbrev= engine must be rigorously configured to prevent main-thread freezing, secure sensitive credentials, and eliminate noise pollution from machine-generated buffers.

1. *Defensive Buffer Sizing & Scanning Limits:*
The custom =ar/dabbrev-friend-buffer-p= function prevents =dabbrev= from freezing the main thread when it attempts to scan massive buffers like minified JSON, huge log files, or compiled artifacts. A strict =buffer-live-p= guard is mathematically required to prevent =wrong-type-argument= crashes during asynchronous buffer killing or garbage collection cycles.

2. *Security & Noise Pollution Safeguards:*
By default, =dabbrev= scans all open buffers for word matches. If an =authinfo= or =.netrc= file is open, plaintext passwords and API tokens will silently leak into the Corfu completion popup. =authinfo-mode= is explicitly added to the ignored modes list to guarantee credential isolation. Additionally, machine-generated output buffers (=compilation-mode=, =magit-status-mode=, =magit-log-mode=, and the catch-all =special-mode=) are excluded to prevent garbage text (e.g., =warning:=, =commit=) from polluting the candidate list.

3. *Corfu Synergy (Keybinding Inversion):*
The legacy Emacs binding for =M-/ = is =dabbrev-expand=, which blindly inserts the first matching word inline, bypassing the Corfu UI and Orderless filtering. The bindings are swapped: =M-/ = is mapped to =dabbrev-completion= (summoning the Corfu popup), while =C-M-/ = falls back to the legacy inline =dabbrev-expand= for instant insertion.

4. *Cross-Buffer Scanning Parity:*
=dabbrev-check-other-buffers= is explicitly set to =t=. This guarantees that native =M-/ = behavior perfectly mirrors the =cape-dabbrev= Capf configured in the Cape subsection, allowing both engines to scan adjacent and project buffers for word matches.

5. *Case-Sensitivity Preservation:*
=dabbrev-upcase-means-case-search= is set to =t=. This ensures that typing an uppercase letter forces =dabbrev= to only match uppercase candidates, preserving case-sensitivity when explicitly requested.
#+begin_src emacs-lisp
(defcustom ar/dabbrev-buffer-scanning-size-limit (* 1 1024 1024) ; 1 MB
  "Size limit in characters for a buffer to be scanned by `cape-dabbrev'/`dabbrev'."
  :type 'integer
  :group 'dabbrev)

(defun ar/dabbrev-friend-buffer-p (other-buffer)
  "Return non-nil if OTHER-BUFFER is safe and under the size limit for scanning.
Includes a `buffer-live-p' guard to prevent crashes during asynchronous
buffer killing or garbage collection cycles."
  (and (buffer-live-p other-buffer)
       (< (buffer-size other-buffer) ar/dabbrev-buffer-scanning-size-limit)))

(use-package dabbrev
  :ensure nil
  ;; CORFU SYNERGY: Keybinding Inversion
  ;; Swap M-/ and C-M-/. M-/ summons the Corfu popup (dabbrev-completion),
  ;; allowing Orderless filtering. C-M-/ falls back to legacy inline insertion.
  :bind (("M-/" . dabbrev-completion)
         ("C-M-/" . dabbrev-expand))
  :config
  (setq dabbrev-friend-buffer-function #'ar/dabbrev-friend-buffer-p
        dabbrev-upcase-means-case-search t
        ;; CROSS-BUFFER SCANNING PARITY:
        ;; Explicitly enable scanning other buffers to guarantee that native
        ;; M-/ behavior perfectly mirrors the `cape-dabbrev` Capf.
        dabbrev-check-other-buffers t)

  ;; Ignore hidden/internal Emacs buffers
  (add-to-list 'dabbrev-ignored-buffer-regexps "\\` ")

  ;; Ignore TAGS and generated index files
  (add-to-list 'dabbrev-ignored-buffer-regexps
               "\\(?:\\(?:[EG]?\\|GR\\)TAGS\\|e?tags\\|GPATH\\)\\(<[0-9]+>\\)?")

  ;; SECURITY & NOISE POLLUTION SAFEGUARDS:
  ;; - authinfo-mode: Prevents plaintext passwords and API tokens from leaking
  ;;   into the Corfu completion popup when credential files are open.
  ;; - compilation/magit/special-mode: Excludes machine-generated output buffers
  ;;   to prevent garbage text (warnings, commits) from polluting candidates.
  ;; - doc-view/pdf-view/vterm/eshell: Excludes binary, terminal, and shell buffers.
  (dolist (mode '(doc-view-mode
                  pdf-view-mode
                  dirvish-directory-view-mode
                  vterm-mode
                  term-mode
                  eshell-mode
                  ghostel-mode
                  ghostel-compile-view-mode
                  tags-table-mode
                  authinfo-mode
                  compilation-mode
                  magit-status-mode
                  magit-log-mode
                  special-mode))
    (add-to-list 'dabbrev-ignored-buffer-modes mode)))
#+end_src


```
