(require 'ert)
(load-file "ox-html-stable-ids.el")

(ert-deftest hello-world-test ()
  (org-html-stable-ids-add)
  (find-file "example.org")
  (org-html-export-as-html)
  (should (string-match-p
	   "<h2 id=\"hello-world"
	   (with-current-buffer "*Org HTML Export*" (buffer-string))))
  (org-html-stable-ids-remove))
