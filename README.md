
# ox-html-stable-ids: Stable IDs for ox-html.el

Ox-html-stable-ids is an Org export extension package that generates HTML with stable ID attributes instead of the random IDs Org's exporter uses by default.


## Introduction

When publishing HTML with Org mode's exporters, the headlines in the resulting documents get assigned ID attributes. These are used as anchors, amongst other things. By default, these are random, so a headline might get assigned `org81963c6` as its ID:

```html
<h2 id="org81963c6">Hello, world!</h2>
```

Because subsequent exports of the same Org file produce different IDs, there's no way to link to a headline from an external page. Ox-html-stable-ids provides stable IDs based on the titles of the headlines they're attached to. In the example above, the headline's ID would be "hello-world".


## Implementation

Ox-html-stable-ids is disabled by default, even after requiring and enabling the library. It only replaces IDs in exported HTML documents when `org-html-stable-ids` is non-nil:

```emacs-lisp
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
```

The function that generates headlines in Org's HTML exporer (`org-html-headline`) calls a function called `org-export-get-reference` to generate a unique reference for the headline. Ox-html-stable-ids adds an advice to overrides that function to return stable IDs, based on the headline's contents, instead.<sup><a id="fnr.1" class="footref" href="#fn.1" role="doc-backlink">1</a></sup>

First, the `org-html-stable-ids--extract-id` helper function takes a headline and returns a stable ID:

```emacs-lisp
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
```

If the headline has a `:CUSTOM_ID` property, that's immediately returned. If not, the ID is created by taking the headline's contents and converting them to "kebab case".

<div class="aside" id="org6151426">
<p>

</p>

<p>
The illustratively named <i>kebab case</i> is a case style (like <code>snake_case</code> or <code>camelCase</code>) where all characters are lower case, and all whitespace is replaced by dashes resembling a kebab.
It's used in Lisp-style languages, and URL fragments.
</p>

<p>
An implementation in Emacs Lisp uses a regular expression to replace everything but letters and numbers to a dash, and then downcases the result:
</p>

<div class="org-src-container">
<pre class="src src-emacs-lisp" id="orgd78f599">(defun org-html-stable-ids--to-kebab-case (string)
  "Convert STRING to kebab-case."
  (string-trim
   (replace-regexp-in-string
    "[^a-z0-9]+" "-"
    (downcase string))
   "-" "-"))
</pre>
</div>

</div>

The `org-export-get-reference` is overridden by a function named `org-html-stable-ids--get-reference`, which calls the `org-html-stable-ids--extract-id` to extract IDs for headlines. It uses an internal propetry list named `:internal-references` as a cache to store generated IDs in. If a generated ID matches one that's already in the cache, an error is returned, and the export is aborted:

```emacs-lisp
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
```

Org's HTML exporter doesn't call the `org-export-get-reference` function directly, but has an internal function named `org-html--reference` that's called whenever a reference is needed. To ensure all ids are checked against the internal references list, this package overrides `org-html--reference` to always call `org-export-get-reference` directly:<sup><a id="fnr.2" class="footref" href="#fn.2" role="doc-backlink">2</a></sup>

```emacs-lisp
(defun org-html-stable-ids--reference (datum info &optional named-only)
  "Call `org-export-get-reference` to get a reference for DATUM with INFO.

If `NAMED-ONLY` is non-nil, return nil."
  (unless named-only
    (org-export-get-reference datum info)))
```

Finally, the advise is added (and possibly removed) through the `org-html-stable-ids-add` and `org-html-stable-ids-remove` functions:

```emacs-lisp
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
```


## Results

Now, all headlines in the file get assigned IDs that match their contents:

```html
<h2 id="hello-world">Hello, world!</h2>
<h2 id="another-headline">Another headline!</h2>
```

If a headline has a `CUSTOM_ID`, that's used instead of the generated one:

```org
* Hello, world!
* Another headline!
:PROPERTIES:
:CUSTOM_ID: custom-id
:END:
```

```html
<h2 id="hello-world">Hello, world!</h2>
<h2 id="custom-id">Another headline!</h2>
```

Now, the function raises an error when two headlines resolve to the same ID:

```org
* Hello, world!
* Hello, world!
```

```
Duplicate ID: hello-world
```

As expected, the error is also raised when a custom ID is duplicated:

```org
* Hello, world!
* Another headline!
:PROPERTIES:
:CUSTOM_ID: hello-world
:END:
```

```
Duplicate ID: hello-world
```


## Installation and usage

Ox-html-stable-ids is currently not available through any of the package registries. Instead, install it from the repository direcly. Install the package with [use-package](https://github.com/jwiegley/use-package) and [straight.el](https://github.com/radian-software/straight.el), and enable it by calling `org-html-stable-ids-add`:

```emacs-lisp
(use-package ox-html-stable-ids
  :straight
  (ox-html-stable-ids :type git :host github :repo "jeffkreeftmeijer/ox-html-stable-ids.el")
  :config
  (org-html-stable-ids-add))
```

After calling `org-html-stable-ids-add`, set the `org-html-stable-ids` variable to to enable the package while exporting:

```emacs-lisp
(let ((org-html-stable-ids t))
  (org-html-publish-to-html))
```

Get stable IDs:

```html
<h2 id="hello-world">Hello, world!</h2>
```


## Contributing

The git repository for ox-html-stable-ids.el is hosted on [Codeberg](https://codeberg.org/jkreeftmeijer/ox-html-stable-ids.el), and mirrored on [GitHub](https://github.com/jeffkreeftmeijer/ox-html-stable-ids.el). Contributions are welcome via either platform.


### Tests

Regression tests are written with [ERT](https://www.gnu.org/software/emacs/manual/html_mono/ert.html) and included in `test.el`. To run the tests in batch mode:

```shell
emacs -batch -l ert -l test.el -f ert-run-tests-batch-and-exit
```

## Footnotes

<sup><a id="fn.1" class="footnum" href="#fnr.1">1</a></sup> This is based on [Adam Porter's useful anchors example](https://github.com/alphapapa/unpackaged.el#export-to-html-with-useful-anchors), which differs in a couple of ways:

Adam's example uses URL encoded IDs, instead of stripping all non-alphabetic and non-numeric characters and converting it to kebab-case. For non-unique IDs, it prepends the ancestors' IDs and appends numbers until each ID is unique instead of raising an error and forcing the user to use custom IDs. It's the better choice if you need stable IDs that sort themselves out without ever breaking your publishing.

<sup><a id="fn.2" class="footnum" href="#fnr.2">2</a></sup> The `org-html--reference` function has added logic to check the *html-prefer-user-labels* attribute. By calling out to `org-export-get-reference` directly, that functionality is lost, meaning this library implies the *html-prefer-user-labels* setting.