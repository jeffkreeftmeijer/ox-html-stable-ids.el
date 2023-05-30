;;; ox-html-stable-ids.el -- Stable IDs for ox-html.el

;; Author: Jeff Kreeftmeijer <jeff@kreeft.me>
;; Version: 0.1
;; URL: https://jeffkreeftmeijer.com/ox-html-stable-ids/

;;; Commentary:

;; ox-html-stable-ids.el replaces the default, unstable IDs with
;; stable ones based on headline contents.
;;
;; Unstable ID:
;;    <h2 id="org81963c6">Hello, world!</h2>
;;
;; ID generated by ox-html-stable-ids:
;;    <h2 id="hello-world">Hello, world!</h2>

;;; Code:

(require 'ox)

(defgroup org-export-html-stable-ids nil
  "Options for org-html-stable-ids."
  :tag "Org Markdown Title"
  :group 'org-export
  :version "24.4"
  :package-version '(Org . "8.0"))

(defcustom org-html-stable-ids nil
  "Non-nil means to use stable IDs in the exported document."
  :group 'org-export-html-stable-ids
  :version "24.4"
  :package-version '(Org . "8.0")
  :type 'boolean)

(defun org-html-stable-ids--extract-id (datum)
  "Extract a reference from a DATUM.

Return DATUM's `:CUSTOM_ID` if set, or generate a reference from its
`:raw-value` property.  If the DATUM does not have either, return
nil."
  (or
   (org-element-property :CUSTOM_ID datum)
   (let ((value (org-element-property :raw-value datum)))
     (when value
       (org-html-stable-ids--to-kebab-case value)))))

(defun org-html-stable-ids--to-kebab-case (string)
  "Convert STRING to kebab-case."
  (string-trim
   (replace-regexp-in-string
    "[^a-z0-9]+" "-"
    (downcase string))
   "-" "-"))

(defun org-html-stable-ids--get-reference (orig-fun datum info)
  "Return a reference for DATUM with INFO.

    Raise an error if the ID was used in the document before."
  (if org-html-stable-ids
      (let ((cache (plist-get info :internal-references))
	    (id (org-html-stable-ids--extract-id datum)))
	(or (car (rassq datum cache))
	    (if (assoc id cache)
		(user-error "Duplicate ID: %s" id)
	      (when id
		(push (cons id datum) cache)
		(plist-put info :internal-references cache)
		id))))
    (funcall orig-fun datum info)))

(defun org-html-stable-ids--reference (datum info &optional named-only)
  "Call `org-export-get-reference` to get a reference for DATUM with INFO.

If `NAMED-ONLY` is non-nil, return nil."
  (unless named-only
    (org-export-get-reference datum info)))

(defun org-html-stable-ids-add ()
  "Enable org-html-stable-ids."
  (interactive)
  (advice-add #'org-export-get-reference :around #'org-html-stable-ids--get-reference)
  (advice-add #'org-html--reference :override #'org-html-stable-ids--reference))

(defun org-html-stable-ids-remove ()
  "Disable org-html-stable-ids."
  (interactive)
  (advice-remove #'org-export-get-reference #'org-html-stable-ids--get-reference)
  (advice-remove #'org-html--reference #'org-html-stable-ids--reference))

(provide 'ox-html-stable-ids)

;;; ox-html-stable-ids.el ends here
