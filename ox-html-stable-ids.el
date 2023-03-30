(defun org-html-stable-ids-add ()
  (interactive)
  (advice-add #'org-export-get-reference :override #'org-html-stable-ids--get-reference))

(defun org-html-stable-ids-remove ()
  (interactive)
  (advice-remove #'org-export-get-reference #'org-html-stable-ids--get-reference))

(defun org-html-stable-ids--to-kebab-case (string)
  (string-trim
   (replace-regexp-in-string "[^a-z0-9]+" "-"
                             (downcase string))
   "-" "-"))

(defun org-html-stable-ids--get-reference (datum info)
  (let ((cache (plist-get info :internal-references)))
    (let ((id (org-html-stable-ids--to-kebab-case
	       (org-element-property :raw-value datum))))
      (or (rassq datum cache)
	  (if (assoc id cache)
	      (user-error "Duplicate ID: %s" id)
	    (push (cons id datum) cache)
	    (plist-put info :internal-references cache)
	    id)))))
