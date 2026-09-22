```org
** DONE Dynamic Directory Structure
Establishes the foundational directory scaffolding for the Second Brain. Enforces strict domain separation between the Factory (flat task management) and the Library (Domain-Driven Denote Silos), utilizing native =.dir-locals.el= files for mathematical silo isolation and routing ephemeral attachments away from Git-tracked boundaries.
#+begin_src emacs-lisp
;; ==========================================
;; CORE DYNAMIC DIRECTORY DEFINITIONS
;; ==========================================
(defvar my/org-directory
  (let ((xdg-docs (getenv "XDG_DOCUMENTS_DIR")))
    (if (and xdg-docs (file-directory-p xdg-docs))
        (expand-file-name "org/" xdg-docs)
      (expand-file-name "~/org/")))
  "Base directory for all Org and Denote files, respecting XDG specifications.")

;; Ensure base root exists immediately to prevent `file-truename' edge cases.
(unless (file-directory-p my/org-directory)
  (make-directory my/org-directory t))

;; Canonicalize symlinks for downstream I/O stability.
(setq my/org-directory (file-truename my/org-directory))

;; ==========================================
;; BOOTSTRAP UTILITIES
;; ==========================================
(defun my/ensure-org-dir (subdir)
  "Ensure SUBDIR exists under `my/org-directory', creating parents if needed."
  (let ((dir (expand-file-name subdir my/org-directory)))
    (unless (file-directory-p dir)
      (make-directory dir t))
    dir))

(defun my/ensure-org-file (filepath &optional template)
  "Ensure FILEPATH exists, seeding it with TEMPLATE if newly created."
  (let ((full-path (expand-file-name filepath my/org-directory)))
    (unless (file-exists-p full-path)
      (with-temp-file full-path
        (when template (insert template))))
    full-path))

(defun my/ensure-denote-silo (silo-dir)
  "Isolate SILO-DIR via a native `.dir-locals.el' file.
This mathematically guarantees Denote commands remain scoped to the silo."
  (let ((dir-locals (expand-file-name ".dir-locals.el" silo-dir)))
    (unless (file-exists-p dir-locals)
      (with-temp-file dir-locals
        (insert ";;; Directory Local Variables.  For more information evaluate:\n")
        (insert ";;;\n")
        (insert ";;;     (info \"(emacs) Directory Variables\")\n\n")
        (insert (format "((nil . ((denote-directory . %S))))\n" silo-dir))))
    silo-dir))

;; ==========================================
;; THE FACTORY (Task & Time Tracking)
;; ==========================================
(defvar my/org-agenda-dir (my/ensure-org-dir "agenda/")
  "Directory for flat task management and time tracking.")

(defvar my/org-archive-dir (my/ensure-org-dir "agenda/archive/")
  "Directory for archived tasks.")

(defvar my/org-todo-file
  (my/ensure-org-file "agenda/todo.org"
                      "#+title: Task Registry\n#+filetags: :agenda:\n\n* Inbox\n\n* Projects\n\n* Tasks\n\n* Someday\n\n* Waiting\n")
  "Unified registry for all actionable tasks and project headings.")

(defvar my/org-journal-file
  (my/ensure-org-file "agenda/journal.org"
                      "#+title: Journal\n#+filetags: :journal:\n\n")
  "Daily logs, meeting notes, and ephemeral thoughts.")

(defvar my/org-habits-file
  (my/ensure-org-file "agenda/habits.org"
                      "#+title: Habits\n#+filetags: :habit:\n\n")
  "Dedicated strictly to org-habit consistency graphs.")

;; ==========================================
;; THE LIBRARY (Domain-Driven Denote Silos)
;; ==========================================
;; Zettelkasten is a direct silo.
(defvar my/denote-zettelkasten-dir (my/ensure-org-dir "zettelkasten/")
  "Global, evergreen concepts. Serves as the fallback `denote-directory'.")
(my/ensure-denote-silo my/denote-zettelkasten-dir)

;; Parent directories for Domain-Driven Silos.
;; These do NOT get a `.dir-locals.el` at their root, as each subdirectory
;; (e.g., `projects/website-redesign/`) will be its own isolated Git repo and silo.
(my/ensure-org-dir "projects/")
(my/ensure-org-dir "areas/")
(my/ensure-org-dir "resources/")
(my/ensure-org-dir "archives/")

;; ==========================================
;; SILO CREATION UTILITY
;; ==========================================
(defun my/create-denote-project-silo (project-name)
  "Create a new isolated Denote silo for PROJECT-NAME under `projects/'."
  (interactive "sProject Name: ")
  (let ((silo-dir (expand-file-name project-name (my/ensure-org-dir "projects/"))))
    (unless (file-directory-p silo-dir)
      (make-directory silo-dir t))
    (my/ensure-denote-silo silo-dir)
    (message "Created Denote Silo: %s" silo-dir)
    silo-dir))

;; ==========================================
;; EPHEMERAL & ATTACHMENT ROUTING
;; ==========================================
(defvar my/org-attachments-dir (my/ensure-org-dir "attachments/")
  "Centralized routing for `org-attach' and `org-download' binaries.")

(defvar my/org-downloads-dir (my/ensure-org-dir "downloads/")
  "Staging area for external downloads before processing.")

;; ==========================================
;; GLOBAL VARIABLE EXPORT & WIRING
;; ==========================================
;; Set the global Org directory.
(setq org-directory my/org-directory)

;; Define the foundational `org-agenda-files` list.
;; Strictly confined to the Factory to prevent I/O latency and Denote globbing.
(setq org-agenda-files (list my/org-todo-file
                             my/org-habits-file
                             my/org-journal-file))

;; Route attachments dynamically to prevent binary pollution in Git-tracked silos.
(setq org-attach-id-dir my/org-attachments-dir
      org-attach-use-inheritance t)
#+end_src

```
