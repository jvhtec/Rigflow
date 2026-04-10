;;; ============================================================
;;; RIG_UTILS.LSP - General Helper Functions
;;; Module 2 of 9 | Load order: 2
;;; Dependencies: rig_config.lsp
;;; Part of RigFlow v3.5.6 modular
;;;
;;; Contains: vector math, formatting, logging, path helpers,
;;;           and generic prompt helpers.
;;; ============================================================

;;; ----------------------------
;;; BASIC HELPERS
;;; ----------------------------

(defun rg:msg (s)
  (prompt s)
)

(defun rg:ensure3d (p)
  (if (= (length p) 2)
    (list (car p) (cadr p) 0.0)
    p
  )
)

(defun rg:dtr (a)
  (* pi (/ a 180.0))
)

(defun rg:v+ (a b)
  (list (+ (car a) (car b))
        (+ (cadr a) (cadr b))
        (+ (if (caddr a) (caddr a) 0.0)
           (if (caddr b) (caddr b) 0.0)))
)

(defun rg:v- (a b)
  (list (- (car a) (car b))
        (- (cadr a) (cadr b))
        (- (if (caddr a) (caddr a) 0.0)
           (if (caddr b) (caddr b) 0.0)))
)

(defun rg:v* (v s)
  (list (* (car v) s)
        (* (cadr v) s)
        (* (if (caddr v) (caddr v) 0.0) s))
)

(defun rg:vlen (v)
  (sqrt
    (+ (* (car v) (car v))
       (* (cadr v) (cadr v))
       (* (if (caddr v) (caddr v) 0.0)
          (if (caddr v) (caddr v) 0.0)))
  )
)

(defun rg:vunit (v / l)
  (setq l (rg:vlen v))
  (if (equal l 0.0 1e-9)
    nil
    (rg:v* v (/ 1.0 l))
  )
)

(defun rg:vlen2d (v)
  (sqrt
    (+ (* (car v) (car v))
       (* (cadr v) (cadr v)))
  )
)

(defun rg:vunit2d (v / l)
  (setq l (rg:vlen2d v))
  (if (equal l 0.0 1e-9)
    nil
    (list (/ (car v) l) (/ (cadr v) l) 0.0)
  )
)

(defun rg:dot (a b)
  (+ (* (car a) (car b))
     (* (cadr a) (cadr b))
     (* (if (caddr a) (caddr a) 0.0)
        (if (caddr b) (caddr b) 0.0)))
)

(defun rg:perp-left (v)
  (list (- (cadr v)) (car v) 0.0)
)

;;; ----------------------------
;;; FORMAT / STRING HELPERS
;;; ----------------------------

(defun rg:fmt-real (val)
  (rtos val 2 2)
)

(defun rg:fmt-weight (val)
  (strcat (rtos val 2 0) " Kg")
)

(defun rg:pad-int (n width / s)
  (setq s (itoa n))
  (while (< (strlen s) width)
    (setq s (strcat "0" s))
  )
  s
)

;;; ----------------------------
;;; LOGGING / PATH HELPERS
;;; ----------------------------

(defun rg:append-log (line / fh)
  (if *rg-debug-log*
    (progn
      (setq fh (open *rg-debug-log* "a"))
      (if fh
        (progn
          (write-line line fh)
          (close fh)
        )
      )
    )
  )
)

(defun rg:pt->str (pt / p)
  (setq p (rg:ensure3d pt))
  (strcat "("
          (rg:fmt-real (car p)) ", "
          (rg:fmt-real (cadr p)) ", "
          (rg:fmt-real (if (caddr p) (caddr p) 0.0))
          ")")
)

(defun rg:stage (stage msg)
  (rg:append-log (strcat "STAGE | " stage " | " (if msg msg "")))
  (if msg
    (rg:msg (strcat "\nRIGFLOW > " stage ": " msg))
    (rg:msg (strcat "\nRIGFLOW > " stage))
  )
)

(defun rg:fail (stage msg)
  (rg:append-log (strcat "FAIL | " stage " | " msg))
  (rg:msg (strcat "\nRIGFLOW > " stage " FAILED: " msg))
)

(defun rg:normalize-path (p)
  (if p (vl-string-translate "\\" "/" p) nil)
)

(defun rg:native-path (p)
  (if p (vl-string-translate "/" "\\" p) nil)
)

(defun rg:ensure-trailing-slash (p)
  (if (and p (> (strlen p) 0) (/= (substr p (strlen p) 1) "/"))
    (strcat p "/")
    p
  )
)

