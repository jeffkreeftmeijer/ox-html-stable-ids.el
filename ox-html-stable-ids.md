
# ox-html-stable-ids

When publishing HTML with Org mode's exporters, the headlines in the resulting documents get assigned ID attributes. These are used as anchors, amongst other things. By default, these are random, so a headline might get assigned `org81963c6` as its ID:

    <h2 id="org81963c6">Hello, world!</h2>

Because subsequent exports of the same Org file produce different IDs, there's no way to bookmark a headline. Instead, it'd be useful to have stable IDs, based on the titles they're attached to. In the example above, that ID would be "hello-world".

The function responsible for exporting headlines to HTML&#x2014;named `org-html-headline`&#x2014;calls `org-export-get-reference` to get a unique reference to the headline. By overriding the latter, we can get the exporter to assign custom IDs to the document's headlines.

We'll write an advise to override the implementation of the `org-export-get-reference` function. To make the custom function easy to switch on and off, we'll write two helper functions:

```emacs-lisp
(defun org-html-stable-ids-add ()
  (interactive)
  (advice-add #'org-export-get-reference :override #'org-html-stable-ids--get-reference))

(defun org-html-stable-ids-remove ()
  (interactive)
  (advice-remove #'org-export-get-reference #'org-html-stable-ids--get-reference))
```

To check if everything is hooked up correctly, we'll define `org-html-stable-ids--get-reference` that ignores the inputs and returns a static result:

```emacs-lisp
(defun org-html-stable-ids--get-reference (datum info)
  "hello-world")
```

As expected, the result used "hello-world" as the ID for all headlines:

    <h2 id="hello-world">Hello, world!</h2>
    <h2 id="hello-world">Another headline!</h2>

To have the IDs match each separate headline's contents, take the headline from the `datum` parmeter with `org-element-property`:

```emacs-lisp
(defun org-html-stable-ids--to-kebab-case (string)
  "Convert STRING to kebab-case."
  (string-trim
   (replace-regexp-in-string "[^a-z0-9]+" "-"
			     (downcase string))
   "-" "-"))

(defun org-html-stable-ids--get-reference (datum info)
  (org-html-stable-ids--to-kebab-case
   (org-element-property :raw-value datum)))
```

Now, all headlines in the file get assigned IDs that match their contents:

    <h2 id="hello-world">Hello, world!</h2>
    <h2 id="another-headline">Another headline!</h2>

If a headline has a `CUSTOM_ID`, that's used instead of the generated one:

```org
* Hello, world!
* Another headline!
:PROPERTIES:
:CUSTOM_ID: custom-id
:END:
```

    <h2 id="hello-world">Hello, world!</h2>
    <h2 id="custom-id">Another headline!</h2>

In the current implementation, multiple headlines with the same contents get assigned the same ID. Instead of making the headlines custom by adding numbers to the end, the exporter should raise an error and quit. It's up to the author to update the document by giving the headlines meaningful custom IDs.

Exporting a document with duplicate IDs should raise an error. To do so, each ID needs to be added to a cache when it's created, much like the original implementation of `org-get-reference`. Whenever an ID is requested, an *internal-references* key is added to the *info* property list if it doesn't exist yet. It holds a cons with the ID and the element. If the function is called again with the same element, the ID is taken from the property list and returned. However, if it's called with new element which resolves to an ID that's already in the property list, the function retuns an error:

```emacs-lisp
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
```

Now, the function raises an error when two headlines resolve to the same ID:

```org
* Hello, world!
* Hello, world!
```

```
Duplicate ID: hello-world
```

In another scenario, one headline has a custom ID that matches a previously resolved ID. Because this yields duplicate IDs, this should also raise an error. Currently, it doesn't:

```org
* Hello, world!
* Another headline!
:PROPERTIES:
:CUSTOM_ID: hello-world
:END:
```

    <h2 id="hello-world">Hello, world!</h2>
    <h2 id="hello-world">Another headline!</h2>

This is caused by a function named `org-html--reference`, which circumvents `org-export-get-reference` when custom IDs are set. To ensure all IDs are checked against the internal references list, we override `org-html--reference` to call `org-export-get-reference` directly:<sup><a id="fnr.1" class="footref" href="#fn.1" role="doc-backlink">1</a></sup>

```emacs-lisp
(defun org-html-stable-ids-add ()
  "Enable org-html-stable-ids."
  (interactive)
  (advice-add #'org-export-get-reference :override #'org-html-stable-ids--get-reference)
  (advice-add #'org-html--reference :override #'org-html-stable-ids--reference))

(defun org-html-stable-ids-remove ()
  "Disable org-html-stable-ids."
  (interactive)
  (advice-remove #'org-export-get-reference #'org-html-stable-ids--get-reference)
  (advice-remove #'org-html--reference #'org-html-stable-ids--reference))
```

    org-html-stable-ids-remove

```emacs-lisp
(defun org-html-stable-ids--reference (datum info &optional named-only)
  "Call `org-export-get-reference` to get a reference for DATUM with INFO.
The NAMED-ONLY argument is ignored, as `org-export-get-reference`
always returns a reference."
  (org-export-get-reference datum info))
```

    org-html-stable-ids--reference

Then, in our overridden version, we check if a custom ID is set before generating an ID from the element's value:

```emacs-lisp
(defun org-html-stable-ids--get-reference (datum info)
  "Return a reference for DATUM with INFO.

Return the element's :CUSTOM_ID, or an id generated from its
`:raw-value` property.  Raise an error if the ID was used in the
document before."
  (let ((cache (plist-get info :internal-references)))
    (let ((id (or
	       (org-element-property :CUSTOM_ID datum)
	       (org-html-stable-ids--to-kebab-case
		(org-element-property :raw-value datum)))))
      (or (rassq datum cache)
	  (if (assoc id cache)
	      (user-error "Duplicate ID: %s" id)
	    (push (cons id datum) cache)
	    (plist-put info :internal-references cache)
	    id)))))
```

    org-html-stable-ids--get-reference

Publishing the example again produces the expected error:

```
Duplicate ID: hello-world
```


# Usage

Install ox-html-stable-ids with straight and use-package:

```emacs-lisp
(use-package ox-html-stable-ids
  :straight '(ox-html-stable-ids
	      :type git
	      :host github
	      :repo "jeffkreeftmeijer/ox-html-stable-ids.el"))
```

Call `org-html-stable-ids-add` before publishing a file:

```emacs-lisp
(org-html-stable-ids-add)
(org-publish-file "test/fixtures/hello-world.org"
		  '("ox-html-stable-ids"
		    :publishing-function org-html-publish-to-html
		    :base-directory "."
		    :publishing-directory "."
		    :section-numbers nil
		    :with-toc nil))
(org-html-stable-ids-remove)
```

Get stable IDs:

    <h2 id="hello-world">Hello, world!</h2>

## Footnotes

<sup><a id="fn.1" class="footnum" href="#fnr.1">1</a></sup> : The `org-html--reference` function has added logic to check the *html-prefer-user-labels* attribute. By calling out to `org-export-get-reference` directly, that functionality is lost, meaning this library implies the *html-prefer-user-labels* setting.