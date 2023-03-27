(require 'ert)

(ert-deftest hello-world-test ()
  (find-file "example.org")
  (org-html-export-as-html)
  (should (string-match-p
	   "<h2 id=\"hello-world"
	   (with-current-buffer "*Org HTML Export*" (buffer-string)))))
