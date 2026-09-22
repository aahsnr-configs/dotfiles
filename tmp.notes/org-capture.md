```org
** TODO Org Capture
Routes quick entries to the flat task registry, spawns Denote notes, and provides a hierarchical dispatcher for all capture workflows.
*** Helper Functions
Utility functions for clipboard URL extraction, habit schedule prompting, and context-aware capture targets.
#+begin_src emacs-lisp
(defun ar/capture-url-from-clipboard ()
  "Return the URL currently in the clipboard/kill-ring.
Falls back to `read-string' if no HTTP/HTTPS URL is found."
  ;; `current-kill' natively forces an interprogram paste query on PGTK/Wayland
  ;; before falling back, preventing stale `(car kill-ring)' data.
  (let ((clip (string-trim (or (ignore-errors (current-kill 0)) ""))))
    (if (string-match-p "^https?://" clip)
        clip
      (read-string "URL: "))))

(defun ar/capture-url-as-org-link ()
  "Format the clipboard URL as an org link with a prompted description."
  (let* ((url  (ar/capture-url-from-clipboard))
         (desc (read-string (format "Description [%s]: " url) nil nil url)))
    (format "[[%s][%s]]" url desc)))

(defun ar/capture-habit-range-schedule ()
  "Prompt for ideal and max repeat intervals, return a SCHEDULED timestamp.
Uses `read-string' because %^{prompt} inside %(sexp) receives the literal
string, not user input, per the Org manual expansion order."
  (let* ((ideal   (read-string "Ideal interval in days (e.g. 1): " "1"))
         (ideal-n (string-to-number ideal))
         (max-def (number-to-string (* 2 ideal-n)))
         (max     (read-string
                   (format "Max interval in days (default %s): " max-def)
                   max-def)))
    (format-time-string
     (format "<%%Y-%%m-%%d %%a .+%sd/%sd>" ideal max))))
#+end_src

*** Smart Dispatcher
Hierarchical capture menu routing tasks, notes, journal, habits, goals, and web clips.
#+begin_src emacs-lisp
(defun ar/capture-dispatch ()
  "Hierarchical smart capture dispatcher.
Top-level keys:
[t] Task → inbox in todo.org    [n] New Denote note
[j] Journal (sub-menu)          [m] Meeting notes
[b] Book / article              [h] Habit (sub-menu)
[g] Goal (sub-menu)             [w] Web clip (sub-menu)
[i] Quick inbox with context    [q] Quit"
  (interactive)
  (let ((choice (read-char-choice
                 (concat "Capture: "
                         "[t]ask [n]ote [j]ournal [m]eeting [b]ook "
                         "[h]abit [g]oal [w]eb [i]nbox [q]uit: ")
                 '(?t ?n ?j ?m ?b ?h ?g ?w ?i ?q))))
    (pcase choice
      (?t (org-capture nil "i"))
      (?n (call-interactively #'denote))
      (?j (let ((kind (read-char-choice
                       "Journal: [d]aily  [l]ink+context  [q]uit: "
                       '(?d ?l ?q))))
            (pcase kind
              (?d (org-capture nil "jd"))
              (?l (org-capture nil "jl"))
              (?q (keyboard-quit)))))
      (?m (org-capture nil "m"))
      (?b (org-capture nil "b"))
      (?h (let ((kind (read-char-choice
                       "Habit: [d]aily flexible  [s]trict daily  [r]ange  [q]uit: "
                       '(?d ?s ?r ?q))))
            (pcase kind
              (?d (org-capture nil "hd"))
              (?s (org-capture nil "hs"))
              (?r (org-capture nil "hr"))
              (?q (keyboard-quit)))))
      (?g (let ((kind (read-char-choice
                       "Goal: [l]ife  [Q]uarterly  [w]eekly  [q]uit: "
                       '(?l ?Q ?w ?q))))
            (pcase kind
              (?l (org-capture nil "gl"))
              (?Q (org-capture nil "gQ"))
              (?w (org-capture nil "gw"))
              (?q (keyboard-quit)))))
      (?w (let ((kind (read-char-choice
                       "Web: [c]lipboard URL  [l]ink+context  [q]uit: "
                       '(?c ?l ?q))))
            (pcase kind
              (?c (org-capture nil "wc"))
              (?l (org-capture nil "wl"))
              (?q (keyboard-quit)))))
      (?i (org-capture nil "i"))
      (?q (keyboard-quit)))))
#+end_src

*** Journal Templates
Daily Denote journal entries with optional context links, utilizing state-aware date routing.
#+begin_src emacs-lisp
(defvar ar/capture-templates-journal
  `(("j" "Journal")
    ("jd" "Daily entry" entry
     (file denote-journal-capture-entry-today)
     ,(concat "* %(denote-journal-capture-timestamp) %?\n"
              ":PROPERTIES:\n"
              ":CREATED: %U\n"
              ":END:\n")
     :empty-lines 1 :kill-buffer t)
    ("jl" "Daily entry + context link" entry
     (file denote-journal-capture-entry-today)
     ,(concat "* %(denote-journal-capture-timestamp) %?\n"
              ":PROPERTIES:\n"
              ":CREATED:  %U\n"
              ":CONTEXT:  %a\n"
              ":END:\n")
     :empty-lines 1 :kill-buffer t))
  "Journal capture templates backed by denote-journal-capture.")
