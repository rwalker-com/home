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
