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


(defvar host (downcase (substring (system-name) 0 
                        (string-match "\\." (system-name)))))

(add-to-list `auto-mode-alist `("\\.log\\'" . auto-revert-tail-mode) t)
(add-to-list `auto-mode-alist `("\\.lua\\'" . lua-mode) t)
(add-to-list `auto-mode-alist `("\\.cif\\'" . lua-mode) t)
(add-to-list `auto-mode-alist `("pak\\'" . lua-mode) t)
(add-to-list `auto-mode-alist `("\\.pak\\'" . lua-mode) t)
(add-to-list `auto-mode-alist `("\\.\\(min\\|ma?k\\)\\'" . makefile-mode) t)
(add-to-list `auto-mode-alist `("make\\.dfile\\'" . makefile-mode) t)
(add-to-list `auto-mode-alist `("\\.bid\\'" . c++-mode) t)
(add-to-list `auto-mode-alist `("\\.comp\\'" . compilation-mode) t)
;(add-to-list `auto-mode-alist `("\\.json\\'" . json-mode) t)
;(add-to-list `auto-mode-alist `("\\.js\\'" . js2-mode) t)


(defun c-mode-hook-indent (indent)
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
  (c-set-offset 'case-label '+)
  )

;; TODO: per-project c-offset alist
(defun my-c-mode-hook ()
  (c-mode-hook-indent 4))

;(add-hook 'c++-mode-hook 'my-c-mode-hook)
;(add-hook 'c-mode-hook   'my-c-mode-hook)

(add-hook 'c-common-mode-hook 'google-set-c-style)

(defun my-change-log-mode-hook ()
  (setq indent-tabs-mode nil))
(add-hook 'change-log-mode-hook 'my-change-log-mode-hook)

(defun my-lua-mode-hook ()
  (setq indent-tabs-mode nil))
(add-hook 'lua-mode-hook 'my-lua-mode-hook)

(defun my-java-mode-hook ()
  (and (fboundp 'indent-c-exp) (local-set-key  "\M-q" 'indent-c-exp))
  (and (fboundp 'c-indent-exp) (local-set-key  "\M-q" 'c-indent-exp))
  (setq indent-tabs-mode nil)
  (c-mode-hook-indent 3)
  )

(add-hook 'java-mode-hook 'my-java-mode-hook)