#+end_src

*** Meeting Template
Structured meeting notes with attendees, agenda, and action items.
#+begin_src emacs-lisp
(defvar ar/capture-templates-meeting
  `(("m" "Meeting" entry
     (file+headline ,(expand-file-name "agenda/journal.org" my/org-directory)
                    "Meetings")
     ,(concat "* %^{Meeting title} :meeting:\n"
              ":PROPERTIES:\n"
              ":CREATED:    %U\n"
              ":ATTENDEES:  %^{Attendees}\n"
              ":LOCATION:   %^{Location|Remote}\n"
              ":END:\n"
              "\n"
              "** Agenda\n"
              "- %?\n"
              "\n"
              "** Notes\n"
              "\n"
              "** Action Items\n"
              "- [ ] \n"
              "\n"
              "** Follow-up\n")
     :empty-lines 1
     :clock-in t
     :clock-resume t))
  "Meeting capture template.")
#+end_src

*** Book / Article Template
Reading list entries with metadata and reflection prompts.
#+begin_src emacs-lisp
(defvar ar/capture-templates-book
  `(("b" "Book / Article" entry
     (file+headline ,(expand-file-name "agenda/todo.org" my/org-directory)
                    "Someday")
     ,(concat "* TODO %^{Title} :read:\n"
              ":PROPERTIES:\n"
              ":CREATED:  %U\n"
              ":AUTHOR:   %^{Author}\n"
              ":TYPE:     %^{Type|Book|Article|Paper|Video|Podcast}\n"
              ":URL:      %^{URL or DOI|}\n"
              ":STATUS:   Unread\n"
              ":END:\n"
              "\n"
              "** Why this matters\n"
              "%?\n"
              "\n"
              "** Key ideas (fill after reading)\n")
     :empty-lines 1))
  "Book and article capture template.")
#+end_src

*** Habit Templates
Habit entries with flexible, strict, and range repeaters routed to habits.org.
#+begin_src emacs-lisp
(defvar ar/capture-templates-habits
  `(("h" "Habit")
    ("hd" "Daily habit (flexible .+1d)" entry
     (file+headline ,(expand-file-name "agenda/habits.org" my/org-directory)
                    "Habits")
     ,(concat "* TODO %^{Habit name}\n"
              "SCHEDULED: %(format-time-string \"<%Y-%m-%d %a .+1d>\")\n"
              ":PROPERTIES:\n"
              ":STYLE:    habit\n"
              ":END:\n")
     :empty-lines 1)
    ("hs" "Daily habit (strict ++1d)" entry
     (file+headline ,(expand-file-name "agenda/habits.org" my/org-directory)
                    "Habits")
     ,(concat "* TODO %^{Habit name}\n"
              "SCHEDULED: %(format-time-string \"<%Y-%m-%d %a ++1d>\")\n"
              ":PROPERTIES:\n"
              ":STYLE:    habit\n"
              ":END:\n")
     :empty-lines 1)
    ("hr" "Range habit (.+Xd/Yd)" entry
     (file+headline ,(expand-file-name "agenda/habits.org" my/org-directory)
                    "Habits")
     ,(concat "* TODO %^{Habit name}\n"
              "SCHEDULED: %(ar/capture-habit-range-schedule)\n"
              ":PROPERTIES:\n"
              ":STYLE:    habit\n"
              ":END:\n")
     :empty-lines 1))
  "Habit capture templates.")
#+end_src

*** Goal Templates
Life, quarterly, and weekly goals routed to the flat task registry.
#+begin_src emacs-lisp
(defvar ar/capture-templates-goals
  `(("g" "Goal")
    ("gl" "Life goal" entry
     (file+headline ,(expand-file-name "agenda/todo.org" my/org-directory)
                    "Projects")
     ,(concat "* TODO %^{Goal}\n"
              ":PROPERTIES:\n"
              ":CREATED:  %U\n"
              ":AREA:     %^{Area|Health|Career|Learning|Relationships|Finance|Creative}\n"
              ":END:\n"
              "\n"
              "** Why this matters\n"
              "%?\n"
              "\n"
              "** Success looks like\n"
              "\n"
              "** First next action\n"
              "- [ ] \n")
     :empty-lines 1)
    ("gQ" "Quarterly goal" entry
     (file+headline ,(expand-file-name "agenda/todo.org" my/org-directory)
                    "Projects")
     ,(concat "* TODO %^{Goal}\n"
              "DEADLINE: %^{Deadline}t\n"
              ":PROPERTIES:\n"
              ":CREATED:  %U\n"
              ":AREA:     %^{Area|Health|Career|Learning|Relationships|Finance|Creative}\n"
              ":END:\n"
              "\n"
              "** Outcome\n"
              "%?\n"
              "\n"
              "** Key milestones\n"
              "- [ ] \n"
              "\n"
              "** Weekly check-in notes\n")
     :empty-lines 1)
    ("gw" "Weekly intention" entry
     (file+headline ,(expand-file-name "agenda/todo.org" my/org-directory)
                    "Tasks")
     ,(concat "* TODO %^{Intention for the week}\n"
              "SCHEDULED: %t\n"
              ":PROPERTIES:\n"
              ":CREATED:  %U\n"
              ":END:\n"
              "\n"
              "%?\n")
     :empty-lines 1))
  "Goal capture templates.")
