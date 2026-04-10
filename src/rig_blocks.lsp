;;; ============================================================
;;; RIG_BLOCKS.LSP - Block Validation, Insertion, and Attributes
;;; Module 3 of 9 | Load order: 3
;;; Dependencies: rig_config.lsp, rig_utils.lsp
;;; Part of RigFlow v3.5.6 modular
;;;
;;; Contains: block existence checks, unit conversion, block
;;;           loading from library, insertion, attribute writing.
;;; ============================================================

;;; ----------------------------
;;; BLOCK EXISTENCE
;;; ----------------------------

(defun rg:block-exists-p (blk)
  (and blk (tblsearch "BLOCK" blk))
)

;;; ----------------------------
;;; BLOCK PATH HELPERS
;;; ----------------------------

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

;;; ----------------------------
;;; UNIT CONVERSION
;;; ----------------------------

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

;;; ----------------------------
;;; BLOCK OBJECT / SCALING
;;; ----------------------------

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

;;; ----------------------------
;;; BLOCK LOADING
;;; ----------------------------

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
                            (if pointName pointName "n/a")
                            " with load "
                            (if pointWeight (rg:fmt-weight pointWeight) "n/a")))
          ref
        )
      )
    )
  )
)

(princ)
