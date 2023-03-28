(defun org-html-stable-ids-add ()
  (interactive)
  (advice-add #'org-export-get-reference :override #'org-html-stable-ids--get-reference))

(defun org-html-stable-ids-remove ()
  (interactive)
  (advice-remove #'org-export-get-reference #'org-html-stable-ids--get-reference))

(defun org-html-stable-ids--get-reference (datum info)
  "hello-world")
