;;; org-stealth.el --- A minor mode to clean org-mode.

;;; Commentary:
;;

(require 'org)
(require 'org-element)
(require 'dash)

;;; Code:

(defgroup org-tidy nil
  "Give you a clean org-mode buffer."
  :prefix "org-tidy-"
  :group 'convenience)

(defcustom org-tidy-properties-style 'inline
  "If non-nil, add text properties to the region markers."
  :group 'org-tidy
  :type '(choice
          (const :tag "Only show fringe bitmap" fringe)
          (const :tag "Only show inline symbol" inline)
          (const :tag "Show nothing" nothing)))

(defvar-local org-tidy-properties-symbol "♯"
  "Variable to store the regions we put an overlay on.")

(defcustom org-tidy-src-block t
  "If non-nil, add text properties to the region markers."
  :type 'boolean
  :group 'org-tidy)

(defvar-local org-tidy-overlays nil
  "Variable to store the regions we put an overlay on.")

(defvar-local org-tidy-overlays-properties nil
  "Variable to store the regions we put an overlay on.")

(define-fringe-bitmap
  'org-tidy-fringe-bitmap-sharp
  [#b00010010
   #b00010010
   #b11111111
   #b00100100
   #b00100100
   #b11111110
   #b01001000
   #b01001000])

(defun org-tidy-overlay-properties (beg end)
  "Hides a region by making an invisible overlay over it."
  (interactive)
  (unless (assoc (list beg end) org-tidy-overlays)
    (let* ((ov nil))
      (pcase org-tidy-properties-style
        ('inline
          (let* ((real-beg (- beg 1)) (real-end (- end 1))
                 (new-overlay (make-overlay real-beg real-end nil t nil)))
            (overlay-put new-overlay 'display " ♯")
            (overlay-put new-overlay 'invisible t)
            (setf ov new-overlay)))

        ('fringe
         (let* ((real-beg (1- beg)) (real-end (1- end))
                (new-overlay (make-overlay real-beg real-end)))
           (overlay-put new-overlay 'display
                        '(left-fringe org-tidy-fringe-bitmap-sharp))
           (overlay-put new-overlay 'invisible t)
           (setf ov new-overlay))))

      (push (cons (list beg end) ov) org-tidy-overlays))))


(defun org-tidy-properties-single (element)
  (-let* (((type props content) element)
          ((&plist :begin begin :end end) props))
    (message "beg:%s end:%s" begin end)
    (org-tidy-overlay-properties begin end)))

(defun org-tidy-properties ()
  "Tidy drawers."
  (interactive)
  (save-excursion
    (let* ((res (org-element-map (org-element-parse-buffer)
                    'property-drawer #'org-tidy-properties-single)))
      res
      )))

(defun org-tidy-overlay-end-src (beg end)
  "Hides a region by making an invisible overlay over it."
  (interactive)
  (unless (assoc (list beg end) org-tidy-overlays)
    (let ((new-overlay (make-overlay beg end)))
      (overlay-put new-overlay 'invisible t)
      (overlay-put new-overlay 'display "☰")
      (push (cons (list beg end) new-overlay) org-tidy-overlays))))

(defun org-tidy-overlay-begin-src (beg end)
  "Hides a region by making an invisible overlay over it."
  (interactive)
  (unless (assoc (list beg end) org-tidy-overlays)
    (let ((new-overlay (make-overlay beg end)))
      (overlay-put new-overlay 'invisible t)
      (overlay-put new-overlay 'display "☰")
      (push (cons (list beg end) new-overlay) org-tidy-overlays))))

(defun org-tidy-src-single (src)
  (let* ((pl (cadr src))
         (begin (plist-get pl :begin))
         (end-src-beg (progn
                        (goto-char begin)
                        (goto-char (line-end-position))
                        (forward-char)
                        (+ (length (plist-get pl :value)) (point))))
         (end (progn (goto-char end-src-beg)
                     (goto-char (line-end-position))
                     (point)))
         )
    (list :begin begin :end-src-beg end-src-beg :end end)))



(defun org-tidy-src ()
  "Tidy source blocks."
  (interactive)
  (save-excursion
    (let* ((res (org-element-map (org-element-parse-buffer)
                    'src-block #'org-tidy-src-single)))
      (mapcar (lambda (item)
                (let* ((end-src-beg (plist-get item :end-src-beg))
                       (end (plist-get item :end))
                       (begin (plist-get item :begin)))
                  (org-tidy-overlay-end-src end-src-beg end)
                  (org-tidy-overlay-begin-src begin (+ 11 begin))))
              res)
      )))

(defun org-untidy ()
  "Untidy."
  (interactive)
  (while org-tidy-overlays
    (let* ((ov (cdar org-tidy-overlays)))
      (message "ov:%s" ov)
      (delete-overlay ov)
      (setf org-tidy-overlays (cdr org-tidy-overlays)))))

(defun org-tidy ()
  "Tidy."
  (interactive)
  ;; (save-excursion
  ;;   (goto-char (point-min))
  ;;   (while (re-search-forward org-property-drawer-re nil t)
  ;;       (let* ((beg (match-beginning 0))
  ;;              (end (1+ (match-end 0))))
  ;;         (org-tidy-hide beg end))))
  )

(provide 'org-tidy)

;;; org-tidy.el ends here
