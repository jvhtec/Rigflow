;;; ============================================================
;;; RIG_PREVIEW.LSP - Temporary Preview Graphics
;;; Module 4 of 9 | Load order: 4
;;; Dependencies: rig_config.lsp, rig_utils.lsp
;;; Part of RigFlow v3.5.6 modular
;;;
;;; Contains: preview circle/line creation, preview lifecycle
;;;           management, pair/single preview helpers.
;;; ============================================================

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

(princ)
