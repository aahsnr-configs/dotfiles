The following is the only usable grep config I could find was from unravel team:

```el
(use-package grep
  :ensure nil
  :commands (grep lgrep rgrep)
  :config
  (setq grep-save-buffers nil)
  (setq grep-use-headings t) ; Emacs 30

  (let ((executable (or (executable-find "rg") "grep"))
        (rgp (string-match-p "rg" grep-program)))
    (setq grep-program executable)
    (setq grep-template
          (if rgp
              "/usr/bin/rg -nH --null -e <R> <F>"
            "/usr/bin/grep <X> <C> -nH --null -e <R> <F>"))
    (setq xref-search-program (if rgp 'ripgrep 'grep))))

```

How do I know this line in your config is correct:

```

  (evil-set-initial-state 'grep-edit-mode 'normal))
```

I need an sample example where somewhere someone used the above line with a link and I also need a link to why this config is needed.