(defun my-idl-mode-hook ()
  (setq indent-tabs-mode nil)
  (c-mode-hook-indent 3)
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

(defun my-sgml-mode-hook ()
  (setq indent-tabs-mode nil)
  )
(add-hook 'sgml-mode-hook 'my-sgml-mode-hook)


;;; OLD "window-system"
;;(cond (running-ntemacs
;;       (defun set-font (f) (set-default-font (create-fontset-from-ascii-font f)))
;;       (set-font "-*-6x13-normal-r-*-*-13-97-*-*-c-*-*-*")
;;       (create-fontset-from-fontset-spec "-*-6x13-normal-r-*-*-13-97-*-*-c-*-*-*")
;;       
;;                                        ;       (set-default-font "-*-6x13-normal-r-*-*-13-97-96-96-c-*-*-#33")
;;                                        ;       (set-default-font "-*-6x13-normal-r-*-*-13-97-*-*-c-*-*-ansi-")
;;                                        ;       (set-default-font "-*-vt100-normal-r-*-*-11-82-*-*-c-*-*-ansi-")
;;                                        ;       (set-screen-width 240)
;;                                        ;       (set-screen-height 110)
;;
;;       (setq file-name-buffer-file-type-alist
;;                                        ;        `(("\\.bat$" . nil) 
;;                                        ;          ("\\.dsp$" . nil) 
;;                                        ;          ("\\.mak$" . nil) 
;;                                        ;          ("\\.ini$" . nil) 
;;                                        ;          (".*" . t))
;;
;;             `(("[:/].*config.sys$")
;;               ("\\.elc$" . t)
;;               ("\\.\\(obj\\|exe\\|com\\|lib\\|sym\\|sys\\|chk\\|out\\|bin\\|ico\\|pif\\|class\\)$" . t)
;;               ("\\.\\(dll\\|drv\\|cpl\\|scr\\vbx\\|386\\|vxd\\|fon\\|fnt\\|fot\\|ttf\\|grp\\)$" . t)
;;               ("\\.\\(hlp\\|bmp\\|wav\\|avi\\|mpg\\|jpg\\|tif\\mov\\au\\)" . t)
;;               ("\\.\\(arc\\|zip\\|lzh\\|zoo\\)$" . t)
;;               ("\\.\\(a\\|o\\|tar\\|z\\|gz\\|taz\\|jar\\)$" . t)
;;               ("\\.tp[ulpw]$" . t)
;;               ("[:/]tags$"))
;;             )
;;
;;       (defun choose-font ()
;;         (interactive)
;;         (let ((font (w32-select-font)))
;;           (set-font font)
;;           (message (concat "Font set to:  " font))))
;;       )
;;      )

(when window-system
  
  (set-background-color
   (or (and (equal (user-login-name) "root")
            "grey20")
       "black"))
  (set-foreground-color "white")
  (set-cursor-color "yellow")

  (defun select-font ()
    (interactive)
    (if (fboundp `w32-select-font) (set-default-font (w32-select-font))
      (if (fboundp `menu-set-font) (menu-set-font)
	(message "Sorry, no set-font functions found."))))

  ;;;; interesting list from bkelley, TODO: make this work?
  ;;`(("6x13"    "-*-6x13-normal-r-*-*-13-97-*-*-c-*-*-ansi-")
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
  (catch `break
    (dolist (name '("-raster-fixed613-normal-normal-normal-mono-13-*-*-*-c-*-iso8859-1"
                    "-*-6x13-normal-r-*-*-13-97-*-*-c-*-*-*"
                    "-*-6x13-normal-r-*-*-13-97-96-96-c-*-*-#33"
                    "-*-6x13-normal-r-*-*-13-97-*-*-c-*-*-ansi-"
                    ))
      (let ((font (create-fontset name)))
        (if font 
            (progn 
              (set-default-font font)
              (throw `break nil))
          )
        )
      )
    )
  )


(put 'upcase-region 'disabled nil)
(put 'downcase-region 'disabled nil)

(and (fboundp 'menu-bar-mode) (menu-bar-mode 0))
(and (fboundp 'tool-bar-mode) (tool-bar-mode 0))
(and (fboundp 'toggle-scroll-bar) (toggle-scroll-bar 0))

(defun insert-time ()
  "inserts date time string"
  (interactive)
  (insert (current-time-string))
  )

(defun prev-window (n)
  "reverse of other window"
  (interactive "p")
  (other-window (- n)))

;; Make the sequence "C-x C-j" execute the `goto-line' command,
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
  (split-window-horizontally 83)        ; includes '|' column
  (other-window 1)
  (split-window-vertically)
  (and (> (screen-width) 166) (split-window-horizontally 83) (other-window 1))
  (other-window 2)
  )

(defun cool-split (s)
  (interactive "NScreens: ")
  (set-screen-width (- (* s 83) 3))
  (cool-split-internal)
  )

(display-time)

(defun whoami ()
  "does a whoami"
  (interactive)
  (message (user-login-name))
  )

(defun smark ()
  "smarks the current buffer"
  (interactive)
  (let ((out (concat (make-temp-file (buffer-name)) ".html"))
        (in  (or (and (fboundp `w32-short-file-name) 
                      (w32-short-file-name buffer-file-name))
                 buffer-file-name)))
    (shell-command (concat "smark -o " out " " in))
    (shell-command (or (and running-ntemacs
                            (concat "cmd /c " (replace-regexp-in-string "/" "\\" out t t)))
                       (concat "open " out)))))


;; Perforce (version control) commands
;;
;;(defun p4-edit ()
;;  (interactive)
;;  (shell-command (concat "p4 edit " buffer-file-name))
;;  (toggle-read-only 0))
;;
;;(defun p4-revert ()
;;  (interactive)
;;  (shell-command (concat "p4 revert " buffer-file-name))
;;  (find-alternate-file buffer-file-name))
;;
;;(defun p4-add ()
;;  (interactive)
;;  (shell-command (concat "p4 add " buffer-file-name)))
;;
;;(defun p4-delete ()
;;  (interactive)
;;  (shell-command (concat "p4 delete " buffer-file-name))
;;  (kill-buffer (current-buffer)))
;;
;;(defun p4-diff ()
;;  (interactive)
;;  (shell-command (concat "p4 diff " buffer-file-name))
;;  (toggle-read-only 0))
;;

(defun byte-compile-directory (dir)
  "compiles all .el files in a directory (or tries)"
  (interactive "DByte compile directory: ")
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

(push
 (byte-compile-directory "~/.emacs.d") 
 load-path)

(require 'lua-mode)
(require 'package)
(add-to-list 'package-archives '("marmalade" . "http://marmalade-repo.org/packages/"))
;(require 'js2-mode)
;(require 'json)
(require 'tree)
(require 'p4)
;;(require 'fontsize)
;;
;;(global-set-key [?\C-+] 'fontsize-up)
;;(global-set-key [?\C--] 'fontsize-down)
;;(global-set-key [?\C-=] 'fontsize-toggle)

(mapcar (lambda (file)
          (and (file-exists-p (expand-file-name file))
               (load-file (expand-file-name file))))
        (list (concat "~/.emacs-" host)))

(defun parenthesize-word ()
  (interactive)
  (kill-word 1)
  (insert "(")
  (yank)
  (insert ")"))

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

;;;;;;;;;;;;;;;;
;; webkit stuff
;;;;;;;;;;;;;;;;

;; internal stuff
(defvar webkit-dir nil 
  "Currently active WebKit development tree root.")

(defvar webkit-type nil 
  "Currently active WebKit development tree type (Mac, Qt, Chromium, etc.).")

(defun webkit-get-dir (arg &optional prompt)
  "Get currently-active webkit directory.  If ARG is non-nil or the current
webkit dir is unset, the user will be queried for webkit's location."
  (let* ((prstr (or prompt "WebKit directory: "))
	 (dir (or (and (null arg) webkit-dir)
		  (setq webkit-dir 
                        (expand-file-name 
                         (directory-file-name
                          (read-directory-name prstr webkit-dir nil t)))))))
    dir))

(defun webkit-get-type (arg &optional prompt)
  "Get currently-active webkit directory type.  If ARG is non-nil or the current
webkit type is unset, the user will be queried for the desired webkit type."
  (let* ((prstr (or prompt "WebKit type: "))
	 (type (or (and (null arg) webkit-type)
                   (setq webkit-type
                         (completing-read prstr `("Qt" "Mac"))))))
    type))

(defun webkit-webkit-error-message (m)
  (message (concat "Error: " m ))
  nil)

(defun webkit-build-internal (d &optional args)
  (let* ((dir (webkit-get-dir d)))
    (compile 
     (concat dir "/Tools/Scripts/build-webkit" webkit-type
             (let ((argstring ""))
               (dolist (arg args argstring)
                 (setq argstring (concat " " arg)))))))
  )

(defun webkit-test-internal (d &optional args)
  (let* ((dir (webkit-get-dir d)))
    (compile 
     (concat dir "/Tools/Scripts/run-webkit-tests" webkit-type
             (let ((argstring ""))
               (dolist (arg args argstring)
                 (setq argstring (concat " " arg)))))))
  )

;; public interface

(defun webkit-debug-safari (&optional arg)
  "Starts gdb of Safari on a debug WebKit Build."
  (interactive "P")
  (let* ((dir (webkit-get-dir arg))
         (dyld-framework-path (concat dir "/WebKitBuild/Debug")))
    (and
     (or (file-directory-p dyld-framework-path)
         (webkit-error-message (concat "can't find " dyld-framework-path)))
     (progn
       (setenv "WEBKIT_UNSET_DYLD_FRAMEWORK_PATH" "YES")
       (setenv "DYLD_FRAMEWORK_PATH" dyld-framework-path)
       (message (concat "DYLD_FRAMEWORK_PATH=" (getenv "DYLD_FRAMEWORK_PATH")))
       (gdb "gdb --annotate=3 -arch x86_64 /Applications/Safari.app/Contents/MacOS/Safari"))))
  )

(defun webkit-debug-qtbrowser (&optional arg)
  "Starts gdb of QtBrowser on a debug WebKit Build."
  (interactive "P")
  (let* ((dir (webkit-get-dir arg))
         (product-dir (concat dir "/WebKitBuild/Debug"))
         (lib-dir (concat product-dir "/lib"))
         (plugin-dir (concat lib-dir "/plugins"))
         (launcher (concat product-dir "/bin/QtTestBrowser")))
    (and
     (or (file-directory-p product-dir)
         (webkit-error-message (concat "can't find " product-dir)))
     (or (file-directory-p lib-dir)
         (webkit-error-message (concat "can't find " lib-dir)))
     (or (file-exists-p launcher)
         (webkit-error-message (concat "can't find " launcher)))
     (progn
       (setenv "QTWEBKIT_PLUGIN_PATH" (concat lib-dir "/plugins"))
       (setenv "LD_LIBRARY_PATH" (concat lib-dir ":" (getenv "LD_LIBRARY_PATH")))
       (gdb (concat "gdb --annotate=3 " launcher)))))
  )

(defun webkit-build-debug (&optional arg)
  (interactive)
  (webkit-build-internal arg `("--debug")))

(defun webkit-build (&optional arg)
  (interactive)
  (webkit-build-internal arg))

(defun webkit-test-debug (&optional arg)
  (interactive)
  (webkit-test-internal arg `("--debug")))

(defun webkit-test (&optional arg)
  (interactive)
  (webkit-test-internal arg))

(defun webkit-select ()
  "Select top directory for webkit operations.  See also `webkit-dir'."
  (interactive)
  (webkit-get-dir 1))

(defun webkit-check-style (&optional arg)
  (interactive)
  (let* ((dir (webkit-get-dir arg))
         (save-default-dir default-directory))
    (setq default-directory dir)
    (compile (concat "cd " dir " && " dir "/Tools/Scripts/check-webkit-style"))
    (setq default-directory save-default-dir))
  )

;; Set keymap. We use the C-x p Keymap for all perforce commands
(defvar webkit-prefix-map
  (let ((map (make-sparse-keymap)))
    (define-key map "c" 'webkit-build-debug)
    (define-key map "C" 'webkit-build)
    (define-key map "t" 'webkit-test-debug)
    (define-key map "T" 'webkit-test)
    (define-key map "w" 'webkit-select)
    (define-key map "d" 'webkit-debug-safari)
    (define-key map "s" 'webkit-check-style)
    map)
  "The prefix for webkit dev commands.")

(if (not (keymapp (lookup-key global-map "\C-xw")))
    (define-key global-map "\C-xw" webkit-prefix-map))

; for Carbon to map command to meta
; '(ns-command-modifier (quote meta))

(custom-set-variables
  ;; custom-set-variables was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 '(delete-selection-mode t)
 '(display-time-24hr-format t)
 '(display-time-day-and-date t)
 '(display-time-mode t)
 '(fill-column 80)
 '(indent-tabs-mode nil)
 '(scroll-bar-mode nil)
 '(inhibit-splash-screen t)
 '(inhibit-startup-screen t)
 '(menu-bar-mode nil)
 '(search-highlight t)
 '(tool-bar-mode nil)
 '(truncate-partial-width-windows nil)
 '(visible-bell nil))

(custom-set-faces
  ;; custom-set-faces was added by Custom.
  ;; If you edit it by hand, you could mess it up, so be careful.
  ;; Your init file should contain only one such instance.
  ;; If there is more than one, they won't work right.
 )

(setenv "P4CONFIG" ".p4config")