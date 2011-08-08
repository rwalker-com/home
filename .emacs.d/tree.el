;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; tree.el - bhk Apr-2008
;; 
;; Tree: Multi-directory find, grep, tags generation
;; =================================================
;;
;; See `tree-top', below, for an overview of commands.
;;
;; Tree Specifications
;; -------------------
;; 
;; By default, all files under the top directory with selected extensions
;; are considered part of the tree.  If you would like to exclude certain
;; sub-trees, or include selected subtrees, or include directories that are
;; outside the tree, you can specify a treespec file.
;; 
;; Each line of a tree specification file may contain a clause that
;; specifies files to be included or excluded. Later (lower) clauses take
;; precedence over earlier (higher) ones.  The initial character of a
;; clause identifies its type:
;; 
;;     <p>    : include files matching pattern <p>
;;     -<p>   : exclude files matching pattern <p>
;;     &<p>   : exclude files *not* matching pattern <p>
;; 
;; Patterns are treated as file names relative to the directory containing
;; the tree spec unless they have the form of an absolute path (initial "/"
;; or "<drive>:/", depending on the OS).  Patterns must match then entire
;; file path, not just a substring.  Patterns may contain the following
;; wildcard strings:
;; 
;;     "..." matches any sequence of characters, including "/"
;;     "*" matches any sequence of characters except "/"
;;     "?" matches any one character
;;     "[<chars>]" matches one character in the set <chars>
;;     "(<alts>)" matches one of a number of alternative substrings
;;            listed in <alts>, delimited by "|" characters.
;; 
;; "#" begins a comment anywhere in the line.  Clauses may contain spaces,
;; but whitespace characters at the beginning and end of the line (or
;; preceding a comment) are stripped.
;; 
;; Examples:
;; 
;;     ...            # include all files in this directory and below
;;     ../z/...       # include a sibling directory
;;     -a/...         # exclude everything under a
;;     a/b/...        # except things also under a/b; include them
;;     &/....(c|h)    # exclude files that do *not* end in ".c" or ".h"
;;     -/...x.c       # exclude files ending in "x.c"
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
;;    -<pat>   =>  (and (not <match>) <previous>)
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
;; type of clause can are described in terms of the result from the pattern
;; in the clause and the result from the pervious clauses in the treespec:
;; 
;;     <pat>   =>  (if <no> <previous> t)     =>  (or (not <no>) <previous>)
;;     -<pat>  =>  (if <yes> nil <previous>)  =>  (and (not <yes>) <previous>))
;;     &<pat>  ->  (if <no> nil <previous>)   =>  (and (not <no>) <previous>)
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require 'cl)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; General-purpose functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

(defun assqval (key list)
  (cdr (assq key list)))

(defun replace-substring (from to str &optional casefold)
  "Replace all occurrences of FROM with TO in STR.  CASEFOLD, if non-nil,
specifies case-insensitive search.  cf. `replace-regexp-in-string'"
  (let ((case-fold-search casefold))
    (replace-regexp-in-string (regexp-quote from) to str t t)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; File-related functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun get-file-as-string (fname)
  "Return file contents as string, or nil if not readable."
  (if (file-readable-p fname)
      (with-temp-buffer	(insert-file-contents-literally fname)
			(buffer-string))))

(defun file-name-path (file)
  "Convert file \"/path/file\" name to \"file [/path/]\" form."
  (let ((pos (string-match "/[^/]*$" file)))
    (if (null pos)
	file
      (concat (substring file (1+ pos)) " [" (substring file 0 (1+ pos)) "]" ))))

(defun matchdefault (marg)
  (lexical-let ((m marg))
    (cond ( (stringp m) (lambda (str) (string-match m str)) )  ; string => regex
	  ( (null m)    'identity )                            ; nil    => match all
	  ( t           m ))))                                 ; default : function

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
  (let ( (limit (- (or maxline xargs-max) (length cmd) 1))   ; room for args
	 (lines nil)
	 (line "") )
    (dolist (arg args)
	(when (and (>= (+ (length line) (length arg)) limit)
		   (not (equal line "")))
	  (push line lines)
	  (setq line ""))
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
;; (other than "/") that match pattern PAT.
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
    (dolist (elem (cdr (reverse (split-string p "/" t))))
      (let ((ere (subpattern-to-regexp elem)))
	(setq result (if result
			 (concat ere "\\(/" result "\\)?")
		       ere))))
    (if (string-match "^/" pat)
	(setq result (concat "/" result)))
    (concat "^" result "$")))

;; Return a form that evals non-nil if *any* files under ,DIRSYM can match PAT
(defun pattern-any-form (pat dirsym)
  `(string-match ,(pattern-parents-regexp pat) ,dirsym))

;; Return a form that evals non-nil if *all* files under ,DIRSYM will match PAT
(defun pattern-all-form (pat dirsym)
  ;; When pattern ends in "..." and matches "dir/", then all files are matched.
  (if (and (> (length pat) 2)
	   (string= "..." (substring pat -3)))
      `(string-match ,(pattern-to-regexp pat) (concat ,dirsym "/"))
    nil))

