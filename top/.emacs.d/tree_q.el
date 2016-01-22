;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test utilities
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require 'cl)
(require 'tree)
(defvar test-cases nil)
(defvar test-failures nil)
(defvar current-test nil)

(eval-and-compile
  ;; For simple assertions...
  (defun assert-equal (a b)
    (when (not (equal a b))
      (princ (format "a: %S\nb: %S\n" a b))
      (error "Assertion failed"))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; tree.el tests
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(eval-when-compile

  (assert-equal (xargs "xxx" '("12345" "22345" "32345" "42345" "52345") 16)
                '("xxx 12345 22345" "xxx 32345 42345" "xxx 52345"))

  (assert-equal (xargs "a" '("b" "bc" "b" "bcd" "bcdefghi") 7)
                '("a b bc" "a b" "a bcd" "a bcdefghi"))

  (for a '( ("b" "x" "ABCD" nil "ABCD")
            ("b" "x" "ABCD" t "AxCD")
            ("." "x" "a.c" nil "axc")
            ("\\" "x" "A\\B" nil "AxB")
            ("x" "\\" "axb" nil "a\\b"))
       ;; case-fold-search should not affect replace-substring
       (let* ((case-fold-search (cadddr a))
              (expected (car (cddddr a)))
              (answer (replace-substring (car a) (cadr a) (caddr a))))
         (assert (equal expected answer) "%s != %s" expected answer)))

  (for a '(("a/.../.x"    "^a/.*/\\.x$")
           ("/....(c|h)"  "^/.*\\.\\(c\\|h\\)$")
           ("/[abc]d"     "^/[abc]d$"))
        (assert-equal (pattern-to-regexp (car a)) (cadr a)))

  ;;            pattern    dir    match
  (dolist (a '(("a/b/..."  "a/b"   all)
               ("a/b/..."  "a/b/c" all)
               ("a/b/..."  "a"     some)
               ("a/..."    "aa"    none)
               ("a..."     "a"     all)
               ("a...."    "a"     some)  ; same as "a...[.]"
               ("a..."     "ab"    all)
               ("a..."     "ab/c"  all)
               ("a..."     "b"     none)
               ("a...b"    "a"     some)
               ("a*"       "a"     none)
               ("a"        "a"     none)
               ("/a/b"     "/a"    some)
               ("/a/b"     "/a/b"  none)
               ("/*/b"     "/a"    some)
               ("/*/b"     "/a/b"  none)
               ("/*/c/..." "/a/b"  none)
               ("/[ab]/..." "/a"   all)
               ("/[ab]/..." "/c"   none)
               ))
    (let* ((pat (car a))
           (dir (cadr a))
           (category (caddr a))
           (all (eval (pattern-all-form pat 'dir)))
           (any (eval (pattern-any-form pat 'dir)))
           (msg (format "%s ~ %s (%s) (all=%s) (any=%s)" pat dir category all any)))
      (assert-equal(not (not all))
                   (eq 'all category))
      (assert-equal (not any)
                    (eq 'none category)))))


(eval-and-compile
  (defvar tt nil) ; parse result; used with dynamic binding
  (defun fp (f)
    (funcall (assqval 'filep tt) (expand-file-name f)))
  (defun dp (d)
    (funcall (assqval 'dirp tt) (expand-file-name d))))


(eval-when-compile
  (defvar root (expand-file-name "/a"))
  (setq tt (treespec-parse "...\n-b/...\n&....(c|h)" root))
  
  (assert (fp "/a/x.c"))
  (assert (fp "/a/b.h"))
  (assert (not (fp "/a/b/x.c")))
  (assert (not (fp "/a/x.o")))
  (assert (dp "/a"))
  (assert (dp "/a/x"))
  (assert (not (dp "/a/b"))))


(eval-when-compile
 (let (gfas requested-file tt)
   ;; redefine (and later restore) get-file-as-string

   (setq gfas (symbol-function 'get-file-as-string))
   (defun get-file-as-string (fname)
     (setq requested-file fname)
     "-a...")

   (setq tt (treespec-parse "/...\n@include f\n/top/ab"
			    (expand-file-name "/top")))

   ;; Compare using "expanded" file name; e.g. DOS "c:/...".
   (assert (equal requested-file (expand-file-name "/top/f")))

   ;; make sure @include applies in right order
   (assert (fp "/top/x"))
   (assert (not (fp "/top/ax")))  ;; related to included file
   (assert (fp "/top/ab"))

   ;; absolute paths too
   (setq tt (treespec-parse "@include /f" "/top"))
   (assert (equal requested-file (expand-file-name "/f")))

   ;; extraneous whitespace
   (setq tt (treespec-parse "@include 	/x	 " "/top"))
   (assert (equal requested-file (expand-file-name "/x")))

   ;; comment
   (setq tt (treespec-parse "@include /a b # c" "/top"))
   (assert (equal requested-file (expand-file-name "/a b")))

   (fset 'get-file-as-string gfas)))


;; select

(eval-when-compile
  (assert-equal '(2 4 6)
                (select (lambda (n) (= 0 (mod n 2)))
                        '(1 2 3 4 5 6 7))))
  
