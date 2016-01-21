;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; tree.el - bhk Apr-2008
;;
;; Tree: Multi-directory find, grep, tags generation
;; =================================================
;;
;; See `tree-top', below, for an overview of commands.
;;
;; By default, all files under the top directory with selected extensions
;; are considered part of the tree.  If you would like to exclude certain
;; sub-trees, or include selected subtrees, or include directories that are
;; outside the tree, you can specify a treespec file.
;;
;; Tree Specifications
;; -------------------
;;
;; A treespec file is a named ".treespec" and specifies the set of files to
;; be included in the "tree" for that directory (which is the "top"
;; directory for the tree).  Although we use the terms "tree" and "top", the
;; tree may in fact include files from anywhere in the file system; the
;; "top" is merely a point of reference.
;;
;; A treespec file contains a number of clauses that specify sets of files
;; to be included or excluded from the tree.  The initial character of a
;; clause identifies its type:
;;
;;     <p>    : include files matching pattern <p>
;;     -<p>   : exclude files matching pattern <p>
;;     &<p>   : intersect with files matching pattern <p>
;;
;; A pattern is a string identifies a set of files.  It takes the form of a
;; file path with optional wildcard substrings.  Any file whose path matches
;; the pattern string is considered part of the set.
;;
;; Later (lower) clauses take precedence over earlier (higher) ones.  You
;; can think of a treespec as an imperative program that proceeds from top
;; to bottom manipulating a set of files, or you can think of it as a
;; functional description with left-associativity.
;;
;; Patterns
;;
;; Patterns take the form of relative paths (relative to the "top" directory
;; of the tree) or absolute paths, with an initial "/" or "<drive>:/",
;; depending on the OS.  Patterns may contain ".." path elements to indicate
;; a parent directory, which can be useful to refer to siblings or ancestors
;; of the top directory.
;;
;; Patterns may contain the following wildcard strings:
;;
;;     "*" matches any sequence of characters except "/"
;;     "..." matches any sequence of characters, including "/"
;;     "?" matches any one character
;;     "[<chars>]" matches one character in the set <chars>
;;     "(<alts>)" matches one of a number of alternative substrings
;;            listed in <alts>, delimited by "|" characters.
;;
;; "#" begins a comment anywhere in a line. Lines that contain non-space
;; characters (excluding comments) are treated as clauses.  Clauses may
;; contain spaces, but whitespace characters at the beginning and end of the
;; line (or preceding a comment) are stripped.
;;
;; Lines beginning with "@" specify a directive.  One directive is defined:
;;
;;   @include <file>  : include clauses from another treespec file
;;
;; When treespec files include relative paths they are considered relative
;; to the location of the file in which they appear, not the original or
;; including treespec.
;;
;; Examples:
;;
;;     ...            # include all files in <topdir> and below
;;     ../z/...       # include a sibling directory of <topdir>
;;     -a/...         # exclude everything under <topdir>/a
;;     a/b/...        # include all files under <topdir>/a/b
;;     &/....(c|h)    # exclude files that do *not* end in ".c" or ".h"
;;     defs/x         # include the file <topdir>/defs/x
;;     -...x.c        # exclude files under <topdir> ending in "x.c"
;;     -/...x.c       # exclude files under / ending in "x.c"
;;
;; Note that the fourth period in a row is treated as a literal period.
;; "......." is equivalent to "...[.]...".
;;
;; An empty treespec matches no files.
;;
;; Bugs:
;;
;;   *  "/" or "..." inside "[]" or "()" is not supported, and not detected.
;;
;; Implementation Notes
;; ====================
;;
;; File predicates
;; ---------------
;;
;; A file predicate takes a file name as an argument and returns non-nil
;; when that file is included in the tree.
;;
;; The ordered include/exclude clauses in a tree spec are procedural in
;; nature.  Each line overrides the effect of the previous lines.  When
;; translating to a functional representation, we can treat each clause as a
;; function of the result of the previous lines.
;;
;;    <pat>    =>  (or <match> <previous>)
;;    -<pat>   =>  (and (not <match>) <previous>)  <=> (if <match> nil <previous>)
;;    &<pat>   =>  (and <match> <previous>)
;;
;; Directory predicates
;; --------------------
;;
;; During enumeration we can prune a directory -- avoid descending into it
;; -- when we can conclude that none of its descendants can be matched by
;; the tree spec.  A directory predicate is a function that takes a
;; directory name as an argument and returns non-nil when the directory
;; should be visited.
;;
;; Patterns are defined as functions of file paths that distinguish
;; "included" from "not-included" files.  For pruning we derive
;; corresponding functions of directory names that distinguish between the
;; following three conditions:
;;
;;    yes   = everything under the directory is matched
;;    no    = nothing under the directory is matched
;;    maybe = some files under the directory may match, some may not
;;
;; For each clause we have an expression that determines whether to visit
;; the directory (if some files under it *might* be included) or skip it (if
;; no files under it can possibly be included).  The expressions for each
;; type of clause can be described in terms of the result from the pattern
;; in the clause and the result from the previous clauses in the treespec:
;;
;;     <pat>   =>  (if <no> <previous> t)     =>  (or (not <no>) <previous>)
;;     -<pat>  =>  (if <yes> nil <previous>)  =>  (and (not <yes>) <previous>))
;;     &<pat>  ->  (if <no> nil <previous>)   =>  (and (not <no>) <previous>)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(eval-when-compile (require 'cl))

(defvar grepmode 'grep)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; General-purpose functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar grepmode 'grep)
(when (< emacs-major-version 22)
  ;; Version 21 lacks read-directory-name
  (defun read-directory-name (prompt dir default name)
    (read-file-name prompt dir default name))
  (setq grepmode 'compile))

(defmacro for (var list &rest body)
  "(for var list ...) is shorthand for (mapcar (lambda (var) ...) list)"
  `(mapcar (lambda (,var) ,@body) ,list))

