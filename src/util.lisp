(cl:in-package :cl-user)
(when (cl:find-package :ros.util)
  (push :ros.util *features*))

(defpackage :ros.util
  (:use :cl)
  (:export :uname :uname-m :homedir :config :use :impl))

(in-package :ros.util)

(defun uname ()
  (ros:roswell '("roswell-internal-use" "uname") :string t))

(defun uname-m ()
  (ros:roswell '("roswell-internal-use" "uname" "-m") :string t))

(defun homedir ()
  (ros:opt "homedir"))

(defun impl (imp)
  (ros:roswell `("roswell-internal-use" "impl" ,(or imp "")) :string t))

(defun config (c)
  (ros:roswell (list "config show" c) :string t))

(defun (setf config) (a b)
  (ros:roswell (list "config" b a) :string t)
  a)

(defun parse-version-spec (string)
  "Parse the given version specification string and returns a list of strings (LISP VERSION).
If it does not contain a version substring, VERSION becomes a null.
If it is a version string only (detected when it starts from digit-char), LISP becomes NIL.
Examples:
ccl-bin/1.11 -> (\"ccl-bin\" \"1.11\")
ccl-bin      -> (\"ccl-bin\" nil)
1.11         -> (nil \"1.11\")
"
  (let ((pos (position #\/ string)))
    (if pos
        (list (subseq string 0 pos) (subseq string (1+ pos)))
        (if (digit-char-p (aref string 0))
            (list nil string)
            (list string nil)))))

(defun use (arg)
  "Parse the lisp version string (such as ccl-bin/1.11) and set it to the correct config slot(s)"
  (when (and arg
             (ignore-errors
               (ros:roswell `("-L" ,arg "version=t" "run"))))
    (destructuring-bind (lisp version) (parse-version-spec arg)
      (cond ((and lisp version)
             (setf (config "default.lisp") lisp
                   (config (format nil "~A.version" lisp)) version))
            (lisp
             (setf (config "default.lisp")
                   lisp))
            (version
             (setf (config (format nil "~A.version" (config "default.lisp")))
                   version))))
    t))
