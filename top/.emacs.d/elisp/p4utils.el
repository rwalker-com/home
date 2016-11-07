;; p4utils.el - my own alternative to the much larger "standard" p4.el
;;

; Perforce (version control) commands
;
;  By default, these operate on the current buffer's file.  If the current
;  buffer is not viewing a file, or if an argument is specified (i.e. command
;  is prefixed with C-U), then it will prompt for a file name.
;

(defun p4-command (arg cmd)
  (let ((fname    (if (or arg (equal buffer-file-name nil))
                      (read-file-name (concat "p4-" cmd " file: "))
                    buffer-file-name)))

    (shell-command (concat "p4 " cmd " \"" fname "\""))))


(defun p4-edit (arg)
  (interactive "P")
  (p4-command arg "edit")
  (or arg (toggle-read-only 0)))

(defun p4-revert (arg)
  (interactive "P")
  (p4-command arg "revert")
  (or arg (find-alternate-file buffer-file-name)))

(defun p4-add  (arg)
  (interactive "P")
  (p4-command arg "add"))

(defun p4-delete  (arg)
  (interactive "P")
  (p4-command arg "delete")
  (or arg (kill-buffer (current-buffer))))

;; when offline, "chmod +w" is necessary (p4x enables this mode of operation)
(defun p4-offline (arg)
  (interactive "P")
  (shell-command (concat "chmod +w " buffer-file-name))
  (or arg (toggle-read-only 0)))

(provide 'p4utils)