(defmacro cache-result (key list &rest body)
  "Retrieve or generate cached value. Results are stored under KEY in LIST.
If not found, BODY is evaluated to get result."
  `(cdr (or (assoc ,key ,list)
            (car (add-to-list ',list
                              (let ((entry (cons ,key ,@body)))
                                (setq ,list (cons entry ,list))
                                entry))))))

(defsubst assqval (key list)
  (cdr (assq key list)))

(defsubst replace-substring (from to str)
  (replace-regexp-in-string (regexp-quote from) to str t t))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; File-related functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun get-file-as-string (fname)
  "Return file contents as string, or nil if not readable."
  (if (file-readable-p fname)
      (with-temp-buffer(insert-file-contents-literally fname)
                       (buffer-string))))

(defsubst file-name-path (file)
  "Convert file \"/path/file\" name to \"file [/path/]\" form."
  (let ((pos (string-match "/[^/]*$" file)))
    (if (null pos)
        file
      (concat (substring file (1+ pos)) " [" (substring file 0 (1+ pos)) "]" ))))

(defmacro matchdefault (m)
  `(cond ((stringp ,m) (lambda (str) (string-match ,m str))) ; string => regex
         ((null ,m)    'identity )      ; nil    => match all
         (t            ,m )))           ; default : function

(defun find-files (dirs &optional fmatch dmatch nosort)
  "Return a list of all matching files under DIRS.
DIRS is a directory or list of directories.
FMATCH and DMATCH are regular expressions or functions or nil to
match all.  Directories matching DMATCH are enumerated; files
matching FMATCH are included in the output.
If NOSORT is non-nil, the list is not sorted."
  (let ((ffn (matchdefault fmatch))
        (dfn (matchdefault dmatch))
        (dirs (mapcar 'directory-file-name (if (listp dirs) dirs (list dirs))))
        (files nil))
    (while dirs
      ;; avoid recursing into "." or ".." by matching "[^.]" (directory-files
      ;; matches with relative name even when it is returning full name)
      (dolist (f (directory-files (pop dirs) t "[^.]" t))
        (if (file-directory-p f)
            (if (funcall dfn f) (push f dirs))
          (if (funcall ffn f) (push f files)))))
    (if nosort
        files
      (sort files 'string<))))

(defvar xargs-max (if (equal system-type 'windows-nt) 255 4095)
  "Limit on command line size for xargs")

(defun xargs (cmd args &optional maxline)
  "Return list of command lines to invoke CMD with arguments in ARGS.
Uses as many lines as necessary to include all ARGS without exceeding
maximum line length MAXLINE (defaults to xargs-max variable)."
  (let ( (limit (- (or maxline xargs-max) (length cmd) 1)) ; room for args
         (lines nil)
         (line "") )
    (dolist (arg args)
      (and (>= (+ (length line) (length arg)) limit)
           (not (equal line ""))
           (progn (push line lines)
                  (setq line "")))
      (setq line (concat line " " arg)))
    ;; any leftovers?
    (or (equal line "")
        (push line lines))
    ;; reverse and add command string
    (for a (reverse lines)
         (concat cmd a))))

(defun generate-tags (tags files)
  "Regenerate TAGS file from FILES."
  (let* ((args (mapcar 'shell-quote-argument files))
         (cmds (xargs (concat "etags -a -o " tags) args)))
    (when (file-exists-p tags)
      (delete-file tags))
    (message "gentags: %d commands..." (length cmds))
    (dolist (cmd cmds)
      (message "gentags: %s" cmd)
      (shell-command cmd))))

;;;;;;;;;;;;;;;;;
;; treespec
;;;;;;;;;;;;;;;;;

;; Convert a treespec pattern sub-string to a (non-rooted) regexp
(defun subpattern-to-regexp (pat)
  (let ((r (regexp-quote pat)))
    (dolist (a '(("..." . ".*")
                 ("*" . "[^/]*")
                 ("?" . ".?")
                 ("[" . "[")
                 ("]" . "]")
                 ("(" . "\\(")
                 (")" . "\\)")
                 ("|" . "\\|")))
      (setq r (replace-substring (regexp-quote (car a)) (cdr a) r)))
    r))

;; Return a regular expression that matches files matching PAT
(defsubst pattern-to-regexp (pat)
  (concat "^" (subpattern-to-regexp pat) "$"))

;; Return form that evals non-nil if PAT matches FILE
(defun pattern-match-form (pat filesym)
  `(string-match ,(pattern-to-regexp pat) ,filesym))

;; Return a regular expression that matches all possible parent directories
;; (other than "/") of files that match pattern PAT.
;;
;;    PAT         Parent patterns
;;    --------    ---------------
;;    /a/b/c      /a    /a/b
;;    /a/*        /a
;;    /*/b        /*
;;    /a/...      /a    /a/...
;;    /a...       /a...
;;    /a...b/c    /a...
;;
(defun pattern-parents-regexp (pat)
  (let ((p (replace-regexp-in-string "\\.\\.\\..*" ".../x" pat))
        (result nil))
    (dolist (elem (cdr (reverse (split-string p "/"))))
      (let ((ere (subpattern-to-regexp elem)))
        (if (not (equal elem ""))
            (setq result (if result
                             (concat ere "\\(/" result "\\)?")
                           ere)))))
    (if (string-match "^/" pat)
        (setq result (concat "/" result)))
    (concat "^" result "$")))

;; Return a form that evals non-nil if *any* files under ,DIRSYM can match PAT
(defun pattern-any-form (pat dirsym)
  `(string-match ,(pattern-parents-regexp pat) ,dirsym))

;; Return a form that evals non-nil if *all* files under ,DIRSYM will match PAT
(defun pattern-all-form (pat dirsym)
  (if (string-match "^\\(.*?\\)\\(/?\\)\\.\\.\\.$" pat)
      (let* ((base (match-string 1 pat))
             (slash (match-string 2 pat))
             (re (concat "^" (subpattern-to-regexp base)))) ; match base...
        (if (equal "/" slash)
            ;; Ends in "/..." => match base exactly, or base/...
            (setq re (concat re "\\(/\\|$\\)")))
        `(string-match ,re ,dirsym))
    nil))

;; Avoid ambiguous handling of certain sequences
;;   ....     ->  ...[.]
;;   .......  ->  ...[.]...
(defun pattern-normalize (pat top)
  (replace-substring "...." "...[.]" (expand-file-name pat top)))

;; Parse treespec.  This internal function calls itself recursively and
;; returns raw building blocks of the predicates: ( fform dform roots )
;;
(defun treespec-parse-raw (spec top fform dform roots)
  (let ((speclines (split-string spec "[\n\r]+")))
    (dolist (ln speclines)
      (if (string-match "@include[[:blank:]]*\\([^#]*?\\)[[:blank:]]*\\(#.*\\)?$" ln)
          (let* ((file (expand-file-name (match-string 1 ln) top))
                 (res (treespec-parse-raw (get-file-as-string file)
                                          (file-name-directory file)
                                          fform dform roots)))
            (setq fform (car res))
            (setq dform (cadr res))
            (setq roots (caddr res)))
        ;; parse line -> <typ> <relpat>
        (if (string-match "^[ ]*\\([&-]?\\)\\([^#]*?\\)[ ]*\\(#\\|$\\)" ln)
            (let* ((typ (intern (match-string 1 ln)))
                   (pat (pattern-normalize (match-string 2 ln) top)))
              (setq fform (case typ
                            ('- `(if ,(pattern-match-form pat 'f) nil ,fform))
                            ('& `(and ,(pattern-match-form pat 'f) ,fform))
                            (t  `(or ,(pattern-match-form pat 'f) ,fform))))
              (setq dform (case typ
                            ('- `(if ,(pattern-all-form pat 'd) nil ,dform))
                            ('& `(and ,(pattern-any-form pat 'd) ,dform))
                            (t  `(or ,(pattern-any-form pat 'd) ,dform))))
              (if (string-match "\\(.*?\\(/\\|$\\)\\)" pat)
                  (add-to-list 'roots (match-string 0 pat))))))))
  (list fform dform roots))

;; Return an alist describing the treespec, containing:
;;   'filep -> file predicate
;;   'dirp  -> directory predicate
;;   'roots -> root directories from which to descend
(defun treespec-parse (spec top)
  "Return alist describing a treespec. SPEC is contents of treespec.
TOP is directory that treespec is relative to."
  (let ((res (treespec-parse-raw spec top nil nil nil)))
    `( (filep . ,(eval `(lambda (f) ,(car res))))
       (dirp . ,(eval `(lambda (d) ,(cadr res))))
       (roots . ,(caddr res)))))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  User interface: commands, etc.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar default-treespec
  (concat
   "....(js|c|cc|cpp|h|s|idl|py|cif|rb|lua|el|bid|min|mak|html|shtml|pl|java|txt|s|scm|scons)\n"
   ".../[Mm]akefile\n"
   "[Mm]akefile\n"
   ".../SCons*t\n"
   "-.../out/...\n"
   "-out/...\n"
   "-(.)...\n"
   "-...[Hh][Ww][Ii][Oo].h\n"
   "-.../(.)...\n")
  "Default treespec to use when .treespec file is not present in `tree-top'.")

(defvar treespec-case-fold t
  "If non-nil, .treespec pattern matches are case-insensitive.")

(defun treespec-find-files (top)
  "Return a list of all files under 'top', as specified by its treespec."
  (let* ((case-fold-search treespec-case-fold)
         (ts (treespec-parse
              (or (get-file-as-string (concat top "/.treespec"))
                  default-treespec)
              top)))
    (if ts
        (progn
          (message "Scanning tree [%s] ..." top)
          (find-files (assqval 'roots ts) (assqval 'filep ts) (assqval 'dirp ts)))
      (message "Error: bad .treespec file")
      nil)))

(defvar tree-top nil
  "Currently-active top for tree operations:

  `tree-find-file' : find file in tree
  `tree-grep'      : grep files in tree
  `tree-tags'      : generate tags for files in tree

These commands work on the currently-active tree, prompting the user to
activate a tree if one has not been activated or if an argument is
passed (see `universal-argument').  When a tree is activated, a
corresponding TAGS file is activated also.

A treespec file ( .treespec in the top directory ) can be used to tailor
the set of files included in the tree.

Use `tree-clear-cache' to force re-enumeration of files.")

(defun tree-get-top (arg &optional prompt)
  "Get/set currently-active top directory.  If ARG is non-nil or the current
top is unset, the user will be queried to change the current top directory."
  (let* ((prstr (or prompt "Top directory: "))
         (top (or (and (null arg) tree-top)
                  (setq tree-top (directory-file-name
                                  (read-directory-name prstr nil nil t)))))
         (tagfile (concat top "/TAGS")))
    (if (file-exists-p tagfile)
        (visit-tags-table tagfile))
    top))

(defvar tree-files-cache nil)
(defvar tree-listing-name nil)        ; one temp file for each instance of emacs
(defvar tree-listing-list nil)        ; list of strings in the temp file

(defun tree-clear-cache ()
  "Clear cache of file names found within a tree.  See also `tree-top'."
  (interactive)
  (setq tree-files-cache '())
  ;; clear grep "cache" too (temp file may have been removed or be stale)
  (setq tree-listing-list nil))

(tree-clear-cache)                      ; initialize list

(defun tree-select ()
  "Select top directory for tree operations.  See also `tree-top'."
  (interactive)
  (tree-get-top 1))

(defun tree-files (top)
  "Return a list of all the files included in the tree."
  (cache-result top tree-files-cache (treespec-find-files top)))

(defun tree-make-listing (flist)
  "Write strings in flist to temp file (-print0 format).  Return file name."
  (when (not (equal flist tree-listing-list))
    (or tree-listing-name (setq tree-listing-name (make-temp-file "tree")))
    (with-temp-file tree-listing-name
      (dolist (f flist) (insert f "\0")))
    (setq tree-listing-list flist))
  tree-listing-name)

(defun tree-grep (arg)
  "Search for regex in a current tree.  If ARG is given, selects `tree-top'."
  (interactive "P")
  (require grepmode)
  (let* ((top (tree-get-top arg "Top dir for grep: "))
         (expr (read-string (concat "Grep (in " top ") : ")))
         (listing (tree-make-listing (tree-files top))))
    (funcall grepmode (concat "xargs -0 grep -n " expr " < " listing))))

(defun select (pred lst)
  (if lst
      (let ((a (car lst))
            (r (select pred (cdr lst))))
        (if (funcall pred a)
            (cons a r)
          r))))

(defun tree-grep-headers (arg)
  "Search within header files in the tree.  If ARG is given, selects `tree-top'."
  (interactive "P")
  (let* ((top (tree-get-top arg "Top dir for grep: "))
         (expr (read-string (concat "Grep (in " top ") : ")))
         (not-header (lambda (filename) (not (string-match "\\.h$" filename))))
         (hdr-files (select not-header (tree-files top)))
         (listing (tree-make-listing hdr-files)))
    (funcall grepmode (concat "xargs -0 grep -n " expr " < " listing))))

(defun tree-find-file (arg)
  "Find file in current tree.  If ARG is given, selects `tree-top'."
  (interactive "P")
  (let* ((top (tree-get-top arg "Top dir for find-file: "))
         ;; alist has form: '( ("name [dir]" . "dir/name") ...)
         (alist (for f (tree-files top)
                     (cons (file-name-path f) f)))
         (completion-ignore-case t) ;; dynamic binding 'ambient value' weirdness
         (prompt (format "Find file (in %s): " top))
         (input (completing-read prompt alist nil t nil 'tree-find-file-hist)))
    (unless (equal input "") (find-file (cdr (assoc input alist))))))

(defun tree-tags (arg)
  "Generate tags file at current `tree-top' and select as active tags table."
  (interactive "P")
  (let* ((top (tree-get-top arg "Generate TAGS for tree: "))
         (tagfile (concat top "/TAGS")))
    (generate-tags tagfile (tree-files top))
    (visit-tags-table tagfile)))

(defun tree-add-dir (arg)
  "Add a different directory's files to the set of files associated with the
current `tree-top`."
  (interactive "P")
  (let* ((top (tree-get-top arg "Add files to top directory: "))
         (newdir (read-directory-name "[Add files to tree] Directory: " nil nil t))
         (oldfiles (tree-files top))
         (newfiles (treespec-find-files newdir)))
    (setq tree-files-cache (cons (cons top (append newfiles oldfiles))
                                 (rassq-delete-all oldfiles tree-files-cache)))))


;;;;;;;;;;;;;;;;;
;; UI stuff
;;;;;;;;;;;;;;;;;

;; Return first list element for which (pred elem) returns true
(defun first-match (lst pred)
  (let (result)
    (while (and lst (not result))
      (if (funcall pred (car lst))
          (setq result (car lst)))
      (setq lst (cdr lst)))
    result))

(defun my-file-at-point ()
  (save-excursion
    (let* ((sre "\\(^\\|[ \"]\\)")
           (ere "\\($\\|[ \"]\\)")
           (p1 (progn (re-search-backward sre) (re-search-forward sre)))
           (p2 (progn (re-search-forward ere) (match-beginning 0)))
           (str (buffer-substring-no-properties p1 p2)))
      (if (string-match "^<\\(.*\\)>$" str)
          (match-string 1 str)
        str))))

;; Search tree files for path ending in fname
(defun tree-search (fname)
  (let ((flist (tree-files (tree-get-top nil "Top dir for search:")))
        (re (concat (if (string-match "^/" fname) "" "/")
                    (regexp-quote fname) "$")))
    (first-match flist (lambda (f) (string-match re f)))))

(defun tree-find-file-by-name (fname)
  (or (null fname)
      (equal "" fname)
      (if (file-exists-p fname)
          (find-file fname))
      (let ((path (tree-search fname)))
        (if path
            (find-file path)))
      (message "File \"%s\" not found in tree." fname)))

(defun tree-hyperjump ()
  "Visit file named by filename at point."
  (interactive)
  (tree-find-file-by-name (my-file-at-point)))

(defun tree-mouse-hyperjump (e)
  "Visit clicked-on filename.  Current dir and tree defined by `tree-top' are
searched.  This should be bound to a mouse event, as in:
   (global-set-key [mouse-3] 'tree-mouse-hyperjump)"
  (interactive "e")
  (let* ((clickcount (car (cddr e)))
         (posinfo (cadr e))
         (window (car posinfo))
         (bufpos (cadr posinfo))
         (filename (with-current-buffer (window-buffer window)
                     (save-excursion
                       (goto-char bufpos)
                       (my-file-at-point)))))
    ;; go to file if it exists
    (tree-find-file-by-name filename)))


(provide 'tree)
