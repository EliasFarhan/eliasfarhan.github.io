# CV system

The CV is a Jekyll page assembled from a collection of small Markdown documents.
`cv.md` supplies the `/cv/` route, `_layouts/cv.html` defines the document
structure, and `_includes/cv/` resolves each named section. Presentation lives in
the `_sass/_cv.scss` partial, exposed through `assets/css/cv.scss`.

## Editing

Edit the documents in `_cv/`. Their filenames and `slug` front matter connect
them to the layout; all visible CV copy remains in Markdown. Run the normal site
preview while editing:

```sh
bundle exec jekyll serve
```

Then open `http://localhost:4000/cv/`.

## Building the PDF

Chrome or Chromium, Ruby/Bundler, Python 3, and curl must be available. Run:

```sh
make cv
```

The command builds Jekyll, briefly serves `_site` locally so browser assets use
the same URLs as production, and writes:

```text
_site/cv/elias-farhan-cv.pdf
```

The GitHub Actions workflow performs the same build, uploads the complete
generated site as a Pages artifact, and deploys it after pushes. Pull requests
run the full build without deploying. The PDF is therefore rebuilt from the
same HTML and Markdown on every build.

## Layout and accessibility

The document order is header, summary, experience, projects, then supporting
details. CSS Grid places supporting details in the 30% sidebar on wider screens
without changing this ATS-friendly source order. On small screens the layout
collapses to one column. Print rules fix the sheet to A4, remove screen chrome,
and keep role/project entries together.
