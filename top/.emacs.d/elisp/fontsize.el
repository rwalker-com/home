;; fontsize.el - bhk
;;
;; fontsize-*  : Adjust a buffer's text size up/down
;;
;; Bug: tab indentation is not adjusted with text height.
;; Bug: doesn't work with read-only buffers.
;; Bug: doesn't work with narrowed regions.
;;

(defmacro without-undo (&rest body)
  "Suspend undo recording and write protection during BODY, then
restore read-only and modified state."
  `(let ((modified (buffer-modified-p))   ; remember 'modified' state
	 (ro buffer-read-only)            ; remember read-only state
	 (buffer-undo-list t))            ; turn off undo recording
     (setq buffer-read-only nil)
     ,@body
     (setq buffer-read-only ro)
     (unless modified (restore-buffer-modified-p nil))))

(defvar fontsize-current 0
  "Current font size (buffer-local).
0 = default; positive = larger; negative = smaller.
This value is to be modified by 'fontsize-up' or 'fontsize-down',
which activate the font sizing feature.")

(make-variable-buffer-local 'fontsize-current)

(defun fontsize-after-change-function (beg end &optional oldlen)
  (without-undo
    (put-text-property beg end 'display `(height (+ ,fontsize-current)))))

(defun fontsize-up (&optional n)
  "Increase text size of current buffer."
  (interactive "P")
  (setq fontsize-current (max (+ fontsize-current (or n 1)) -9))  ; -10 becomes big again?!?
  (if (= fontsize-current 0)
      ;; disable and clean up when back to 0
      (progn (remove-hook 'after-change-functions 'fontsize-after-change-function t)
	     (without-undo (remove-text-properties 1 (1+ (buffer-size)) '(display nil))))
    ;; resize and install hook
    (fontsize-after-change-function 1 (1+ (buffer-size)))
    (add-hook 'after-change-functions 'fontsize-after-change-function t t))
  (message (format "Size: %+d" fontsize-current)))

(defun fontsize-down (&optional n)
  "Decrease text size of current buffer."
  (interactive "P")
  (fontsize-up (- (or n 1))))

;;----------------------------------------------------------------
;;
;; ; change-size : Resize text and make it sticky.  "Sticky" means
;; ; auto-insert characters will inherit that property (small size)
;; ; from the previous character.  Not all inserts do, however;
;; ; shell windows in particular.
;;
;; (defun change-size (n)
;;  (add-text-properties 1 (1+ (buffer-size))
;;                     `(display (height (- ,n)) rear-nonsticky ((display . t)))))
;;
;;
;; ; reset all properties
;; (set-text-properties 1 (1+ (buffer-size)) nil)

(provide 'fontsize)

