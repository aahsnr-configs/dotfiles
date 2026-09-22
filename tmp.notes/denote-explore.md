### 1. `** TODO Denote Explore` Subsection Rewrite

```org
** TODO Denote Explore
Provides summary statistics, random walks, structural maintenance, and network visualization for Denote collections.
#+begin_src emacs-lisp
(use-package denote-explore
  :defer t
  :ensure (:host github :repo "pprevos/denote-explore")
  :after (denote denote-regexp)
  :commands (denote-explore-count-notes
             denote-explore-count-keywords
             denote-explore-barchart-timeline
             denote-explore-barchart-keywords
             denote-explore-barchart-filetypes
             denote-explore-random-note
             denote-explore-random-regex
             denote-explore-random-link
             denote-explore-random-keyword
             denote-explore-random-signature
             denote-explore-duplicate-notes
             denote-explore-duplicate-notes-dired
             denote-explore-missing-links
             denote-explore-zero-keywords
             denote-explore-single-keywords
             denote-explore-rename-keyword
             denote-explore-sync-metadata
             denote-explore-isolated-files
             denote-explore-network
             denote-explore-network-regenerate
             denote-explore-barchart-degree
             denote-explore-barchart-backlinks)
  :custom
  ;; Route graph artifacts (JSON/SVG/GEXF) to the no-littering var directory.
  (denote-explore-network-directory
   (no-littering-expand-var-file-name "denote-explore/")))
#+end_src
```

### 2. Keybindings Subsection Delta

_Strictly adhering to the NO Scope Creep and Atomic Implementation Matrix constraints, the following delta contains **only** the `denote-explore` API surface. The `denote-wordcloud` binding is strictly excised and reserved for the Order 17 implementation phase._

```emacs-lisp
;; Explore & Analytics
"n e"   '(:ignore t :wk "explore")
;; Statistics
"n e c" '(denote-explore-count-notes :wk "Count notes")
"n e k" '(denote-explore-count-keywords :wk "Count keywords")
"n e f" '(denote-explore-barchart-filetypes :wk "Filetypes barchart")
"n e w" '(denote-explore-barchart-keywords :wk "Keywords barchart")
"n e t" '(denote-explore-barchart-timeline :wk "Timeline barchart")
;; Random Walks
"n e r" '(denote-explore-random-note :wk "Random note")
"n e x" '(denote-explore-random-regex :wk "Random regex")
"n e l" '(denote-explore-random-link :wk "Random link")
"n e K" '(denote-explore-random-keyword :wk "Random keyword")
"n e S" '(denote-explore-random-signature :wk "Random signature")
;; Janitor
"n e d" '(denote-explore-duplicate-notes :wk "Duplicate notes")
"n e D" '(denote-explore-duplicate-notes-dired :wk "Duplicates (Dired)")
"n e m" '(denote-explore-missing-links :wk "Missing links")
"n e z" '(denote-explore-zero-keywords :wk "Zero keywords")
"n e s" '(denote-explore-single-keywords :wk "Single keywords")
"n e R" '(denote-explore-rename-keyword :wk "Rename keyword")
"n e y" '(denote-explore-sync-metadata :wk "Sync metadata")
"n e i" '(denote-explore-isolated-files :wk "Isolated files")
;; Network Graphs & Visualisation
"n e n" '(denote-explore-network :wk "Generate network")
"n e g" '(denote-explore-network-regenerate :wk "Regenerate network")
"n e G" '(denote-explore-barchart-degree :wk "Degree barchart")
"n e b" '(denote-explore-barchart-backlinks :wk "Backlinks barchart")
```
