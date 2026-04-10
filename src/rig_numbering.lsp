;;; ============================================================
;;; RIG_NUMBERING.LSP - Sorting, Numbering, and Final Insertion
;;; Module 7 of 9 | Load order: 7
;;; Dependencies: rig_config.lsp, rig_utils.lsp, rig_blocks.lsp,
;;;               rig_records.lsp
;;; Part of RigFlow v3.5.6 modular
;;;
;;; Contains: role/side ranking, record sorting, final point
;;;           numbering, and block insertion pass.
;;; ============================================================

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
      (cond
        ((rg:record< a b)
          ;; a belongs before b: emit a, advance
          (setq out (append out (list a)))
          (setq rest (cdr rest))
        )
        ((rg:record< b a)
          ;; b belongs before a: swap, keep a in rest for further comparison
          (setq out (append out (list b)))
          (setq rest (append (list a) (cddr rest)))
          (setq changed T)
        )
        (T
          ;; equal records: treat as stable, emit a and advance
          (setq out (append out (list a)))
          (setq rest (cdr rest))
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

(princ)
