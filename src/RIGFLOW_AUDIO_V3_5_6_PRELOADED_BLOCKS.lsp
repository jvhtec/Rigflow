;;; ============================================================
;;; RIGFLOW_AUDIO_V3_5_6_PRELOADED_BLOCKS.LSP
;;;
;;; Command:
;;;   RIGFLOW
;;;
;;; Workflow:
;;;   - Main
;;;   - Optional Outfill
;;;   - Optional Flown Subs
;;;   - Optional mirror at end
;;;   - Final numbering assigned per POINT, left-to-right
;;;
;;; Naming logic:
;;;   main L  -> SX01 / SX02
;;;   main R  -> SX03 / SX04
;;;   out  L  -> SX05 / SX06
;;;   out  R  -> SX07 / SX08
;;;   sub  L  -> SX09 / SX10
;;;   sub  R  -> SX11 / SX12
;;;
;;; Pair point order:
;;;   front first, back second
;;;
;;; Single-point option:
;;;   available for main / out / sub
;;;   full entered weight stays on that point
;;;
;;; Pair mode:
;;;   entered total weight is split equally across both points
;;;
;;; V3.2 changes:
;;;   - PRODUCTION VERSION: NAME/WEIGHT written by LISP, X/Y left to block fields
;;;   - BUG FIX: nil guard on outFront after circle projection
;;;   - Undo grouping: entire RIGFLOW placement is one UNDO step
;;;   - Error handler: Escape/errors close undo mark cleanly
;;;   - Input retry loops on block type, spacing, point mode
;;;   - Summary report printed at end (records, points, range)
;;;   - PATCH: rg:get-yes-no now retries invalid input consistently
;;;   - PATCH: undo mark close is guarded with rg:undo-open flag
;;;   - PATCH: load message updated to V3.2
;;;   - FIX: outfill circle center now placed behind main front along
;;;     rear direction so main front is tangent to circumference;
;;;     rg:choose-point-on-circle refactored to accept anchor point +
;;;     direction and recompute center when radius changes
;;; ============================================================

(vl-load-com)

;;; ----------------------------
;;; USER CONFIG
;;; ----------------------------

(setq *rg-block-1t* "1T AUDIO")
(setq *rg-block-2t* "2T AUDIO")
(setq *rg-block-library* "C:/CAD/RIGBLOCKS/")
(setq *rg-debug-log* "C:/CAD/RIGFLOW_DEBUG.log")
(setq *rg-block-scale-1t* 0.08)
(setq *rg-block-scale-2t* 0.08)

;; Library blocks are assumed to be drawn in millimeters.
;; For unit-aware drawings, AutoCAD should handle the conversion.
;; For unitless drawings, fall back to meters so inserts still land at sane size.
(setq *rg-block-source-insunits* 4) ; millimeters
(setq *rg-default-target-insunits* 6) ; meters
(setq *rg-rotation* 0.0)

(setq *rg-preview-radius* 0.08)
(setq *rg-preview-color-main*   3) ; green
(setq *rg-preview-color-out*    5) ; blue
(setq *rg-preview-color-sub*    1) ; red
(setq *rg-preview-color-guide*  2) ; yellow
(setq *rg-preview-color-mirror* 6) ; magenta