#+end_src

*** Web / Bookmark Templates
Clipboard URL bookmarks and Emacs context links for the reading list.
#+begin_src emacs-lisp
(defvar ar/capture-templates-web
  `(("w" "Web / Bookmark")
    ("wc" "Clipboard URL bookmark" entry
     (file+headline ,(expand-file-name "agenda/todo.org" my/org-directory)
                    "Someday")
     ,(concat "* %(ar/capture-url-as-org-link) :bookmark:\n"
              ":PROPERTIES:\n"
              ":CREATED:  %U\n"
              ":TAGS:     %^{Tags (space-separated)}\n"
              ":END:\n"
              "\n"
              "%?\n")
     :empty-lines 1
     :prepend t)
    ("wl" "Link to current Emacs location" entry
     (file+headline ,(expand-file-name "agenda/todo.org" my/org-directory)
                    "Someday")
     ,(concat "* %^{Description} :bookmark:context:\n"
              ":PROPERTIES:\n"
              ":CREATED:  %U\n"
              ":LINK:     %a\n"
              ":END:\n"
              "\n"
              "%?\n")
     :empty-lines 1
     :prepend t))
  "Web clip and bookmark capture templates.")
#+end_src

*** Quick Inbox Template
Frictionless capture to the Inbox heading in the flat task registry.
#+begin_src emacs-lisp
(defvar ar/capture-templates-inbox
  `(("i" "Quick inbox item (with context)" entry
     (file+headline ,(expand-file-name "agenda/todo.org" my/org-directory)
                    "Inbox")
     ,(concat "* TODO %?\n"
              ":PROPERTIES:\n"
              ":CREATED:  %U\n"
              ":CONTEXT:  %a\n"
              ":END:\n")
     :empty-lines 1))
  "Quick inbox capture template routed to agenda/todo.org.")
#+end_src

*** Denote Note Template
Spawns a new Denote note via org-capture with front-matter handled by denote-org-capture.
#+begin_src emacs-lisp
(defvar ar/capture-templates-denote
  '(("n" "Note (Denote)" plain
     (file denote-last-path)
     #'denote-org-capture
     :no-save t :immediate-finish nil :kill-buffer t :jump-to-captured t))
  "Denote note capture template.")
#+end_src

*** use-package
Wires all template groups into org-capture, routes the UI to a dedicated bottom drawer, and saves buffers on successful capture.
#+begin_src emacs-lisp
(use-package org-capture
  :ensure nil
  :defer t
  :after org
  :custom
  (org-capture-templates
   (append ar/capture-templates-journal
           ar/capture-templates-meeting
           ar/capture-templates-book
           ar/capture-templates-habits
           ar/capture-templates-goals
           ar/capture-templates-web
           ar/capture-templates-inbox
           ar/capture-templates-denote))
  :config
  ;; Doom Emacs Parity: Route the *Capture* buffer to a dedicated 33% bottom drawer.
  ;; Isolates it from popper and winner-mode, providing a distraction-free UI
  ;; without the fragility of spawning dedicated X11/Wayland child frames.
  (add-to-list 'display-buffer-alist
               '("\\`\\*Capture\\*\\'\\|\\`CAPTURE-"
                 (display-buffer-in-side-window)
                 (side . bottom)
                 (window-height . 0.33)
                 (window-parameters (no-delete-other-windows . t))))
  ;; Save all org buffers after successful capture only (not on abort).
  (add-hook 'org-capture-after-finalize-hook
            (lambda ()
              (unless org-note-abort
                (org-save-all-org-buffers)))))
#+end_src
```
