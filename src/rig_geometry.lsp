;;; ============================================================
;;; RIG_GEOMETRY.LSP - Coordinate and Geometry Logic
;;; Module 5 of 9 | Load order: 5
;;; Dependencies: rig_config.lsp, rig_utils.lsp, rig_preview.lsp
;;; Part of RigFlow v3.5.6 modular
;;;
;;; Contains: pair generation, circle projection, outfill circle
;;;           picking, sub positioning, point mirroring.
;;; ============================================================

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

  ;; Validate initRadius before creating any preview geometry
  (if (or (null radius) (<= radius 0.0))
    (progn
      (rg:fail stage
               (strcat "Invalid initial radius: "
                       (if radius (rg:fmt-real radius) "nil")
                       ". Must be a positive number."))
      (setq done 'SKIP)
    )
  )

  (if (and (not done) (not dir2d))
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

(princ)