;;; ----------------------------
;;; GENERIC PROMPT HELPERS
;;; ----------------------------

(defun rg:prompt-kword (stage optionPrompt keywords / raw ans)
  ;; Use getstring plus manual parsing because getkword proved unreliable in this workflow.
  ;; This also lets us accept readable words, abbreviations, and legacy numbers for debugging.
  (rg:stage stage (strcat "Waiting for option input " optionPrompt))
  (setq raw (getstring T (strcat "\nRIGFLOW > " stage " " optionPrompt ": ")))
  (if raw
    (progn
      (setq ans (strcase (vl-string-trim " " raw)))
      (rg:append-log (strcat "RAW | " stage " | " ans))
      (if (= ans "")
        (progn
          (rg:stage stage "No option entered.")
          nil
        )
        (progn
          (rg:stage stage (strcat "Selected " ans))
          ans
        )
      )
    )
    (progn
      (rg:stage stage "No option entered.")
      nil
    )
  )
)

(defun rg:get-string-default (stage msg def / val)
  (rg:stage stage "Waiting for text input.")
  (setq val (getstring T (strcat "\nRIGFLOW > " stage " " msg " <" def ">: ")))
  (if (= val "")
    (progn
      (rg:stage stage (strcat "Using default " def))
      def
    )
    (progn
      (rg:stage stage (strcat "Entered " val))
      val
    )
  )
)

(defun rg:get-int-default (stage msg def / val)
  (rg:stage stage "Waiting for integer input.")
  (setq val (getint (strcat "\nRIGFLOW > " stage " " msg " <" (itoa def) ">: ")))
  (if val
    (progn
      (rg:stage stage (strcat "Entered " (itoa val)))
      val
    )
    (progn
      (rg:stage stage (strcat "Using default " (itoa def)))
      def
    )
  )
)

(defun rg:get-positive-real (stage msg / val)
  (rg:stage stage "Waiting for numeric input.")
  (setq val (getreal (strcat "\nRIGFLOW > " stage " " msg ": ")))
  (cond
    ((null val)
      (rg:stage stage "No numeric value entered.")
      nil
    )
    ((> val 0.0)
      (rg:stage stage (strcat "Entered " (rg:fmt-real val)))
      val
    )
    (T
      (rg:fail stage (strcat "Value must be greater than zero. Got " (rg:fmt-real val)))
      nil
    )
  )
)

(defun rg:get-yes-no (stage question / ans)
  (setq ans (rg:prompt-kword stage (strcat question " [Yes/No]") "Yes No"))
  (cond
    ((or (= ans "YES") (= ans "Y") (= ans "1")) T)
    ((or (= ans "NO") (= ans "N") (= ans "2")) nil)
    (T
      (if ans
        (rg:fail stage (strcat "Unrecognized yes/no option: " ans)))
      nil)
  )
)

(defun rg:get-real-default (stage msg def / val)
  (rg:stage stage "Waiting for numeric input.")
  (setq val (getreal (strcat "\nRIGFLOW > " stage " " msg " <" (rg:fmt-real def) ">: ")))
  (if val
    (progn
      (rg:stage stage (strcat "Entered " (rg:fmt-real val)))
      val
    )
    (progn
      (rg:stage stage (strcat "Using default " (rg:fmt-real def)))
      def
    )
  )
)

(defun rg:confirm-place (stage / ans done ok)
  (setq done nil)
  (setq ok nil)
  (while (not done)
    (rg:stage stage "Waiting for preview confirmation. Enter = Accept.")
    (setq ans (getstring T (strcat "\nRIGFLOW > " stage " Preview [Accept/Cancel] <Accept>: ")))
    (if ans
      (setq ans (strcase (vl-string-trim " " ans)))
    )
    (rg:append-log (strcat "RAW | " stage " | " (if ans ans "")))
    (cond
      ((or (null ans) (= ans "") (= ans "ACCEPT") (= ans "A") (= ans "1"))
        (setq ok T)
        (setq done T)
      )
      ((or (= ans "CANCEL") (= ans "C") (= ans "2"))
        (rg:stage stage "Preview canceled.")
        (setq ok nil)
        (setq done T)
      )
      (T
        (rg:fail stage (strcat "Unrecognized preview option: " ans))
        (rg:stage stage "Preview is still active. Type Accept or Cancel."))
    )
  )
  ok
)

(princ)
