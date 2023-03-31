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

(ert-deftest multiple-headlines-test ()
  (org-html-stable-ids-add)
  (find-file "example-3.org")
  (org-html-export-as-html)
  (let ((buffer (with-current-buffer "*Org HTML Export*" (buffer-string))))
    (should (string-match-p "<h2 id=\"hello-world" buffer))
    (should (string-match-p "<h2 id=\"another-headline" buffer)))
  (org-html-stable-ids-remove))

(ert-deftest duplicate-headlines-test ()
  (org-html-stable-ids-add)
  (find-file "example-5.org")
  (should-error (org-html-export-as-html))
  (org-html-stable-ids-remove))

(ert-deftest duplicate-headlines-with-custom-id-test ()
  (org-html-stable-ids-add)
  (find-file "example-6.org")
  (should-error (org-html-export-as-html))
  (org-html-stable-ids-remove))
