---
title: "Any document to PDF"
weight: 140
---

[`go-pdfkit/doc2pdf`](https://github.com/go-pdfkit/doc2pdf) (v0.1.0) turns a
document into a PDF from a shell:

```sh
go install github.com/go-pdfkit/doc2pdf@latest

doc2pdf report.docx            # writes report.pdf beside it
doc2pdf notes.md out.pdf
doc2pdf --list
```

```text
report.docx → report.pdf (Word, read by go-ooxml/ooxml, 44102 bytes)
```

Pure Go, CGO-free, no TeX.

## What it reads

Word, Excel, PowerPoint, OpenDocument Text, Markdown, reStructuredText, HTML,
plain text, CSV, JSON, XML, EPUB, MOBI, FictionBook and email — fifteen
formats through thirteen libraries, all of them arriving at the
[richdoc](https://github.com/go-richdoc/richdoc) document model and leaving
through [`go-pdfkit/document`](https://github.com/go-pdfkit/document).

`doc2pdf --list` prints the table, with the package that reads each one.

## Why it exists

Thirteen of those libraries were finished, tested, released — and **unusable
from a shell**. Measured across thirty repositories of this fleet: four shipped
a command and twenty-five did not.

A reader that nothing can call is in a different state from an unfinished one,
and it is easy to mistake for it. An inventory of these capabilities was
revised five times in one morning, largely over that distinction.

## Nothing is fetched

A document arrives from something somebody was handed — a `.docx`, an EPUB, an
email — and its images carry URLs that **whoever wrote the file chose**.
Following them would make every conversion a request to an address of the
author's choosing, from the converting machine and with its network position.

So nothing is fetched, and what was refused is **printed**:

```text
report.docx → report.pdf (Word, read by go-ooxml/ooxml, 44102 bytes)
  not fetched: https://tracker.example.invalid/pixel.png
```

A page with holes in it must not be silent.

## When a file will not read

The format is chosen by **suffix**, and the error says which suffixes are
known rather than reading the file as something else. `.docx`, `.xlsx`,
`.pptx`, `.odt` and `.epub` are all ZIP files, so sniffing the content means
reading the package anyway.

A reader that fails names **itself**, because thirteen libraries stand behind
this command and *"cannot read it"* sends you to the wrong one:

```text
doc2pdf: go-ooxml/ooxml could not read this Word: …
```

## What it cannot do

It inherits [html2pdf](../html-to-pdf/): no JavaScript, no `@font-face`, no
CSS background images, and CJK characters render as nothing.

Two other paths take a richdoc to a PDF and go through a real TeX compile —
`go-richdoc/rst/pdf` and `go-richdoc/latex/pdf`. Reach for those when TeX's
hyphenation and justification are the point and a six-megabyte engine is
acceptable; reach for this one when being CGO-free, building for `GOOS=js`,
and keeping emphasis, links and tables matter more.

Ten of the fifteen formats are exercised end to end by the tests, and the
test asserts that number against the table — EPUB, MOBI, FictionBook,
PowerPoint and ODT each need a real package built as a fixture, which is its
own work. A recorded gap rather than an unnoticed one.
