;;; ============================================================
;;; RIG_RECORDS.LSP - Internal Record Structure
;;; Module 6 of 9 | Load order: 6
;;; Dependencies: rig_config.lsp, rig_utils.lsp, rig_preview.lsp,
;;;               rig_geometry.lsp
;;; Part of RigFlow v3.5.6 modular
;;;
;;; Contains: record constructors, accessors, preview wrappers,
;;;           and record mirroring.
;;;
;;; Record structure:
;;;   (role side mode blk pts totalWeight color)
;;;   role: "MAIN" / "OUT" / "SUB"
;;;   side: "L" / "R"
;;;   mode: "PAIR" / "SINGLE"
;;;   pts : list of points, ordered as intended for numbering
;;; ============================================================

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

(princ)
