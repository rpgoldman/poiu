":" ; : "-*- Lisp -*-" \
; case "${1:-sbcl}" in (sbcl) sbcl --load test.lisp \
;; (allegro) alisp -L test.lisp \
;; (ccl) ../single-threaded-ccl/stccl --load test.lisp \
;; (clisp) clisp -i test.lisp \
;; (*) echo "Unrecognized/unsupported Lisp: $1" ; exit 42
;; esac 2>&1 | tee foo ; exit

(in-package :cl-user)

(setf *load-verbose* nil
      *load-print* nil
      *compile-verbose* nil
      *compile-print* nil)

(ignore-errors (funcall 'require "asdf"))
#-asdf2 (load "../asdf/build/asdf.lisp")

(asdf:load-system :asdf)
(asdf:load-system :poiu)

(in-package :poiu) ;; in case there was a punt, be in the NEW asdf package.

(assert (can-fork-p))

(pushnew :DBG *features*)
(defmacro DBG (tag &rest exprs)
  "simple debug statement macro:
outputs a tag plus a list of source expressions and their resulting values, returns the last values"
  (let ((res (gensym))(f (gensym)))
  `(let ((,res))
    (flet ((,f (fmt &rest args) (apply #'format *trace-output* fmt args)))
      (,f "~&~A~%" ,tag)
      ,@(mapcan
         #'(lambda (x)
            `((,f "~&  ~S => " ',x)
              (,f "~{~S~^ ~}~%" (setf ,res (multiple-value-list ,x)))))
         exprs)
      (apply 'values ,res)))))


(setf *load-verbose* t
      *load-print* t
      *compile-verbose* t
      *compile-print* t)

(format *error-output* "~&POIU ~A~%" (component-version (find-system "poiu")))

#+(or)
(trace
 ;; record-dependency operate make-plan perform-plan perform
 ;; action-status (setf action-status) action-already-done-p
 ;; mark-as-done
 ;; process-return process-result ;; action-result-file
 ;; input-files output-files file-write-date
 ;; component-operation-time mark-operation-done
 ;; call-queue/forking posix-waitpid
 ;; perform perform-with-restarts
 ;; compile-file load
 ;; operate call-recording-breadcrumbs
)
;;#+allegro (trace posix-fork posix-wexitstatus posix-waitpid excl::getpid quit)
;;#+clisp (trace asdf::read-file-form asdf::read-file-forms)

(defvar *fare* (uiop/common-lisp:user-homedir-pathname))
(defun subnamestring (base sub)
  (namestring (uiop:subpathname base sub)))

(block nil
  (handler-bind ((error #'(lambda (condition)
                            (format t "~&ERROR:~%~A~%" condition)
                            (print-backtrace :stream *standard-output*)
                            (format t "~&ERROR:~%~A~%" condition)
                            (finish-output)
                            (return))))
    (load-system
     :exscribe ;; :verbose t
     :force :all
     :plan-class 'parallel-plan
     :breadcrumbs-to "/tmp/breadcrumbs.text")
    (funcall (uiop:find-symbol* :process-command-line :exscribe)
             `("-I" ,(subnamestring *fare* "fare/www/")
               "-o" "-" "-H" ,(subnamestring *fare* "fare/www/index.scr")))))

(format t "~&~S~%" (uiop:implementation-identifier))
(format t "~&Compiled with as many as ~D forked subprocesses~%" *max-actual-forks*)

(quit 0)
