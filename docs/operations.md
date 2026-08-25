# Rearranging a file

[`ops`](https://github.com/go-pdfkit/ops) is the verb layer: what people
actually do to a PDF they already have. A document here is an ordered list of
pages borrowed from source files, and nothing is applied until it is written.

```go
doc, _ := ops.Open(bytes)
doc.Select("4-6")                 // keep three pages
doc.SetRotation("2", 90)          // turn the middle one
doc.Watermark("all", "DRAFT")
doc.Compress()
out, _ := doc.Bytes()
```

A page range is written `1-3,7,10-` and may say `all`, `even`, `odd` or
`last`. It keeps its own order and its own repeats, so `3-1` reverses three
pages and `1,1` gives two copies.

## The verbs

Merge, select, delete, reverse, move, rotate, crop, resize, split; n-up,
booklet, overlay and underlay, blank pages; watermarks, page numbers, Bates
stamps and free stamps; sanitize, flatten, strip; compress, encrypt, decrypt
and permissions; and reading a page back as text or as pictures.

Links and bookmarks are **carried over** and pointed at the pages they became,
so extracting three pages of a book leaves the links between those three
working and drops the rest rather than pointing them at nothing.
`Doc.SetOutline` writes an outline of your own instead, which is what a
document assembled from several files needs.

## On the command line

```
pdfops merge out.pdf a.pdf b.pdf
pdfops select -pages 4-6 report.pdf extract.pdf
pdfops nup -n 4 slides.pdf handout.pdf
pdfops watermark -text CONFIDENTIAL contract.pdf marked.pdf
pdfops encrypt -user letmein -allow print,copy plain.pdf locked.pdf
pdfops -password letmein permissions locked.pdf
pdfops text -layout -pages 1 paper.pdf
pdfops images paper.pdf pictures/
```

## What the corpus says

Every verb is measured on all 118 863 files rather than on a fixture. The
campaigns found nine defects no unit test would have — a stamp that fell off
pages smaller than the margin, links that dragged a source file's whole page
tree into a one-page extract, bookmarks dropped for being broken when they had
been broken in the source, and an empty owner password in AES-256 that let any
password open the file with every permission.

118 833 of 118 833 files compress and read back **page for page identical**:
35.2 GB down to 33.6 GB.