(setq *rg-sub-base-offset* 2.0)
(setq *rg-sub-box-offset-default* 0.36)
(setq *rg-sub-fixed-mode* "PAIR")
(setq *rg-sub-fixed-spacing* 1.40)
(setq *rg-persistent-preview-ents* '())

;;; attribute tags inside block definitions
(setq *rg-tag-name*   "LABEL")
(setq *rg-tag-weight* "LOAD")

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

(defun rg:block-exists-p (blk)
  (and blk (tblsearch "BLOCK" blk))
)

(defun rg:fmt-real (val)
  (rtos val 2 2)
)

(defun rg:fmt-weight (val)
  (strcat (rtos val 2 0) " Kg")
)

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

(defun rg:block-source-path (blk / base path)
  (setq base (rg:ensure-trailing-slash (rg:normalize-path *rg-block-library*)))
  (if (and base blk)
    (progn
      (setq path (strcat base blk ".dwg"))
      (if (findfile path) path nil)
    )
    nil
  )
)

(defun rg:quoted-path (p)
  (strcat "\"" p "\"")
)

(defun rg:insunits->meters (code)
  (cond
    ((= code 1) 0.0254)
    ((= code 2) 0.3048)
    ((= code 3) 1609.344)
    ((= code 4) 0.001)
    ((= code 5) 0.01)
    ((= code 6) 1.0)
    ((= code 7) 1000.0)
    ((= code 8) 2.54e-8)
    ((= code 9) 2.54e-5)
    ((= code 10) 0.9144)
    ((= code 11) 1.0e-10)
    ((= code 12) 1.0e-9)
    ((= code 13) 1.0e-6)
    ((= code 14) 0.1)
    ((= code 15) 10.0)
    ((= code 16) 100.0)
    ((= code 17) 1.0e9)
    ((= code 18) 1.495978707e11)
    ((= code 19) 9.4607304725808e15)
    ((= code 20) 3.08567758149137e16)
    (T nil)
  )
)

(defun rg:insunits-label (code)
  (cond
    ((= code 0) "Unitless")
    ((= code 1) "Inches")
    ((= code 2) "Feet")
    ((= code 3) "Miles")
    ((= code 4) "Millimeters")
    ((= code 5) "Centimeters")
    ((= code 6) "Meters")
    ((= code 7) "Kilometers")
    ((= code 8) "Microinches")
    ((= code 9) "Mils")
    ((= code 10) "Yards")
    ((= code 11) "Angstroms")
    ((= code 12) "Nanometers")
    ((= code 13) "Microns")
    ((= code 14) "Decimeters")
    ((= code 15) "Decameters")
    ((= code 16) "Hectometers")
    ((= code 17) "Gigameters")
    ((= code 18) "AstronomicalUnits")
    ((= code 19) "LightYears")
    ((= code 20) "Parsecs")
    (T (strcat "Code " (itoa code)))
  )
)

(defun rg:get-target-insunits (/ drawingIns defTarget)
  (setq drawingIns (getvar "INSUNITS"))
  (if (and drawingIns (> drawingIns 0))
    drawingIns
    (progn
      (setq defTarget (getvar "INSUNITSDEFTARGET"))
      (if (and defTarget (> defTarget 0))
        defTarget
        *rg-default-target-insunits*
      )
    )
  )
)

(defun rg:get-block-object (blk / doc blocks obj)
  (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))
  (setq blocks (vla-get-Blocks doc))
  (setq obj (vl-catch-all-apply 'vla-Item (list blocks blk)))
  (if (vl-catch-all-error-p obj)
    nil
    obj
  )
)

(defun rg:get-block-units (blk / blkObj units)
  (setq blkObj (rg:get-block-object blk))
  (if (and blkObj (vlax-property-available-p blkObj 'Units))
    (progn
      (setq units (vl-catch-all-apply 'vla-get-Units (list blkObj)))
      (if (vl-catch-all-error-p units)
        nil
        units
      )
    )
    nil
  )
)

(defun rg:rig-library-block-p (blk)
  (or (= (strcase blk) (strcase *rg-block-1t*))
      (= (strcase blk) (strcase *rg-block-2t*)))
)

(defun rg:get-rig-block-scale-override (blk)
  (cond
    ((= (strcase blk) (strcase *rg-block-1t*)) *rg-block-scale-1t*)
    ((= (strcase blk) (strcase *rg-block-2t*)) *rg-block-scale-2t*)
    (T nil)
  )
)

(defun rg:get-block-insert-scale-info (blk / drawingIns defSource defTarget blockUnits targetIns srcCode srcMeters targetMeters scale msg sourceNote override)
  (setq drawingIns (getvar "INSUNITS"))
  (setq defSource (getvar "INSUNITSDEFSOURCE"))
  (setq defTarget (getvar "INSUNITSDEFTARGET"))
  (setq targetIns (rg:get-target-insunits))
  (setq blockUnits (rg:get-block-units blk))
  (setq override (rg:get-rig-block-scale-override blk))
  (if override
    (progn
      (setq msg
            (strcat
              "Using explicit rig block scale override "
              (rtos override 2 6)
              " for "
              blk
              ". Block reported units="
              (if (and blockUnits (> blockUnits 0))
                (rg:insunits-label blockUnits)
                "Unknown")
              ", drawing target units="
              (rg:insunits-label targetIns)
              "."))
      (list override msg)
    )
    (progn
      (if (rg:rig-library-block-p blk)
        (progn
          (setq srcCode *rg-block-source-insunits*)
          (setq sourceNote
                (strcat
                  "forced library units for rig block"
                  (if (and blockUnits (> blockUnits 0))
                    (strcat ", block definition reported " (rg:insunits-label blockUnits))
                    "")))
        )
        (progn
          (setq srcCode blockUnits)
          (if (or (null srcCode) (<= srcCode 0))
            (setq srcCode *rg-block-source-insunits*)
          )
          (setq sourceNote
                (if (and blockUnits (> blockUnits 0))
                  "from block definition"
                  "fallback default"))
        )
      )
      (setq srcMeters (rg:insunits->meters srcCode))
      (setq targetMeters (rg:insunits->meters targetIns))
      (if (and srcMeters targetMeters (> targetMeters 0.0))
        (progn
          (setq scale (/ srcMeters targetMeters))
          (setq msg
                (strcat
                  "Using manual block scale "
                  (rtos scale 2 6)
                  ". Block units="
                  (rg:insunits-label srcCode)
                  " ("
                  sourceNote
                  ")"
                  ", target units="
                  (rg:insunits-label targetIns)
                  ", drawing INSUNITS="
                  (itoa drawingIns)
                  ", INSUNITSDEFSOURCE="
                  (itoa defSource)
                  ", INSUNITSDEFTARGET="
                  (itoa defTarget)
                  "."))
          (list scale msg)
        )
        (list 1.0 "Could not resolve block/drawing units. Using scale 1.000000.")
      )
    )
  )
)

(defun rg:load-block-from-library-command (src blk stage / oldEcho oldAttdia oldAttreq before ent ok cmdSrc)
  (setq oldEcho   (getvar "CMDECHO"))
  (setq oldAttdia (getvar "ATTDIA"))
  (setq oldAttreq (getvar "ATTREQ"))
  (setq before (entlast))
  (setq ok nil)
  (setq cmdSrc (rg:quoted-path (rg:native-path src)))
  (setvar "CMDECHO" 0)
  (setvar "ATTDIA" 0)
  (setvar "ATTREQ" 0)
  (rg:stage stage (strcat "Trying command-line library fallback: " cmdSrc))
  (if (vl-catch-all-error-p
        (vl-catch-all-apply
    'vl-cmdf
          (list "_.-INSERT" cmdSrc "_non" "0,0,0" 1.0 1.0 0.0)))
    (rg:fail stage "Command-line fallback raised an AutoLISP command error.")
  )
  (setq ent (entlast))
  (if (and ent (/= ent before))
    (progn
      (rg:stage stage "Command fallback created a temporary insert. Deleting probe entity.")
      (entdel ent)
    )
  )
  (if (rg:block-exists-p blk)
    (setq ok T)
  )
  (setvar "ATTREQ" oldAttreq)
  (setvar "ATTDIA" oldAttdia)
  (setvar "CMDECHO" oldEcho)
  ok
)

(defun rg:ensure-block-available (blk stage / src ms ref insertSrc)
  (cond
    ((not blk)
      (rg:fail stage "No block specified.")
      nil
    )
    ((rg:block-exists-p blk)
      (rg:stage stage (strcat "Using drawing block definition: " blk))
      T
    )
    (T
      (setq src (rg:block-source-path blk))
      (if src
        (progn
          (rg:stage stage (strcat "Block missing in drawing. Trying library fallback: " src))
          (setq insertSrc (rg:native-path src))
          (setq ms (rg:get-space-object))
          (setq ref
            (vl-catch-all-apply
              'vla-InsertBlock
              (list ms (vlax-3d-point '(0.0 0.0 0.0)) insertSrc 1.0 1.0 1.0 0.0)
            )
          )
          (if (vl-catch-all-error-p ref)
            (progn
              (rg:fail stage (strcat "COM temporary insert failed. "
                                     (vl-catch-all-error-message ref)))
              (if (rg:load-block-from-library-command src blk stage)
                (progn
                  (rg:stage stage (strcat "Command fallback loaded block definition: " blk))
                  T
                )
                (progn
                  (rg:fail stage (strcat "Command fallback also failed for " src))
                  nil
                )
              )
            )
            (progn
              (if ref (vla-delete ref))
              (if (rg:block-exists-p blk)
                (progn
                  (rg:stage stage (strcat "Library fallback loaded block definition: " blk))
                  T
                )
                (progn
                  (rg:fail stage
                           (strcat
                             "Temporary insert finished, but the block definition is still unavailable. Source path: "
                             src))
                  nil
                )
              )
            )
          )
        )
        (progn
          (rg:fail stage
                   (strcat
                     "Block not found in drawing or library. Expected file: "
                     (rg:ensure-trailing-slash (rg:normalize-path *rg-block-library*))
                     blk
                     ".dwg"))
          nil
        )
      )
    )
  )
)

(defun rg:pad-int (n width / s)
  (setq s (itoa n))
  (while (< (strlen s) width)
    (setq s (strcat "0" s))
  )
  s
)

;;; ----------------------------
;;; INPUT HELPERS
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

(defun rg:get-block-by-type (stage / ans)
  (setq ans (rg:prompt-kword stage "[OneT/TwoT]" "OneT TwoT"))
  (cond
    ((or (= ans "1")
         (= ans "1T")
         (and ans (wcmatch ans "ONE*")))
      (rg:stage stage (strcat "Mapped to block " *rg-block-1t*))
      *rg-block-1t*
    )
    ((or (= ans "2")
         (= ans "2T")
         (and ans (wcmatch ans "TWO*")))
      (rg:stage stage (strcat "Mapped to block " *rg-block-2t*))
      *rg-block-2t*
    )
    (T
      (if ans
        (rg:fail stage (strcat "Unrecognized block option: " ans)))
      nil)
  )
)

(defun rg:get-spacing (stage / ans)
  (setq ans (rg:prompt-kword stage "[OneTwenty/Ninety]" "OneTwenty Ninety"))
  (cond
    ((or (= ans "1")
         (= ans "120")
         (= ans "1.20")
         (= ans "1,20")
         (and ans (wcmatch ans "ONE*")))
      1.20)
    ((or (= ans "2")
         (= ans "090")
         (= ans "0.90")
         (= ans "0,90")
         (and ans (wcmatch ans "N*")))
      0.90)
    (T
      (if ans
        (rg:fail stage (strcat "Unrecognized spacing option: " ans)))
      nil)
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

(defun rg:get-point-mode (stage label / ans)
  (setq ans (rg:prompt-kword stage (strcat label " point mode [Pair/Single]") "Pair Single"))
  (cond
    ((or (= ans "1") (= ans "P") (and ans (wcmatch ans "PAIR*"))) "PAIR")
    ((or (= ans "2") (= ans "S") (and ans (wcmatch ans "SINGLE*"))) "SINGLE")
    (T
      (if ans
        (rg:fail stage (strcat "Unrecognized point mode: " ans)))
      nil)
  )
)

(defun rg:get-direction (stage base label / mode p ang vec)
  (setq mode (rg:prompt-kword stage
                              (strcat label " direction method [Front/Angle/Back]")
                              "Front Angle Back"))

  (cond
    ((or (= mode "1") (= mode "F") (and mode (wcmatch mode "FRONT*")))
      (rg:stage stage "Waiting for a FRONT direction point.")
      (setq p (getpoint base "\nPick a point in the FRONT direction: "))
      (if p
        (setq vec (rg:vunit (rg:v- (rg:ensure3d p) (rg:ensure3d base))))
        (rg:stage stage "No front reference point selected.")
      )
    )
    ((or (= mode "2") (= mode "A") (and mode (wcmatch mode "ANGLE*")))
      (rg:stage stage "Waiting for a direction angle.")
      (setq ang (getreal "\nEnter direction angle in degrees: "))
      (if ang
        (setq vec (list (cos (rg:dtr ang)) (sin (rg:dtr ang)) 0.0))
        (rg:stage stage "No angle entered.")
      )
    )
    ((or (= mode "3") (= mode "B") (and mode (wcmatch mode "BACK*")))
      (rg:stage stage "Waiting for a BACK reference point.")
      (setq p (getpoint base "\nPick BACK point or reference: "))
      (if p
        (setq vec (rg:vunit (rg:v- (rg:ensure3d base) (rg:ensure3d p))))
        (rg:stage stage "No back reference point selected.")
      )
    )
    (T
      (if mode
        (rg:fail stage (strcat "Unrecognized direction mode: " mode))))
  )

  (if vec
    (rg:stage stage (strcat "Direction vector = " (rg:pt->str vec)))
    (if mode
      (rg:fail stage (strcat label " direction could not be determined."))
    )
  )

  vec
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

;;; ----------------------------
;;; INSERT + ATTRIBUTES
;;; ----------------------------

(defun rg:get-space-object (/ doc)
  (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))
  (if (= (getvar "CVPORT") 1)
    (vla-get-PaperSpace doc)
    (vla-get-ModelSpace doc)
  )
)

(defun rg:set-attribute-if-exists (blkRef tagName value / arr idx att)
  (if (and blkRef (= :vlax-true (vla-get-HasAttributes blkRef)))
    (progn
      (setq arr (vlax-invoke blkRef 'GetAttributes))
      (setq idx 0)
      (repeat (length arr)
        (setq att (nth idx arr))
        (if (= (strcase (vla-get-TagString att)) (strcase tagName))
          (vla-put-TextString att value)
        )
        (setq idx (1+ idx))
      )
    )
  )
)

(defun rg:insert-block-with-pointdata (blk pt pointName pointWeight stage / ms ref scaleInfo scale)
  (if (not (rg:block-exists-p blk))
    (progn
      (rg:fail stage (strcat "Block definition is not loaded: " blk))
      nil
    )
    (progn
      (setq scaleInfo (rg:get-block-insert-scale-info blk))
      (setq scale (car scaleInfo))
      (rg:stage stage (strcat "Inserting " blk " at " (rg:pt->str pt)))
      (rg:stage stage (cadr scaleInfo))
      (setq ms (rg:get-space-object))
      (setq ref
        (vl-catch-all-apply
          'vla-InsertBlock
          (list
            ms
            (vlax-3d-point (rg:ensure3d pt))
            blk
            scale
            scale
            scale
            *rg-rotation*
          )
        )
      )
      (if (vl-catch-all-error-p ref)
        (progn
          (rg:fail stage (strcat "Final block insertion failed. "
                                 (vl-catch-all-error-message ref)))
          nil
        )
        (progn
          (if pointName
            (rg:set-attribute-if-exists ref *rg-tag-name* pointName)
          )
          (if pointWeight
            (rg:set-attribute-if-exists ref *rg-tag-weight* (rg:fmt-weight pointWeight))
          )
          (rg:stage stage
                    (strcat "Inserted point "
                            pointName
                            " with load "
                            (if pointWeight (rg:fmt-weight pointWeight) "n/a")))
          ref
        )
      )
    )
  )
)

;;; ----------------------------
;;; PREVIEW HELPERS
;;; ----------------------------

(defun rg:make-preview-circle (pt rad color)
  (entmakex
    (list
      '(0 . "CIRCLE")
      (cons 10 (rg:ensure3d pt))
      (cons 40 rad)
      (cons 62 color)
    )
  )
)

(defun rg:make-preview-line (p1 p2 color)
  (entmakex
    (list
      '(0 . "LINE")
      (cons 10 (rg:ensure3d p1))
      (cons 11 (rg:ensure3d p2))
      (cons 62 color)
    )
  )
)

(defun rg:delete-entities (lst)
  (foreach e lst
    (if (and e (entget e))
      (entdel e)
    )
  )
)

(defun rg:keep-preview-entities (lst)
  (if lst
    (setq *rg-persistent-preview-ents* (append *rg-persistent-preview-ents* lst))
  )
  lst
)

(defun rg:clear-persistent-previews ()
  (if *rg-persistent-preview-ents*
    (rg:delete-entities *rg-persistent-preview-ents*)
  )
  (setq *rg-persistent-preview-ents* '())
)

(defun rg:preview-pair (front back color / ents)
  (setq ents '())
  (setq ents (cons (rg:make-preview-circle front *rg-preview-radius* color) ents))
  (setq ents (cons (rg:make-preview-circle back  *rg-preview-radius* color) ents))
  (setq ents (cons (rg:make-preview-line front back color) ents))
  ents
)

(defun rg:preview-single (pt color / ents)
  (setq ents '())
  (setq ents (cons (rg:make-preview-circle pt *rg-preview-radius* color) ents))
  ents
)

;;; ----------------------------
;;; GEOMETRY
;;; ----------------------------

(defun rg:pair-from-front-dir (front dir spacing / back)
  (setq front (rg:ensure3d front))
  (setq dir   (rg:vunit dir))
  (if (not dir)
    nil
    (progn
      (setq back (rg:v- front (rg:v* dir spacing)))
      (list front back)
    )
  )
)

(defun rg:project-point-to-circle (center radius picked / c p v)
  ;; Outfill circle picking is planar: keep the center/front Z fixed and
  ;; project only in XY so screen picks from other elevations do not skew the radius.
  (setq c (rg:ensure3d center))
  (setq p (rg:ensure3d picked))
  (setq v (rg:vunit2d (list (- (car p) (car c))
                            (- (cadr p) (cadr c))
                            0.0)))
  (if v
    (list (+ (car c) (* (car v) radius))
          (+ (cadr c) (* (cadr v) radius))
          (caddr c))
    nil
  )
)

(defun rg:choose-point-on-circle (stage anchorPt anchorDir initRadius / anchor dir2d center radius done choice circEnt pickEnt guideEnt p proj newRadius)
  ;; anchorPt stays on the circumference; center is computed as
  ;; anchorPt - anchorDir * radius, so changing radius shifts the center.
  (setq anchor (rg:ensure3d anchorPt))
  (setq dir2d  (rg:vunit2d anchorDir))
  (setq radius initRadius)
  (setq done nil)
  (setq proj nil)

  (if (not dir2d)
    (progn
      (rg:fail stage "Could not determine a planar reference direction for the outfill circle.")
      (setq done 'SKIP)
    )
  )

  (while (not done)
    (setq center (list (- (car anchor) (* (car dir2d) radius))
                       (- (cadr anchor) (* (cadr dir2d) radius))
                       (caddr anchor)))
    (if circEnt (entdel circEnt))
    (if pickEnt (entdel pickEnt))
    (if guideEnt (entdel guideEnt))
    (setq circEnt (rg:make-preview-circle center radius *rg-preview-color-guide*))
    (if proj
      (progn
        (setq pickEnt (rg:make-preview-circle proj *rg-preview-radius* *rg-preview-color-out*))
        (setq guideEnt (rg:make-preview-line center proj *rg-preview-color-guide*))
      )
    )

    (rg:stage stage
              (strcat "Preview circle center " (rg:pt->str center)
                      ", radius " (rg:fmt-real radius)
                      (if proj
                        (strcat ", selected front " (rg:pt->str proj))
                        "")))
    (if proj
      (setq choice (rg:prompt-kword stage "[Accept/Pick/Radius/Skip] <Accept>"
                                    "Accept Pick Radius Skip"))
      (setq choice (rg:prompt-kword stage "[Pick/Radius/Skip]" "Pick Radius Skip"))
    )

    (cond
      ((or (= choice "PICK") (= choice "P") (= choice "1"))
        (rg:stage stage "Waiting for approximate outfill front point.")
        (setq p (getpoint "\nPick approximate outfill front point on or near the circle: "))
        (if p
          (progn
            (setq proj (rg:project-point-to-circle center radius p))
            (if proj
              (rg:stage stage (strcat "Projected front point = " (rg:pt->str proj)))
              (rg:fail stage "Could not project the picked point to the circle.")
            )
          )
          (rg:stage stage "No outfill point selected.")
        )
      )
      ((or (null choice) (= choice "ACCEPT") (= choice "A"))
        (if proj
          (setq done (list proj radius center))
          (progn
            (if (null choice)
              (rg:stage stage "No circle action selected. Skipping outfill.")
              (rg:fail stage "No outfill front point has been picked yet."))
            (setq done 'SKIP)
          )
        )
      )
      ((or (= choice "RADIUS") (= choice "R") (= choice "2"))
        (rg:stage stage "Waiting for a new outfill radius.")
        (setq newRadius (getreal "\nEnter new outfill circle radius: "))
        (cond
          ((null newRadius)
            (rg:stage stage (strcat "Keeping radius " (rg:fmt-real radius))))
          ((<= newRadius 0.0)
            (rg:fail stage (strcat "Radius must be greater than zero. Keeping "
                                   (rg:fmt-real radius))))
          (T
            (setq radius newRadius)
            (setq proj nil)
            (rg:stage stage (strcat "Updated radius to " (rg:fmt-real radius))))
        )
      )
      ((or (null choice) (= choice "SKIP") (= choice "S") (= choice "3"))
        (if (or (= choice "SKIP") (= choice "S") (= choice "3"))
          (rg:stage stage "Outfill skipped.")
          (rg:stage stage "No circle action selected. Skipping outfill."))
        (setq done 'SKIP)
      )
    )
  )

  (if circEnt (entdel circEnt))
  (if pickEnt (entdel pickEnt))
  (if guideEnt (entdel guideEnt))
  (if (= done 'SKIP) nil done)
)

(defun rg:subpoints-from-mainfront+dir (mainFront mainDir spacing boxOffset mode / subFrontCenter axis half p1 p2 totalOffset)
  ;; Flown subs are behind main front by:
  ;;   2.0m + boxOffset
  ;; Pair mode: left/right points using spacing
  ;; Single mode: one point at center
  (setq mainFront (rg:ensure3d mainFront))
  ;; Sub placement is a plan-view offset. Keep Z fixed and use XY direction only.
  (setq mainDir   (rg:vunit2d mainDir))

  (if (not mainDir)
    nil
    (progn
      (setq totalOffset (+ *rg-sub-base-offset* boxOffset))
      (setq subFrontCenter (rg:v- mainFront (rg:v* mainDir totalOffset)))
      (setq axis (rg:perp-left mainDir))

      (if (= mode "SINGLE")
        (list subFrontCenter)
        (progn
          (setq half (/ spacing 2.0))
          (setq p1 (rg:v+ subFrontCenter (rg:v* axis (- half))))
          (setq p2 (rg:v+ subFrontCenter (rg:v* axis half)))
          ;; for subs, treat first point as "front/left logical first", second as second
          (list p1 p2)
        )
      )
    )
  )
)

(defun rg:mirror-point-across-line (pt linePt1 linePt2 / p1 p2 axis ap proj foot)
  (setq pt (rg:ensure3d pt))
  (setq p1 (rg:ensure3d linePt1))
  (setq p2 (rg:ensure3d linePt2))
  (setq axis (rg:vunit (rg:v- p2 p1)))

  (if (not axis)
    nil
    (progn
      (setq ap   (rg:v- pt p1))
      (setq proj (rg:v* axis (rg:dot ap axis)))
      (setq foot (rg:v+ p1 proj))
      (rg:v+ pt (rg:v* (rg:v- foot pt) 2.0))
    )
  )
)

(defun rg:mirror-points (pts mirrorA mirrorB / out p mp)
  (setq out '())
  (foreach p pts
    (setq mp (rg:mirror-point-across-line p mirrorA mirrorB))
    (if mp
      (setq out (append out (list mp)))
    )
  )
  out
)

;;; ----------------------------
;;; ELEMENT RECORDS
;;; record:
;;; (role side mode blk pts totalWeight color)
;;; role: "MAIN" / "OUT" / "SUB"
;;; side: "L" / "R"
;;; mode: "PAIR" / "SINGLE"
;;; pts : list of points, ordered as intended for numbering
;;; ----------------------------

(defun rg:make-record (role side mode blk pts totalWeight color)
  (list role side mode blk pts totalWeight color)
)

(defun rg:rec-role   (r) (nth 0 r))
(defun rg:rec-side   (r) (nth 1 r))
(defun rg:rec-mode   (r) (nth 2 r))
(defun rg:rec-blk    (r) (nth 3 r))
(defun rg:rec-pts    (r) (nth 4 r))
(defun rg:rec-wt     (r) (nth 5 r))
(defun rg:rec-color  (r) (nth 6 r))

(defun rg:preview-record (rec / pts color ents)
  (setq pts   (rg:rec-pts rec))
  (setq color (rg:rec-color rec))
  (setq ents '())

  (rg:append-log
    (strcat
      "PREVIEW | "
      (rg:rec-role rec) " " (rg:rec-side rec) " " (rg:rec-mode rec)
      " | PT1=" (rg:pt->str (nth 0 pts))
      (if (> (length pts) 1)
        (strcat " | PT2=" (rg:pt->str (nth 1 pts)))
        "")
    )
  )

  (if (= (rg:rec-mode rec) "PAIR")
    (setq ents (append ents (rg:preview-pair (nth 0 pts) (nth 1 pts) color)))
    (setq ents (append ents (rg:preview-single (nth 0 pts) color)))
  )

  ents
)

(defun rg:mirror-record (rec mirrorA mirrorB / mpts)
  (setq mpts (rg:mirror-points (rg:rec-pts rec) mirrorA mirrorB))
  (if (= (length mpts) (length (rg:rec-pts rec)))
    (rg:make-record
      (rg:rec-role rec)
      "R"
      (rg:rec-mode rec)
      (rg:rec-blk rec)
      mpts
      (rg:rec-wt rec)
      *rg-preview-color-mirror*
    )
    nil
  )
)

;;; ----------------------------
;;; SORT / NUMBER / INSERT
;;; ----------------------------

(defun rg:role-rank (role)
  (cond
    ((= role "MAIN") 1)
    ((= role "OUT")  2)
    ((= role "SUB")  3)
    (T 99)
  )
)

(defun rg:side-rank (side)
  (cond
    ((= side "L") 1)
    ((= side "R") 2)
    (T 99)
  )
)

(defun rg:record< (a b / ra rb sa sb)
  (setq ra (rg:role-rank (rg:rec-role a)))
  (setq rb (rg:role-rank (rg:rec-role b)))
  (setq sa (rg:side-rank (rg:rec-side a)))
  (setq sb (rg:side-rank (rg:rec-side b)))

  (or (< ra rb)
      (and (= ra rb) (< sa sb)))
)

(defun rg:sort-records (lst / changed out a b rest)
  ;; simple bubble-ish sort, because AutoLISP enjoys primitive rituals
  (setq out lst)
  (setq changed T)
  (while changed
    (setq changed nil)
    (setq rest out)
    (setq out '())
    (while (> (length rest) 1)
      (setq a (car rest))
      (setq b (cadr rest))
      (if (rg:record< a b)
        (progn
          (setq out (append out (list a)))
          (setq rest (cdr rest))
        )
        (progn
          (setq out (append out (list b)))
          (setq rest (append (list a) (cddr rest)))
          (setq changed T)
        )
      )
    )
    (if (= (length rest) 1)
      (setq out (append out rest))
    )
  )
  out
)

(defun rg:place-record-with-numbering (rec prefix idx width / pts wt perPt nm stage)
  (setq pts (rg:rec-pts rec))
  (setq wt  (rg:rec-wt rec))
  (setq stage (strcat "INSERT > " (rg:rec-role rec) " " (rg:rec-side rec)))

  (if (= (rg:rec-mode rec) "PAIR")
    (setq perPt (/ wt 2.0))
    (setq perPt wt)
  )

  (foreach p pts
    (setq nm (strcat prefix (rg:pad-int idx width)))
    (rg:stage stage
              (strcat "Preparing " nm
                      " at " (rg:pt->str p)
                      " with load " (rg:fmt-weight perPt)))
    (rg:insert-block-with-pointdata (rg:rec-blk rec) p nm perPt stage)
    (setq idx (1+ idx))
  )

  idx
)

;;; ----------------------------
;;; COLLECTORS
;;; ----------------------------

(defun rg:collect-main (prefixColor / mode front blk spacing dir wt pts rec preview ok)
  (setq rec nil)
  (setq mode (rg:get-point-mode "MAIN > MODE" "MAIN"))
  (if mode
    (progn
      (rg:stage "MAIN > FRONT" "Waiting for MAIN front point.")
      (setq front (getpoint "\nPick MAIN front point: "))
      (if front
        (progn
          (setq front (rg:ensure3d front))
          (rg:stage "MAIN > FRONT" (strcat "Front point = " (rg:pt->str front)))
          (setq blk (rg:get-block-by-type "MAIN > BLOCK"))
          (cond
            ((null blk)
              (rg:stage "MAIN > BLOCK" "MAIN block selection canceled."))
            ((not (rg:ensure-block-available blk "MAIN > LOAD BLOCK"))
              (rg:fail "MAIN > LOAD BLOCK" (strcat "MAIN block unavailable: " blk)))
            (T
              (setq wt (rg:get-positive-real "MAIN > WEIGHT" "Enter TOTAL weight for MAIN element"))
              (if wt
                (progn
                  (if (= mode "PAIR")
                    (progn
                      (setq spacing (rg:get-spacing "MAIN > SPACING"))
                      (setq dir (rg:get-direction "MAIN > DIRECTION" front "MAIN"))
                      (if (and spacing dir)
                        (setq pts (rg:pair-from-front-dir front dir spacing))
                        (rg:fail "MAIN > GEOMETRY"
                                 "Could not compute MAIN pair from spacing and direction.")
                      )
                    )
                    (setq pts (list front))
                  )
                  (if pts
                    (progn
                       (setq rec (rg:make-record "MAIN" "L" mode blk pts wt prefixColor))
                       (rg:stage "MAIN > PREVIEW"
                                 (strcat "Previewing " (itoa (length pts)) " MAIN point(s)."))
                       (setq preview (rg:preview-record rec))
                       (setq ok (rg:confirm-place "MAIN > PREVIEW"))
                       (if ok
                         (progn
                           (rg:keep-preview-entities preview)
                           (rg:stage "MAIN > PREVIEW" "MAIN preview accepted and kept visible."))
                         (progn
                           (rg:delete-entities preview)
                           (setq rec nil)
                           (rg:stage "MAIN > PREVIEW" "MAIN placement canceled."))
                       )
                       (if (not ok)
                         (progn
                           (setq rec nil)
                         )
                       )
                     )
                     (rg:fail "MAIN > GEOMETRY" "Could not build MAIN geometry.")
                   )
                )
              )
            )
          )
        )
        (rg:stage "MAIN > FRONT" "No MAIN front point selected.")
      )
    )
  )
  rec
)

(defun rg:collect-out (mainFront mainDir prefixColor / addOut mode outChoice outFront outCenter outRadius blk spacing dir wt pts rec preview ok)
  (setq rec nil)
  (setq addOut (rg:get-yes-no "OUTFILL > ENABLE" "Add outfill"))
  (if addOut
    (progn
      (setq mode (rg:get-point-mode "OUTFILL > MODE" "OUTFILL"))
      (if mode
        (progn
          (setq outRadius (rg:get-real-default "OUTFILL > RADIUS"
                                               "Enter initial outfill circle radius"
                                               2.00))
          (setq outChoice (rg:choose-point-on-circle "OUTFILL > CIRCLE" mainFront mainDir outRadius))
          (if outChoice
            (progn
              (setq outFront (car outChoice))
              (setq outRadius (cadr outChoice))
              (setq outCenter (caddr outChoice))
              (rg:stage "OUTFILL > FRONT" (strcat "Outfill front point = " (rg:pt->str outFront)))
              (setq blk (rg:get-block-by-type "OUTFILL > BLOCK"))
              (cond
                ((null blk)
                  (rg:stage "OUTFILL > BLOCK" "OUTFILL block selection canceled."))
                ((not (rg:ensure-block-available blk "OUTFILL > LOAD BLOCK"))
                  (rg:fail "OUTFILL > LOAD BLOCK" (strcat "OUTFILL block unavailable: " blk)))
                (T
                  (setq wt (rg:get-positive-real "OUTFILL > WEIGHT"
                                                 "Enter TOTAL weight for OUTFILL element"))
                  (if wt
                    (progn
                      (if (= mode "PAIR")
                        (progn
                          (setq spacing (rg:get-spacing "OUTFILL > SPACING"))
                          (if spacing
                            (progn
                              (setq dir (rg:vunit2d (rg:v- outFront outCenter)))
                              (if dir
                                (rg:stage "OUTFILL > DIRECTION"
                                          (strcat
                                            "Using radial direction from circle center "
                                            (rg:pt->str outCenter)
                                            " so the rear point goes back toward the center in plan."))
                                (rg:fail "OUTFILL > DIRECTION"
                                         "Could not derive a radial direction from the picked outfill point."))
                            )
                            (rg:fail "OUTFILL > SPACING" "No outfill spacing selected.")
                          )
                          (if (and spacing dir)
                            (progn
                              (setq pts (rg:pair-from-front-dir outFront dir spacing))
                              (rg:stage "OUTFILL > GEOMETRY"
                                        (strcat
                                          "Center=" (rg:pt->str outCenter)
                                          ", front=" (rg:pt->str outFront)
                                          ", rear=" (rg:pt->str (nth 1 pts)))))
                            (rg:fail "OUTFILL > GEOMETRY"
                                     "Could not compute OUTFILL pair from spacing and direction.")
                          )
                        )
                        (setq pts (list (rg:ensure3d outFront)))
                      )
                      (if pts
                        (progn
                          (setq rec (rg:make-record "OUT" "L" mode blk pts wt prefixColor))
                          (rg:stage "OUTFILL > PREVIEW"
                                    (strcat "Previewing " (itoa (length pts)) " OUTFILL point(s)."))
                          (setq preview (rg:preview-record rec))
                          (setq ok (rg:confirm-place "OUTFILL > PREVIEW"))
                          (if ok
                            (progn
                              (rg:keep-preview-entities preview)
                              (rg:stage "OUTFILL > PREVIEW" "OUTFILL preview accepted and kept visible."))
                            (progn
                              (rg:delete-entities preview)
                              (setq rec nil)
                              (rg:stage "OUTFILL > PREVIEW" "OUTFILL placement canceled."))
                          )
                          (if (not ok)
                            (progn
                              (setq rec nil)
                            )
                          )
                        )
                        (rg:fail "OUTFILL > GEOMETRY" "Could not build OUTFILL geometry.")
                      )
                    )
                  )
                )
              )
            )
            (rg:stage "OUTFILL > CIRCLE" "No OUTFILL geometry chosen.")
          )
        )
      )
    )
  )
  rec
)

(defun rg:collect-sub (mainFront mainDir prefixColor / addSub mode boxOffset blk spacing wt pts rec preview ok)
  (setq rec nil)
  (setq addSub (rg:get-yes-no "SUBS > ENABLE" "Add flown subs"))
  (if addSub
    (progn
      (setq mode *rg-sub-fixed-mode*)
      (rg:stage "SUBS > MODE"
                (strcat "Using fixed FLOWN SUB mode " mode "."))
      (if mode
        (progn
          (setq boxOffset (rg:get-real-default "SUBS > OFFSET"
                                               "Enter extra box offset for flown subs"
                                               *rg-sub-box-offset-default*))
          (setq blk (rg:get-block-by-type "SUBS > BLOCK"))
          (cond
            ((null blk)
              (rg:stage "SUBS > BLOCK" "FLOWN SUB block selection canceled."))
            ((not (rg:ensure-block-available blk "SUBS > LOAD BLOCK"))
              (rg:fail "SUBS > LOAD BLOCK" (strcat "FLOWN SUB block unavailable: " blk)))
            (T
              (setq wt (rg:get-positive-real "SUBS > WEIGHT"
                                             "Enter TOTAL weight for FLOWN SUB element"))
              (if wt
                (progn
                  (if (= mode "PAIR")
                    (progn
                      (setq spacing *rg-sub-fixed-spacing*)
                      (rg:stage "SUBS > SPACING"
                                (strcat "Using fixed FLOWN SUB spacing "
                                        (rg:fmt-real spacing)
                                        "."))
                      (setq pts (rg:subpoints-from-mainfront+dir mainFront mainDir spacing boxOffset mode))
                    )
                    (setq pts (rg:subpoints-from-mainfront+dir mainFront mainDir 0.0 boxOffset mode))
                  )
                  (if pts
                    (progn
                      (setq rec (rg:make-record "SUB" "L" mode blk pts wt prefixColor))
                      (rg:stage "SUBS > PREVIEW"
                                (strcat "Previewing " (itoa (length pts)) " FLOWN SUB point(s)."))
                      (setq preview (rg:preview-record rec))
                      (if (> (length pts) 0)
                        (setq preview (append preview (list (rg:make-preview-line mainFront (nth 0 pts) *rg-preview-color-guide*))))
                      )
                      (setq ok (rg:confirm-place "SUBS > PREVIEW"))
                      (if ok
                        (progn
                          (rg:keep-preview-entities preview)
                          (rg:stage "SUBS > PREVIEW" "FLOWN SUB preview accepted and kept visible."))
                        (progn
                          (rg:delete-entities preview)
                          (setq rec nil)
                          (rg:stage "SUBS > PREVIEW" "FLOWN SUB placement canceled."))
                      )
                      (if (not ok)
                        (progn
                          (setq rec nil)
                        )
                      )
                    )
                    (rg:fail "SUBS > GEOMETRY" "Could not build FLOWN SUB geometry.")
                  )
                )
              )
            )
          )
        )
      )
    )
  )
  rec
)

;;; ----------------------------
;;; MAIN COMMAND
;;; ----------------------------

(defun c:RIGFLOW
  (/ prefix startNum startNumSave width
     allRecs sortedRecs
     mainRec outRec subRec
     addMirror mirrorA mirrorB mirrorRecs mrec preview ok rec
     mainFront mainDir
     oldErr totalPts rg:undo-open)

  ;; --- error handler: undo everything on Escape/error ---
  (setq oldErr *error*)
  (defun *error* (msg)
    (if (not (wcmatch (strcase msg) "*CANCEL*,*QUIT*"))
      (rg:fail "ERROR" msg)
      (rg:stage "CANCEL" "RIGFLOW canceled by user.")
    )
    (rg:clear-persistent-previews)
    (if rg:undo-open
      (progn
        (vla-EndUndoMark (vla-get-ActiveDocument (vlax-get-acad-object)))
        (setq rg:undo-open nil)
      )
    )
    (setq *error* oldErr)
    (princ)
  )

  (vla-StartUndoMark (vla-get-ActiveDocument (vlax-get-acad-object)))
  (setq rg:undo-open T)
  (rg:clear-persistent-previews)

  (rg:append-log "----- RIGFLOW RUN START -----")
  (setq allRecs '())

  (rg:stage "SETUP" "RIGFLOW - point-based naming, left-to-right numbering.")

  ;; numbering seed
  (setq prefix (rg:get-string-default "SETUP > PREFIX" "Enter point name prefix" "SX"))
  (setq startNum (rg:get-int-default "SETUP > START NUMBER" "Enter starting point number" 1))
  (setq startNumSave startNum)

  (setq width 2)

  ;; MAIN
  (setq mainRec (rg:collect-main *rg-preview-color-main*))
  (if (null mainRec)
    (progn
      (rg:fail "MAIN" "Main canceled or invalid. Nothing was placed.")
      (rg:clear-persistent-previews)
      (princ)
    )
    (progn
      (setq allRecs (append allRecs (list mainRec)))

      ;; capture main front + direction basis for downstream logic
      (setq mainFront (nth 0 (rg:rec-pts mainRec)))
      (if (= (rg:rec-mode mainRec) "PAIR")
        (progn
          (setq mainDir (rg:vunit (rg:v- (nth 0 (rg:rec-pts mainRec)) (nth 1 (rg:rec-pts mainRec)))))
          (if mainDir
            (rg:stage "REFERENCE > DIRECTION"
                      (strcat "Using MAIN pair direction " (rg:pt->str mainDir)))
            (rg:fail "REFERENCE > DIRECTION" "Could not derive direction from the MAIN pair."))
        )
        ;; single main has no inherent pair direction, so ask for a reference direction for out/sub logic
        (setq mainDir (rg:get-direction "REFERENCE > DIRECTION"
                                        mainFront
                                        "REFERENCE FOR OUTFILL/SUB POSITIONING"))
      )

      (if (null mainDir)
        (progn
          (rg:fail "REFERENCE > DIRECTION" "Could not determine main/reference direction.")
          (rg:clear-persistent-previews)
          (princ)
        )
        (progn
          ;; OUTFILL
          (setq outRec (rg:collect-out mainFront mainDir *rg-preview-color-out*))
          (if outRec
            (setq allRecs (append allRecs (list outRec)))
          )

          ;; SUBS
          (setq subRec (rg:collect-sub mainFront mainDir *rg-preview-color-sub*))
          (if subRec
            (setq allRecs (append allRecs (list subRec)))
          )

          ;; MIRROR
          (setq addMirror (rg:get-yes-no "MIRROR > ENABLE" "Mirror complete rig at end"))
          (if addMirror
            (progn
              (rg:stage "MIRROR > LINE" "Waiting for first mirror point.")
              (setq mirrorA (getpoint "\nPick first point of mirror centerline: "))
              (if mirrorA
                (progn
                  (setq mirrorA (rg:ensure3d mirrorA))
                  (rg:stage "MIRROR > LINE" (strcat "First mirror point = " (rg:pt->str mirrorA))))
                (rg:stage "MIRROR > LINE" "No first mirror point selected.")
              )
              (setq mirrorB
                    (if mirrorA
                      (progn
                        (rg:stage "MIRROR > LINE" "Waiting for second mirror point.")
                        (getpoint mirrorA "\nPick second point of mirror centerline: "))
                      nil))
              (if mirrorB
                (progn
                  (setq mirrorB (rg:ensure3d mirrorB))
                  (rg:stage "MIRROR > LINE" (strcat "Second mirror point = " (rg:pt->str mirrorB))))
                (rg:stage "MIRROR > LINE" "No second mirror point selected.")
              )

              (if (and mirrorA mirrorB)
                (progn
                  (rg:stage "MIRROR > BUILD" "Building mirrored preview records.")
                  (setq mirrorRecs '())
                  (foreach rec allRecs
                    (setq mrec (rg:mirror-record rec mirrorA mirrorB))
                    (if mrec
                      (setq mirrorRecs (append mirrorRecs (list mrec)))
                    )
                  )

                  (setq preview '())
                  (foreach rec mirrorRecs
                    (setq preview (append preview (rg:preview-record rec)))
                  )

                  (if (> (length preview) 0)
                    (progn
                      (setq ok (rg:confirm-place "MIRROR > PREVIEW"))
                      (if ok
                        (progn
                          (rg:keep-preview-entities preview)
                          (setq allRecs (append allRecs mirrorRecs))
                          (rg:stage "MIRROR > PREVIEW" "Mirror accepted and kept visible."))
                        (progn
                          (rg:delete-entities preview)
                          (rg:stage "MIRROR > PREVIEW" "Mirror canceled."))
                      )
                    )
                    (rg:fail "MIRROR > PREVIEW" "No mirrored preview entities were created.")
                  )
                )
                (rg:fail "MIRROR > LINE" "Invalid mirror line. Mirror skipped.")
              )
            )
          )

          ;; SORT FOR FINAL L-R NUMBERING
          (rg:stage "NUMBERING > SORT" "Sorting records in logical role/side order.")
          (setq sortedRecs (rg:sort-records allRecs))

          ;; FINAL INSERT WITH POINT NUMBERING
          (rg:stage "NUMBERING > PREVIEW" "Clearing accepted preview geometry before final insertion.")
          (rg:clear-persistent-previews)
          (rg:stage "NUMBERING > INSERT" "Starting final block insertion.")
          (foreach rec sortedRecs
            (setq startNum (rg:place-record-with-numbering rec prefix startNum width))
          )

          ;; SUMMARY
          (setq totalPts (- startNum startNumSave))
          (rg:msg (strcat "\n\n--- RIGFLOW SUMMARY ---"))
          (rg:msg (strcat "\n  Records placed: " (itoa (length sortedRecs))))
          (rg:msg (strcat "\n  Total points:   " (itoa totalPts)))
          (rg:msg (strcat "\n  Numbering:      " prefix (rg:pad-int startNumSave width)
                          " .. " prefix (rg:pad-int (1- startNum) width)))
          (foreach rec sortedRecs
            (rg:msg (strcat "\n  " (rg:rec-role rec) " " (rg:rec-side rec)
                            " [" (rg:rec-mode rec) "] "
                            (itoa (length (rg:rec-pts rec))) "pt "
                            (rg:fmt-weight (rg:rec-wt rec))))
          )
          (rg:msg "\n-----------------------")
          (rg:msg "\nRIGFLOW complete. Use UNDO to reverse entire placement.")
        )
      )
    )
  )

  (if rg:undo-open
    (progn
      (vla-EndUndoMark (vla-get-ActiveDocument (vlax-get-acad-object)))
      (setq rg:undo-open nil)
    )
  )
  (setq *error* oldErr)
  (princ)
)

(princ "\nLoaded RIGFLOW_AUDIO_V3.5.6_PRELOADED_BLOCKS (hybrid fallback + debug prompts).")
(rg:append-log "Loaded RIGFLOW_AUDIO_V3.5.6_PRELOADED_BLOCKS (hybrid fallback + debug prompts).")
(princ "\nCommand available: RIGFLOW")
(princ)
