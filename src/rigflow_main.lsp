;;; ============================================================
;;; RIGFLOW_MAIN.LSP - Entry Point and Module Loader
;;; Module 9 of 9 | Load order: 9 (loads all others first)
;;; Dependencies: all other modules (loaded by this file)
;;; Part of RigFlow v3.5.6 modular
;;;
;;; This is the only file that should be added to the
;;; AutoCAD Startup Suite. It loads all required modules
;;; and defines the c:RIGFLOW command.
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
;;; ============================================================

;;; ----------------------------
;;; MODULE LOADER
;;; ----------------------------

(defun rg:get-module-dir (/ scriptPath dir)
  ;; Determine the directory containing this file by searching
  ;; the AutoCAD support file search path for rigflow_main.lsp.
  (setq scriptPath (findfile "rigflow_main.lsp"))
  (if scriptPath
    (progn
      (setq dir (vl-filename-directory scriptPath))
      (if (and dir (> (strlen dir) 0))
        ;; Normalize to forward slashes and ensure trailing slash
        (progn
          (setq dir (vl-string-translate "\\" "/" dir))
          (if (/= (substr dir (strlen dir) 1) "/")
            (strcat dir "/")
            dir
          )
        )
        "./"
      )
    )
    "./"
  )
)

(defun rg:load-module (dir filename / fullpath)
  (setq fullpath (strcat dir filename))
  (if (findfile fullpath)
    (progn
      (load fullpath)
      (princ (strcat "\n  Loaded " filename))
      T
    )
    (progn
      (princ (strcat "\n  ERROR: Module not found: " fullpath))
      nil
    )
  )
)

(defun rg:load-all-modules (/ dir ok)
  (setq dir (rg:get-module-dir))
  (setq ok T)
  (princ "\nRIGFLOW: Loading modules...")
  (foreach mod '("rig_config.lsp"
                 "rig_utils.lsp"
                 "rig_blocks.lsp"
                 "rig_preview.lsp"
                 "rig_geometry.lsp"
                 "rig_records.lsp"
                 "rig_numbering.lsp"
                 "rig_collectors.lsp")
    (if (not (rg:load-module dir mod))
      (setq ok nil)
    )
  )
  (if ok
    (princ "\nRIGFLOW: All modules loaded successfully.")
    (princ "\nRIGFLOW: WARNING - Some modules failed to load! Check paths above.")
  )
  ok
)

;;; Load all modules on file load
(rg:load-all-modules)

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

;;; ----------------------------
;;; LOAD BANNER
;;; ----------------------------

(princ "\nLoaded RIGFLOW v3.5.6 modular (9-file structure).")
(rg:append-log "Loaded RIGFLOW v3.5.6 modular (9-file structure).")
(princ "\nCommand available: RIGFLOW")
(princ)
