;;; ============================================================
;;; RIG_COLLECTORS.LSP - User-Interactive Collection of Rig Elements
;;; Module 8 of 9 | Load order: 8
;;; Dependencies: rig_config.lsp, rig_utils.lsp, rig_blocks.lsp,
;;;               rig_preview.lsp, rig_geometry.lsp, rig_records.lsp
;;; Part of RigFlow v3.5.6 modular
;;;
;;; Contains: rig-specific input helpers (block type, spacing,
;;;           point mode, direction) and the three collector
;;;           functions (main, outfill, flown subs).
;;; ============================================================

;;; ----------------------------
;;; RIG-SPECIFIC INPUT HELPERS
;;; ----------------------------

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

(princ)
