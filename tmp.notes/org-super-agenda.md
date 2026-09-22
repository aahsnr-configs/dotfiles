```org
** DONE Org Super Agenda
Groups agenda items into labeled sections by urgency, context, and status.
#+begin_src emacs-lisp
(use-package org-super-agenda
  :defer t
  :after org-agenda
  :hook (org-agenda-mode . (lambda () (org-super-agenda-mode 1)))
  :custom
  (org-super-agenda-header-separator ?─)
  (org-super-agenda-hide-empty-groups t)
  (org-super-agenda-keep-order t)
  (org-super-agenda-unmatched-name "Other Tasks")
  (org-super-agenda-show-message nil)
  (org-super-agenda-header-prefix "▸ ")
  (org-super-agenda-final-group-separator
   "\n─────────────────────────────────────────────────\n")
  (org-super-agenda-date-format "%A, %B %d")
  :config
  (set-face-attribute 'org-super-agenda-header nil
    :inherit 'font-lock-keyword-face :weight 'bold :height 1.05)

  (defun ar/org-super-agenda-toggle-group ()
    "Toggle visibility of the current agenda group at point."
    (interactive)
    (let ((pos (if (get-text-property (point) 'org-agenda-structural-header)
                   (point)
                 (or (previous-single-property-change
                      (point) 'org-agenda-structural-header)
                     (user-error "No group header found")))))
      (let* ((header-end (save-excursion
                           (goto-char pos)
                           (forward-line 0)
                           (unless (get-text-property
                                    (point) 'org-agenda-structural-header)
                             (forward-line -1))
                           (line-end-position)))
             (next-header (next-single-property-change
                           header-end 'org-agenda-structural-header
                           nil (point-max)))
             (next-header-start (if next-header
                                    (save-excursion
                                      (goto-char next-header)
                                      (forward-line 0)
                                      (point))
                                  (point-max)))
             (ovs (overlays-in (1+ header-end) next-header-start))
             (fold-ovs (seq-filter
                        (lambda (ov) (overlay-get ov 'ar/sa-fold)) ovs)))
        (if fold-ovs
            (dolist (ov fold-ovs) (delete-overlay ov))
          (let ((ov (make-overlay (1+ header-end) next-header-start)))
            (overlay-put ov 'invisible t)
            (overlay-put ov 'ar/sa-fold t))))))

  (defun ar/org-super-agenda-goto-first-item ()
    "Move point to the first item in the current group."
    (interactive)
    (let ((origin (point)))
      (forward-line 1)
      (if (or (get-text-property (point) 'org-agenda-structural-header)
              (eobp))
          (progn (goto-char origin)
                 (user-error "Empty group")))))

  (define-key org-super-agenda-header-map (kbd "TAB")
    #'ar/org-super-agenda-toggle-group)
  (define-key org-super-agenda-header-map (kbd "RET")
    #'ar/org-super-agenda-goto-first-item)
  (define-key org-super-agenda-header-map (kbd "q")
    #'org-agenda-quit)

  ;; :log closed MUST precede :discard; both match DONE items and
  ;; first-match-wins would otherwise empty the Completed group.
  (setq org-super-agenda-groups
        `((:name ,(concat (nerd-icons-faicon "nf-fa-check_circle" :v-adjust 0.02)
                          " Completed Today")
           :log closed
           :order 0)

          (:discard (:todo ("DONE" "CANCEL")))

          (:name ,(concat (nerd-icons-octicon "nf-oct-alert" :v-adjust 0.02)
                          " Overdue")
           :deadline past
           :scheduled past
           :face font-lock-warning-face
           :order 1)

          (:name ,(concat (nerd-icons-octicon "nf-oct-inbox" :v-adjust 0.02)
                          " Inbox")
           :todo "TODO"
           :file-path "agenda/todo\\.org"
           :transformer (string-remove-prefix "TODO " it)
           :order 2)

          (:name ,(concat (nerd-icons-faicon "nf-fa-calendar" :v-adjust 0.02)
                          " Today")
           :time-grid t
           :order 3)

          (:name ,(concat (nerd-icons-mdicon "nf-md-chart_line" :v-adjust 0.02)
                          " Habits")
           :habit t
           :order 4)

          (:name ,(concat (nerd-icons-faicon "nf-fa-fire" :v-adjust 0.02)
                          " High Priority")
           :priority "A"
           :order 5)

          (:name ,(concat (nerd-icons-faicon "nf-fa-laptop" :v-adjust 0.02)
                          " @Computer")
           :and (:tag "@computer" :todo ("NEXT" "TODO"))
           :order 6)
          (:name ,(concat (nerd-icons-faicon "nf-fa-home" :v-adjust 0.02)
                          " @Home")
           :and (:tag "@home" :todo ("NEXT" "TODO"))
           :order 7)
          (:name ,(concat (nerd-icons-faicon "nf-fa-car" :v-adjust 0.02)
                          " @Errands")
           :and (:tag "@errands" :todo ("NEXT" "TODO"))
           :order 8)
          (:name ,(concat (nerd-icons-faicon "nf-fa-phone" :v-adjust 0.02)
                          " @Phone")
           :and (:tag "@phone" :todo ("NEXT" "TODO"))
           :order 9)
          (:name ,(concat (nerd-icons-faicon "nf-fa-brain" :v-adjust 0.02)
                          " @Deep Work")
           :and (:tag "@deep_work" :todo ("NEXT" "TODO"))
           :order 10)

          (:name ,(concat (nerd-icons-faicon "nf-fa-hourglass_half" :v-adjust 0.02)
                          " Waiting For")
           :todo "WAIT"
           :face shadow
           :transformer (string-remove-prefix "WAIT " it)
           :order 11)

          (:name ,(concat (nerd-icons-faicon "nf-fa-clock" :v-adjust 0.02)
                          " Due Soon")
           :deadline (before "+7d")
           :order 12)

          (:name ,(concat (nerd-icons-octicon "nf-oct-kebab_horizontal"
                          :v-adjust 0.02)
                          " Other Tasks")
           :take (15 (:anything t))
           :order 99))))
#+end_src


```
