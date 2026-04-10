;;; ============================================================
;;; RIG_CONFIG.LSP - RigFlow Configuration Constants
;;; Module 1 of 9 | Load order: 1
;;; Dependencies: none
;;; Part of RigFlow v3.5.6 modular
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

(princ)