;; Collapse nested and's and or's:  (and a (and b c))  -> (and a b c)
(defun optimize-form (form)
  (let ((op (and (consp form) (car form))))
    (if (member op '(and or))
	(apply 'append
	       (for rawarg form
		    (let ((a (optimize-form rawarg)))
		      (if (eq op (and (consp a) (car a)))
			  (cdr a)
			(list a)))))
      form)))

;; Return alist describing the treespec
;;   filep = file predicate
;;   dirp = directory predicate
(defun treespec-parse (spec top)
  "Return alist describing a treespec. SPEC is contents of treespec.
TOP is directory that treespec is relative to."
  (let (alist speclines fform dform root)
    (setq speclines (split-string spec "[\n\r]+"))
    ;; At present all files must be under one root directory
    (setq root (and (string-match "\\(.*?\\(/\\|$\\)\\)" top)
		    (match-string 1 top)))
    (dolist (ln speclines)
      ;; parse line -> <typ> <relpat> 
      (if (string-match "^[ ]*\\([&-]?\\)\\([^#]*?\\)[ ]*\\(#\\|$\\)" ln)
	  (let* ((typ (intern (match-string 1 ln)))
		 (pat (expand-file-name (match-string 2 ln) top)))
	    (setq fform (case typ
			  ('- `(and (not ,(pattern-match-form pat 'f)) ,fform))
			  ('& `(and ,(pattern-match-form pat 'f) ,fform))
			  (t  `(or ,(pattern-match-form pat 'f) ,fform))))
	    (setq dform (case typ
			  ('- `(and (not ,(pattern-all-form pat 'd)) ,dform))
			  ('& `(and ,(pattern-any-form pat 'd) ,dform))
			  (t  `(or ,(pattern-any-form pat 'd) ,dform)))))))
    
    (push `(filep . ,(eval `(lambda (f) ,(optimize-form fform)))) alist)
    (push `(dirp . ,(eval `(lambda (d) ,(optimize-form dform)))) alist)
    (push `(roots . ,(list root)) alist)
    alist))

(defun treespec-find-files (top)
  "Return a list of all files under 'top', as specified by its treespec."
  (let* ((ts (treespec-parse
	      (or (get-file-as-string (concat top "/.treespec"))
		  default-treespec)
	      top)))
    (if ts
	(progn
	  (message "Scanning tree [%s] ..." top)
	  (find-files (assqval 'roots ts) (assqval 'filep ts) (assqval 'dirp ts)))
      (message "Error: bad .treespec file")
      nil)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  User interface: commands, etc.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

(defvar default-treespec "...\n&....(c|cpp|h|s|idl|cif|rb|lua|el|bid|cif|min)"
  "Default treespec to use when .treespec file is not present in `tree-top'.")

(defun tree-get-top (arg &optional prompt)
  "Get/set currently-active top directory.  If ARG is non-nil or the current
top is unset, the user will be queried to change the current top directory."
  (let* ((prstr (or prompt "Top directory: "))
	 (top (or (and (null arg) tree-top)
		  (setq tree-top (directory-file-name
				  (read-directory-name prstr tree-top nil t)))))
	 (tagfile (concat top "/TAGS")))
    (if (file-exists-p tagfile)
	(visit-tags-table tagfile))
    top))

(defun tree-select ()
  "Select top directory for tree operations.  See also `tree-top'."
  (interactive)
  (tree-get-top 1))

(defun tree-clear-cache ()
  "Clear cache of file names found within a tree.  See also `tree-top'."
  (interactive)
  (setq tree-files-cache '()))

(tree-clear-cache)  ; initialize list

(defun tree-files (top)
  "Return a list of all the files included in the tree."
  (cache-result top tree-files-cache (treespec-find-files top)))

(defun tree-files-directories (top)
  "Return a list of all the directories with files in the tree."
  (delete-dups (let ((dirs '()))
                 (dolist (file (tree-files top) dirs)
                   (let ((dir (file-name-directory file)))
                     (if (file-directory-p dir)
                         (setq dirs (cons dir dirs)))))
                 dirs)))

(setq tree-listing-name nil)  ; one temp file for each instance of emacs
(setq tree-listing-list nil)  ; list of strings in the temp file

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
  (let* ((top (tree-get-top arg "Top dir for grep: "))
	 (expr (read-string (concat "Grep under (" top ") : ")))
	 (file (tree-make-listing (tree-files top))))
    (compile (concat "xargs -0 grep -n " expr " < " file))))

(defun tree-find-file (arg)
  "Find file in current tree.  If ARG is given, selects `tree-top'."
  (interactive "P")
  (let* ((top (tree-get-top arg "Top dir for find-file: "))
	 ;; alist has form: '( ("name [dir]" . "dir/name") ...)
	 (alist (for f (tree-files top)
		     (cons (file-name-path f) f)))
	 (completion-ignore-case t) ;; dynamic binding 'ambient value' weirdness
	 (prompt (format "Find file (under %s): " top))
	 (input (completing-read prompt alist nil t nil 'tree-find-file-hist)))
    (unless (equal input "") (find-file (cdr (assoc input alist))))))

(defun tree-tags (arg)
  "Generate tags file at current `tree-top' and select as active tags table."
  (interactive "P")
  (let* ((top (tree-get-top arg "Generate TAGS for tree: "))
	 (tagfile (concat top "/TAGS")))
    (generate-tags tagfile (tree-files top))
    (visit-tags-table tagfile)))

(defun tree-gdb-dirs (arg)
  "Pumps all file paths from a tree into the current gdb session."
  (interactive "P")
  (let* ((top (tree-get-top arg "gdb dirs for tree: "))
         (file (make-temp-file "tree-gdb-dirs")))
    (with-temp-file file
      (insert "dir\n")
      (dolist (dir (tree-files-directories top))
        (insert (concat "dir " dir "\n"))))
    (message (concat "source " file))
    (gud-basic-call (concat "source " file))))

(provide 'tree)
