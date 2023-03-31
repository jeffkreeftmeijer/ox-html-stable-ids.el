(require 'ert)
(load-file "ox-html-stable-ids.el")

(ert-deftest hello-world-test ()
  (org-html-stable-ids-add)
  (find-file "test/fixtures/hello-world.org")
  (org-html-export-as-html)
  (should (string-match-p
           "<h2 id=\"hello-world"
           (with-current-buffer "*Org HTML Export*" (buffer-string))))
  (org-html-stable-ids-remove))

(ert-deftest multiple-headlines-test ()
  (org-html-stable-ids-add)
  (find-file "test/fixtures/multiple-headlines.org")
  (org-html-export-as-html)
  (let ((buffer (with-current-buffer "*Org HTML Export*" (buffer-string))))
    (should (string-match-p "<h2 id=\"hello-world" buffer))
    (should (string-match-p "<h2 id=\"another-headline" buffer)))
  (org-html-stable-ids-remove))

(ert-deftest src-block-test ()
  (org-html-stable-ids-add)
  (find-file "test/fixtures/src-block.org")
  (org-html-export-as-html)
  (let ((buffer (with-current-buffer "*Org HTML Export*" (buffer-string))))
    (should (string-match-p "<pre class=\"src src-shell\">" buffer)))
  (org-html-stable-ids-remove))

(ert-deftest duplicate-headlines-test ()
  (org-html-stable-ids-add)
  (find-file "test/fixtures/duplicate-headlines.org")
  (should-error (org-html-export-as-html))
  (org-html-stable-ids-remove))

(ert-deftest duplicate-headlines-with-custom-id-test ()
  (org-html-stable-ids-add)
  (find-file "test/fixtures/duplicate-headlines-with-custom-id.org")
  (should-error (org-html-export-as-html))
  (org-html-stable-ids-remove))
