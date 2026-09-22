```org
** TODO Flycheck
Highlights syntax errors and warnings directly in the code buffer.
#+begin_src emacs-lisp
(use-package flycheck
  :demand t
  :hook (prog-mode . flycheck-mode)
  :custom
  ;; Inherits the load path for the emacs-lisp checker to respect local dependencies.
  (flycheck-emacs-lisp-load-path 'inherit)
  ;; Routes diagnostic indicators to the right fringe for a modern IDE gutter.
  (flycheck-indication-mode 'right-fringe)
  ;; Underlines only the exact erroneous symbol rather than the entire line.
  (flycheck-highlighting-mode 'symbols)
  ;; Triggers syntax checks on save and idle, excluding newlines to prevent LSP flooding.
  (flycheck-check-syntax-automatically '(save idle-change mode-enabled))
  ;; Delays idle checks to prevent main-thread blocking during rapid typing.
  (flycheck-idle-change-delay 1.0)
  ;; Tightens the echo area feedback loop for snappy error display.
  (flycheck-display-errors-delay 0.25)
  ;; Refreshes syntax check state when briefly switching through intermediate buffers.
  (flycheck-buffer-switch-check-intermediate-buffers t)
  :custom-face
  ;; Forces straight underlines to prevent PGTK/Wayland bezier curve redisplay stutter.
  (flycheck-error ((t (:underline (:style line :color "#f7768e")))))
  (flycheck-warning ((t (:underline (:style line :color "#e0af68")))))
  (flycheck-info ((t (:underline (:style line :color "#7aa2f7")))))
  ;; Themes the fringe indicators to match the Tokyo Night text underlines.
  (flycheck-fringe-error ((t (:foreground "#f7768e"))))
  (flycheck-fringe-warning ((t (:foreground "#e0af68"))))
  (flycheck-fringe-info ((t (:foreground "#7aa2f7"))))
  :config
  ;; Disables org-lint to prevent false positives in Denote/Org silos.
  (setq-default flycheck-disabled-checkers '(org-lint))
  ;; CVE-2024-53920: Disables the emacs-lisp checker in non-project (untrusted) buffers
  ;; to mitigate potential code execution vulnerabilities during macro expansion.
  (eval '(setf (flycheck-checker-get 'emacs-lisp 'predicate)
               (lambda ()
                 (and (not (bound-and-true-p no-byte-compile))
                      (project-current)))) t)
  ;; Prevents the *Flycheck errors* buffer from stealing input focus when popped.
  (add-to-list 'display-buffer-alist
               '("\\*Flycheck error messages\\*\\|\\*Flycheck errors\\*"
                 (display-buffer-reuse-window display-buffer-in-side-window)
                 (side . bottom)
                 (window-height . 0.25)
                 (window-parameters (no-delete-other-windows . t)))))
#+end_src
```

```org
** TODO Flycheck Posframe
Routes diagnostic messages to a floating childframe popup with Corfu and Evil state inhibition.
#+begin_src emacs-lisp
(use-package flycheck-posframe
  :defer t
  :after flycheck
  :hook (flycheck-mode . flycheck-posframe-mode)
  :custom
  ;; Unicode prefixes for visual severity identification.
  (flycheck-posframe-warning-prefix "⚠ ")
  (flycheck-posframe-info-prefix "ⓘ ")
  (flycheck-posframe-error-prefix "⮾ ")
  :custom-face
  ;; Themes the childframe to match the Tokyo Night palette and lsp-ui-doc.
  (flycheck-posframe-background-face ((t (:background "#24283b"))))
  (flycheck-posframe-border-face ((t (:background "#292e42"))))
  :config
  ;; Hides the posframe immediately on the next keypress or user action.
  (defun ar/flycheck-posframe-hide-h ()
    (unless (flycheck-posframe-check-position)
      (posframe-hide flycheck-posframe-buffer))
    (remove-hook 'post-command-hook #'ar/flycheck-posframe-hide-h))

  (define-advice flycheck-posframe-show-posframe (:around (fn &rest args) hide-on-next-command)
    (cl-letf (((symbol-function 'posframe-show)
               (lambda (&rest posframe-args)
                 (add-hook 'post-command-hook #'ar/flycheck-posframe-hide-h)
                 (apply posframe-show posframe-args))))
      (apply fn args)))

  ;; Inhibits popups when Corfu completion is active to prevent spatial collisions.
  (add-hook 'flycheck-posframe-inhibit-functions
            (lambda () (and (boundp 'corfu--index) (>= corfu--index 0))))
  ;; Inhibits popups in Evil insert/replace states to prevent cursor displacement and input delay.
  (add-hook 'flycheck-posframe-inhibit-functions #'evil-insert-state-p)
  (add-hook 'flycheck-posframe-inhibit-functions #'evil-replace-state-p))
#+end_src
```

```org
** TODO Consult Flycheck
Upgrades buffer diagnostic navigation with live minibuffer previews and severity narrowing.
#+begin_src emacs-lisp
(use-package consult-flycheck
  :defer t
  :after (consult flycheck)
  :commands (consult-flycheck))
#+end_src
```

```org
** TODO Flycheck Keybindings
Routes centralized leader and Unimpaired keybindings for diagnostic navigation.
#+begin_src emacs-lisp
(general-define-key
  :states '(normal visual motion)
  "]e" #'flycheck-next-error
  "[e" #'flycheck-previous-error)

(ar/global-leader
  "c e" '(flycheck-list-errors :wk "List errors")
  "c F" '(consult-flycheck :wk "Consult errors"))
#+end_src
```
