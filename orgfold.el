;;; orgfold.el
;; Copyright (C) 2009 

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;
;; Proof of concept implementation of saving folding information in
;; org buffers. This variant saves folding information in a separate
;; file.
;; 

(require 'cl)
(require 'org)

(defun orgfold-get-fold-info-file-name ()
  (concat (buffer-file-name) ".fold"))

(defun orgfold-save ()
  (save-excursion
    (goto-char (point-min))

    (let (foldstates)
      (unless (looking-at outline-regexp)
        (outline-next-visible-heading 1))

      (while (not (eobp))
        (push (if (some (lambda (o) (overlay-get o 'invisible))
                        (overlays-at (line-end-position)))
                  t)
              foldstates)
        (outline-next-visible-heading 1))
      
      (with-temp-file (orgfold-get-fold-info-file-name)
	(prin1 (nreverse foldstates) (current-buffer))))))

(defun orgfold-restore ()
  (save-excursion
    (goto-char (point-min))
    (let* ((foldfile (orgfold-get-fold-info-file-name))
	   (foldstates
	    (if (file-readable-p foldfile)
		(with-temp-buffer
		  (insert-file-contents foldfile)
 		  (read (current-buffer))))))

      (if (not foldstates)
          (message "no saved folding information for the file")

        (show-all)
        (goto-char (point-min))

        (unless (looking-at outline-regexp)
          (outline-next-visible-heading 1))

        (while (and foldstates
                    (not (eobp)))
          (if (pop foldstates)
            (hide-subtree))

          (outline-next-visible-heading 1))

        (message "restored saved folding")))))

(add-hook 'org-mode-hook 'orgfold-activate)

(defun orgfold-activate ()
  (orgfold-restore)
  (add-hook 'kill-buffer-hook 'orgfold-kill-buffer nil t))

(defun orgfold-kill-buffer ()
  ;; don't save folding info for unsaved buffers
  (unless (buffer-modified-p)
    (orgfold-save)))

(provide 'orgfold)
