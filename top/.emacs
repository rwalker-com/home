;;; -*- Mode: Emacs-Lisp -*-

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                      Basic Customization                         ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Older versions of emacs did not have these variables
;;; (emacs-major-version and emacs-minor-version.)
;;; Let's define them if they're not around, since they make
;;; it much easier to conditionalize on the emacs version.

(if (and (not (boundp 'emacs-major-version))
         (string-match "^[0-9]+" emacs-version))
    (setq emacs-major-version
          (string-to-int (substring emacs-version
                                    (match-beginning 0) (match-end 0)))))
(if (and (not (boundp 'emacs-minor-version))
         (string-match "^[0-9]+\\.\\([0-9]+\\)" emacs-version))
    (setq emacs-minor-version
          (string-to-int (substring emacs-version
                                    (match-beginning 1) (match-end 1)))))

(setq running-xemacs (string-match "Lucid" emacs-version))
(setq running-ntemacs (string-match "nt[45].[01]" (emacs-version)))
(setq running-emacs-19 (>= emacs-major-version 19))
(setq running-fsf-emacs-19 (and running-emacs-19 (not running-xemacs)))


(cond (running-xemacs
       ;;
       ;; Code for any version of Lucid Emacs goes here
       ;;
       ))

(cond (running-emacs-19
       ;;
       ;; Code for any vintage-19 emacs goes here
       ;;
       ))

(cond (running-fsf-emacs-19
       ;;
       ;; Code specific to FSF Emacs 19 (not Lucid Emacs) goes here
       ;;
       (and (fboundp 'global-font-lock-mode)
            ;; Turn on font-lock in all modes that support it
            (global-font-lock-mode t)
            ;; Maximum colors
            (setq font-lock-maximum-decoration t)
            )

       (defun set-facep-foreground (face color)
         (and (facep face)
              (set-face-foreground face color)))

       (defun set-facep-background (face color)
         (and (facep face)
              (set-face-background face color)))

       (set-facep-foreground 'font-lock-comment-face              "darkseagreen")
       (set-facep-foreground 'font-lock-comment-delimiter-face    "darkseagreen")
       (set-facep-foreground 'font-lock-doc-face                  "aquamarine")
       (set-facep-foreground 'font-lock-constant-face             "aquamarine")
       (set-facep-foreground 'font-lock-keyword-face              "darkseagreen2")
       (set-facep-foreground 'font-lock-string-face               "aquamarine")
       (set-facep-foreground 'font-lock-type-face                 "goldenrod")
       (set-facep-foreground 'font-lock-variable-name-face        "darkseagreen2")
       (set-facep-foreground 'font-lock-function-name-face        "lightgoldenrod")
       (set-facep-foreground 'font-lock-builtin-face              "lightsteelblue")
       (set-facep-foreground 'font-lock-preprocessor-face         "lightsteelblue")
         ;      I like the way these are by default
         ;       (set-facep-foreground 'font-lock-negation-char-face        "blue")
         ;       (set-facep-foreground 'font-lock-regexp-grouping-backslash "red")
         ;       (set-facep-foreground 'font-lock-regexp-grouping-construct "pink")

       (set-facep-foreground 'font-lock-warning-face              "yellow")

       (set-facep-background 'region              "grey25")
       (set-facep-background 'highlight           "grey25")
       (set-facep-background 'secondary-selection "grey25")

       (set-facep-foreground 'italic              "light goldenrod")
       (set-facep-foreground 'bold                "goldenrod")
       (set-facep-foreground 'bold-italic         "green")
       (set-facep-foreground 'minibuffer-prompt   "yellow")

       )
      )

(defun byte-compile-directory (dir)
  "compiles all .el files in a directory (or tries)"
  (interactive "DByte compile directory: ")
  (push dir load-path)
  (if (file-directory-p dir)
      (let ((destdir (concat dir "/" emacs-version system-configuration ".elc.d")))
        (make-directory destdir t)
        (mapcar (lambda (file)
                  (let ((src  (concat dir "/" file))
                        (dest (concat destdir "/" file)))
                    (if (file-newer-than-file-p src (concat dest "c"))
                        (progn
                          (copy-file src dest t)
                          (byte-compile-file dest)))))
                  (directory-files dir nil "^.*\.el$"))
        destdir)))

(byte-compile-directory "~/.emacs.d/elisp")

(defun updirs (file &optional dir)
  "look for file in dir and dir's parents, returns readable file name or nil"
  (let ((dir  (replace-regexp-in-string "/+$" "" (or dir default-directory))))
    (let ((test (concat dir "/" file))
          (up   (file-name-directory dir)))
      (if (file-readable-p test)
          test
        (if up (updirs file up) nil)))))

(defun updirs-load-file (file &optional dir)
  "find and load file using updirs from dir"
  (interactive "sFilename: ")
  (let ((file (updirs file dir)))
    (if file (load-file file))))

(defun load-dotemacs-local (&optional dir)
  "find and load the .emacs-local for the specified dir (or cwd if nil)"
  (let ((file (updirs ".emacs-local")))
    (and file
         (and (or (eq (user-uid) (nth 2 (file-attributes file 'integer)))
                  (y-or-n-p (concat "Ok to load " file ", owned by " (nth 2 (file-attributes file 'string)) "?")))
              (updirs-load-file file)))))

(add-hook 'find-file-hook 'load-dotemacs-local)

(require 'tree)

(mapcar (lambda (l) (add-to-list 'auto-mode-alist l))
       '(
         ("\\.gyp\\'" . python-mode)
         ("\\.log\\'" . auto-revert-tail-mode)
         ("\\.\\(min\\|ma?k\\)\\'" . makefile-mode)
         ("make\\.dfile\\'" . makefile-mode)
         ("\\.bid\\'" . c++-mode)
         ("\\.comp\\'" . compilation-mode)
         ("\\.sh\\'" . shell-script-mode)
         ("\\.bash_alias\\'" . shell-script-mode)
         ("\\.cgi\\'" . shell-script-mode)
         ))

;(require 'json)
(cond ((featurep 'json)
       (add-to-list 'auto-mode-alist '("\\.json\\'" . json-mode))))

;(require 'js2-mode)
(cond ((featurep 'js2)
       (add-to-list 'auto-mode-alist '("\\.js\\'" . js2-mode))))

;(require 'go-mode)
(cond ((featurep 'go-mode)
       (add-to-list 'auto-mode-alist '("\\.go\\'" . go-mode))))

;; can be put in a .emacs-local, won't work until after-init, and is *slow*
;(require 'haskell)

; BREW hangover ;)
(setq-default my-c-indent 3)

(defun my-c-style (indent)
  (interactive "NIndent: ")
  (and (fboundp 'indent-c-exp) (local-set-key  "\M-q" 'indent-c-exp))
  (and (fboundp 'c-indent-exp) (local-set-key  "\M-q" 'c-indent-exp))
  (setq c-basic-offset indent)
  (setq c-indent-level indent)          ; 19.x version
  (setq c-continued-statement-offset indent)
  (setq c-brace-offset 0)
  (setq c-label-offset (- 0 indent))
  (setq tab-width indent)
  (setq indent-tabs-mode nil)
  (c-set-offset 'substatement-open 0)
  (c-set-offset 'statement-case-open 0)
  (c-set-offset 'brace-list-open 0)
  (c-set-offset 'case-label '+))

(defun my-c-mode-hook ()
  (my-c-style my-c-indent))

(add-hook 'c++-mode-hook 'my-c-mode-hook)
(add-hook 'c-mode-hook   'my-c-mode-hook)

; for a .emacs-local
;(require 'google-c-style)
;(and (featurep 'google-c-style)
;     (add-hook 'c-common-mode-hook 'google-set-c-style))

;; Delete trailing whitespace from lines before a file is saved.
;; (unless we're editing a makefile)
;;
(add-hook 'before-save-hook
          (lambda ()
            (unless (string-match "^make" (symbol-name major-mode))
              (delete-trailing-whitespace))))

;; Don't show whitespace in command, shell, *Messages*, *Minibuf-.., etc...
;;
(add-hook 'after-change-major-mode-hook
          (lambda ()
            (if (string-match "^ *\*" (buffer-name))
                (setq show-trailing-whitespace nil))))


(require 'lua-mode)
(cond ((featurep 'lua-mode)
       (mapcar (lambda (l) (add-to-list 'auto-mode-alist l))
              '(
                ("\\.lua\\'" . lua-mode)
                ("\\.cif\\'" . lua-mode)
                ("pak\\'" . lua-mode)
                ("\\.pak\\'" . lua-mode)
                ))
       (add-hook 'lua-mode-hook (lambda () (setq indent-tabs-mode nil)))
       )
      )

(defun my-java-mode-hook ()
  (and (fboundp 'indent-c-exp) (local-set-key  "\M-q" 'indent-c-exp))
  (and (fboundp 'c-indent-exp) (local-set-key  "\M-q" 'c-indent-exp))
  (setq indent-tabs-mode nil)
  (my-c-mode-hook)
  )

(add-hook 'java-mode-hook 'my-java-mode-hook)

(defun my-idl-mode-hook ()
  (setq indent-tabs-mode nil)
  (my-c-mode-hook)
  )

(add-hook 'idl-mode-hook 'my-idl-mode-hook)

(add-to-list 'auto-coding-regexp-alist '("^\377\376" . utf-16-le) t)
(add-to-list 'auto-coding-regexp-alist '("^\376\377" . utf-16-be) t)

(defun my-perl-mode-hook ()
  (and (fboundp 'indent-c-exp) (local-set-key  "\M-q" 'indent-c-exp))
  (and (fboundp 'c-indent-exp) (local-set-key  "\M-q" 'c-indent-exp))
  (setq indent-tabs-mode nil)
  )

(add-hook 'perl-mode-hook 'my-perl-mode-hook)

(add-hook 'sgml-mode-hook (lambda () (setq indent-tabs-mode nil)))

(when window-system

  (set-background-color
   (or (and (equal (user-login-name) "root")
            "grey20")
       "black"))
  (set-foreground-color "white")
  (set-cursor-color "yellow")

  (defun select-font ()
    (interactive)
    (if (fboundp 'w32-select-font) (set-default-font (w32-select-font))
      (if (fboundp 'menu-set-font) (menu-set-font)
	(message "Sorry, no set-font functions found."))))

  ;;;; interesting list from bkelley, TODO: make this work?
  ;;'(("6x13"    "-*-6x13-normal-r-*-*-13-97-*-*-c-*-*-ansi-")
  ;;  ("6x11"    "-*-6x11-normal-r-*-*-11-97-*-*-c-*-*-ansi-")
  ;;  ("vt100"   "-*-vt100-normal-r-*-*-11-82-*-*-c-*-*-ansi-")
  ;;  ("term8"   "-*-Terminal-normal-r-*-*-11-100-*-*-c-*-*-*-")
  ;;  ("term9"   "-*-Terminal-normal-r-*-*-12-90-*-*-c-*-*-*-")
  ;;  ("luc8"    "-*-Lucida Console-normal-r-*-*-11-82-*-*-c-*-*-ansi-")
  ;;  ("luc9"    "-*-Lucida Console-normal-r-*-*-12-90-*-*-c-*-*-ansi-")
  ;;  ("luc6n"   "-*-Lucida Console-medium-r-*-*-9-*-*-*-C-65-IS08859-")
  ;;  ("luc7n"   "-*-Lucida Console-medium-r-*-*-10-*-*-*-C-65-IS08859-")
  ;;  ("luc8n"   "-*-Lucida Console-medium-r-*-*-11-82-*-*-C-60-ISO8859-")
  ;;  ("luc10"   "-*-Lucida Console-normal-r-*-*-13-97-*-*-c-*-*-ansi-")
  ;;  ("luc12"   "-*-Lucida Console-normal-r-*-*-15-97-*-*-c-*-*-ansi-")
  ;;  ("deja18"  "-unknown-DejaVu Sans Mono-normal-normal-normal-*-18-*-*-*-m-0-iso10646-1")
  ;;  ("deja15"  "-unknown-DejaVu Sans Mono-normal-normal-normal-*-15-*-*-*-m-0-iso10646-1")
  ;;  ("deja13"  "-unknown-DejaVu Sans Mono-normal-normal-normal-*-13-*-*-*-m-0-isox10646-1")
  ;;  ("deja11"  "-unknown-DejaVu Sans Mono-normal-normal-normal-*-11-*-*-*-m-0-iso10646-1")
  ;;  ("and12"   "-*-Andale Mono-*"))

  (defun create-fontset (name)
    (condition-case nil ; suppress error
        (create-fontset-from-ascii-font name)
      (error nil)))

  ;; various names for my old friend "fixed"
  ;; best one so far: http://www.hassings.dk/lars/fonts.html
  (catch 'break
    (dolist (name '("-raster-fixed613-normal-normal-normal-mono-13-*-*-*-c-*-iso8859-1"
                    "-*-6x13-normal-r-*-*-13-97-*-*-c-*-*-*"
                    "-*-6x13-normal-r-*-*-13-97-96-96-c-*-*-#33"
                    "-*-6x13-normal-r-*-*-13-97-*-*-c-*-*-ansi-"
                    ))
      (let ((font (create-fontset name)))
        (if font
            (progn
              (set-default-font font)
              (throw 'break nil))
          )
        )
      )
    )
  )


(put 'upcase-region 'disabled nil)
(put 'downcase-region 'disabled nil)

(defun insert-time ()
  "inserts date time string"
  (interactive)
  (insert (current-time-string))
  )

(defun prev-window (n)
  "reverse of other window"
  (interactive "p")
  (other-window (- n)))

;; Make the sequence "C-x C-j" execute the 'goto-line' command,
;; which prompts for a line number to jump to.
(global-set-key "\C-x\C-j" 'goto-line)
(global-set-key "\M-o" 'prev-window)
(global-set-key "\M-c" 'compile)

(defun insert-qualcomm-copyright ();filename)
  "Inserts copyright information for filename."
  (interactive);"sFilename: ")
  (insert "/*
=======================================================================
                  Copyright " (substring (current-time-string) -4) " QUALCOMM Incorporated.
                         All Rights Reserved.
                      QUALCOMM Confidential and Proprietary
=======================================================================
*/
")
  )

(defun insert-copyright ();filename)
  "Inserts copyright information for filename."
  (interactive); "sFilename: ")
  (insert-qualcomm-copyright)) ;filename))

(defun buffer-insert-copyright ()
  "Inserts copyright for current buffer"
  (interactive)
  (beginning-of-buffer)
  (insert-copyright); (buffer-name))
  )


(defun insert-function-comment-block (fn)
  "Inserts comment block for fn"
  (interactive "sFunction: ")
  (insert "/**
  || Function
  || --------
  || " fn "
  ||
  || Description
  || -----------
  ||
  || Parameters
  || ----------
  ||
  || Returns
  || -------
  ||
  || Remarks
  || -------
  ||
  */
")
  )

(defun insert-method-comment-block (prototype)
  "Inserts comment block for method, given the full prototype"
  (interactive "sFunction: ")
  (let ((prototype-clean (replace-in-string " +" " " (replace-in-string "[\n\r]" "" prototype))))
    (let ((method (replace-regexp-in-string ".* +\\(.*\\)(.*).*" "\\1()" prototype-clean))
          (params (replace-in-string ", *" "\n   " (replace-regexp-in-string ".*?( *\\(.*\\))" "\\1" prototype-clean))))
      (insert "
=======================================================================

" method "

Description:

Prototype:

   " prototype "

Parameters:
   " params "

Return Value:

Comments:
   None

Side Effects:
   None

See Also:
   None

"))))

(defun insert-multiple-method-comment-block (prototypes)
  "Inserts comment blocks for multiple methods, given the full prototypes separated by newlines"
  (interactive "sFunctions: ")
  (mapcar (lambda (prototype)
            (insert-method-comment-block prototype))
          (split-string prototypes "[\r\n]+")))

(defun extern-c-region (&optional beg &optional end)
  "insert's extern \"C\" stuff around a region"
  (and beg end (kill-region (region-beginning) (region-end)))
  (insert "#ifdef __cplusplus
extern \"C\" {
#endif /* #ifdef __cplusplus */

")
  (and beg end (yank))
  (insert "
#ifdef __cplusplus
}
#endif /* #ifdef __cplusplus */
")
  )

(defun extern-c ()
  "insert's extern \"C\" stuff"
  (interactive)
  (extern-c-region
   (and mark-active (region-beginning))
   (and mark-active (region-end)))
  )

(defun if-0-region (&optional beg &optional end)
  "if 0's a region"
  (and beg end (kill-region beg end))
  (insert "#if 0
")
  (and beg end (yank))
  (insert "
#endif /* #if 0 */
")
  )

(defun if-0 ()
  "if 0's a region"
  (interactive)
  (if-0-region
   (and mark-active (region-beginning))
   (and mark-active (region-end)))
  )

(defun ifndef-region (symbol &optional beg &optional end)
  "Inserts ifndef SYMBOL around a region"
  (and beg end (kill-region beg end))
  (insert "#ifndef " symbol "
")
  (and beg end (yank))
  (insert "
#endif /* #ifndef " symbol " */
")
  )

(defun ifndef (symbol)
  "Inserts ifndef SYMBOL around a region"
  (interactive "sSymbol: \n")
  (ifndef-region
   symbol
   (and mark-active (region-beginning))
   (and mark-active (region-end)))
  )

(defun ifdef-region (symbol &optional beg &optional end)
  "Inserts ifdef SYMBOL around a region"
  (and beg end (kill-region beg end))
  (insert "#ifdef " symbol "
")
  (and beg end (yank))
  (insert "
#endif /* #ifdef " symbol " */
")
  )

(defun ifdef (symbol)
  "Inserts ifdef SYMBOL around a region"
  (interactive "sSymbol: \n")
  (ifdef-region
   symbol
   (and mark-active (region-beginning))
   (and mark-active (region-end)))
  )

(defun replace-in-string (regexp newtext string)
  "Replace REGEXP with NEWTEXT everywhere in STRING and return result.
  NEWTEXT is taken literally---no \\DIGIT escapes will be recognized."
  (let ((result "") (start 0) mb me)
    (while (string-match regexp string start)
      (setq mb (match-beginning 0)
            me (match-end 0)
            result (concat result (substring string start mb) newtext)
            start me))
    (concat result (substring string start)))
  )

(defun buffer-inclusion-guard ()
  "Inserts inclusion guard for current buffer"
  (interactive)
  (let (symbol)
    (setq symbol (upcase (replace-in-string "\\." "_" (buffer-name))))
    (beginning-of-buffer)
    (insert "#define " symbol "
")
    (ifndef-region symbol 1 (buffer-size))
    )
  )

(defun new-header ()
  "Inserts new header file stuff"
  (interactive)
  (buffer-insert-copyright)
  (buffer-inclusion-guard)
  )

(defun insert-class (classname)
  "Inserts class for filename."
  (interactive "sClassname: ")
  (insert "public class " classname "
{
    /* public data, methods */

    /**
     *  main entry point
     */
    public static void main(String args[])
    {

    }

    /* protected data, methods */

    /* private data, methods */

}
")
  )

(defun buffer-insert-class ()
  "Inserts class for current buffer"
  (interactive)
  (insert-class (replace-in-string "\\.java" "" (buffer-name)))
  )

(defun new-java ()
  "Inserts new java file stuff"
  (interactive)
  (buffer-insert-copyright)
  (buffer-insert-class)
  )

(defun next-buffer ()
  (interactive)
  (switch-to-buffer (car (reverse (buffer-list))))
  )

(global-set-key "\M-\C-p" 'bury-buffer) ; 'bury' acts as previous
(global-set-key "\M-\C-n" 'next-buffer)

(defun single-up-center ()
  (interactive)
  (previous-line 1)
  (scroll-down 1)
  )

(global-set-key "\M-p" 'single-up-center)

(defun single-down-center ()
  (interactive)
  (next-line 1)
  (scroll-up 1)
  )

(global-set-key "\M-n" 'single-down-center)
(global-set-key "\C-h" 'backward-delete-char)


(or (fboundp 'set-screen-width)
    (defun set-screen-width (w)
      (interactive "NWidth: ")
      (set-frame-width (window-frame (get-buffer-window)) w)))

(or (fboundp 'set-screen-height)
    (defun set-screen-height (h)
      (interactive "NHeight: ")
      (set-frame-height (window-frame (get-buffer-window)) h)))

(defun set-window-width (w)
  (interactive "NWidth: ")
  (set-screen-width w)
  )

(defun set-window-height (h)
  (interactive "NHeight: ")
  (set-screen-height h)
  )

(defun cool-split-internal ()
  "does a multi-split kinda window...my favorite"
  (interactive)
  (delete-other-windows)
  (and (> (window-body-width) 83) (split-window-horizontally 83))
                                        ; includes '|' column
  (other-window 1)
  (split-window-vertically)
  (while (> (window-body-width) 83) (split-window-horizontally 83)
         (other-window 1))
  (other-window 2)
  )

;(defun cool-split-test ()
;  (interactive)
;  (dotimes (width 300)
;    (set-frame-width (window-frame (get-buffer-window)) (+ width 3))
;    (sleep-for 0.1) ;; some delay in set-frame-width?
;    (cool-split-internal)
;    (redraw-display)))


(defun cool-split (s)
  (interactive "NScreens: ")
  (set-frame-width (window-frame (get-buffer-window)) (- (* s 83) 3))
  (while (/= (frame-width) (- (* s 83) 3))
             (sleep-for 0.1)) ;; some delay in set-frame-width?
  (cool-split-internal)
  )

(display-time)

;(require 'fontsize)
(cond ((featurep 'fontsize)
       (global-set-key [?\C-+] 'fontsize-up)
       (global-set-key [?\C--] 'fontsize-down)
       (global-set-key [?\C-=] 'fontsize-toggle))
      )

(mapcar (lambda (file)
          (and (file-exists-p (expand-file-name file))
               (load-file (expand-file-name file))))
        (list (concat "~/.emacs-"
                      (downcase (substring (system-name) 0
                        (string-match "\\." (system-name)))))))

(defun msdev-compile-compile-command ()
  "does this: compiles with current buffer as makefile"
  (interactive)
  (compile (concat "msdev " buffer-file-name " /make")))

(global-set-key [f7] 'msdev-compile-compile-command)

(defun new-html ()
  (interactive)
  (insert "<html>
  <head>
    <title>
    </title>
  </head>
  <body>

  </body>
</html>"))

(defun get-region ()
  "Return the current region as a list with 2 integers.

If no region is set, return the current cursor pos and the maximum cursor pos."
  (interactive)
  (or
   (and
    mark-active (list (region-beginning) (region-end)))
   (list (point) (point-max))))

(defun pointer-stars-left ()
  (interactive)
  (let ((region (get-region)))
    (query-replace-regexp " +\\(\\*+)\\)" "\\1"
                          nil (nth 0 region) (nth 1 region))
    (query-replace-regexp "\\([0-9a-zA-Z_]\\)\\( +\\)\\(\\*+\\)\\([^/]\\)"
                          "\\1\\3\\2\\4"
                          nil (nth 0 region) (nth 1 region))
    )
  )

(defun ps-print-code-buffer-with-faces (&optional FILENAME)
  (interactive)
  (let ((ps-n-up-printing 2)
        (ps-line-number t))
    (ps-print-buffer-with-faces FILENAME))
  )

(defun ps-print-code-buffer (&optional FILENAME)
  (interactive)
  (let ((ps-n-up-printing 2)
        (ps-line-number t))
    (ps-print-buffer FILENAME)
    )
  )

(cond ((>= emacs-major-version 24)
       (require 'package)
       (custom-set-variable
        '(package-archives (quote (("gnu" . "http://elpa.gnu.org/packages/")
                                   ("melpa-stable" . "http://stable.melpa.org/packages/"))))))
      )

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(auto-revert-interval 0.2)
 '(delete-selection-mode t)
 '(display-time-24hr-format t)
 '(display-time-day-and-date t)
 '(display-time-mode t)
 '(fill-column 80)
 '(indent-tabs-mode nil)
 '(inhibit-startup-screen t)
 '(menu-bar-mode nil)
 '(scroll-bar-mode nil)
 '(search-highlight t)
 '(show-trailing-whitespace t)
 '(tool-bar-mode nil)
 '(truncate-partial-width-windows nil)
 '(visible-bell nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
