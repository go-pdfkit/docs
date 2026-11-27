---
title: "Any document to PDF"
weight: 140
---

[`go-pdfkit/doc2pdf`](https://github.com/go-pdfkit/doc2pdf) (v0.4.0) turns a
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

Word, Excel, PowerPoint, OpenDocument Text, Spreadsheet, Presentation and
Graphics, Markdown, reStructuredText, HTML, plain text, CSV, JSON, XML, EPUB,
MOBI, FictionBook, RTF (`.rtf`) and email — nineteen formats, all of them
arriving at the
[richdoc](https://github.com/go-richdoc/richdoc) document model and leaving
through [`go-pdfkit/document`](https://github.com/go-pdfkit/document).

`doc2pdf --list` prints the table, with the package that reads each one.
XPS and OpenXPS (`.xps`, `.oxps`) are read separately, see below.

RTF is read by [`go-richdoc/rtf`](https://github.com/go-richdoc/rtf) v0.1.2 or
later. It keeps headings, lists, tables, hyperlinks, footnotes, PNG and JPEG
pictures, bold, italic, strike and paragraph alignment; it does not keep font
sizes, colours, underline, fonts, indents, headers and footers, or WMF and EMF
pictures.

## XPS and OpenXPS

`doc2pdf scan.xps` and `doc2pdf scan.oxps` (v0.4.0) write a **vector** PDF with
selectable text and embedded fonts. XPS does not go through richdoc: every
glyph sits where its producer put it, so the package is read directly by the
`xps` package of doc2pdf.

It draws paths and geometry, clips, opacity and transforms; solid, linear,
radial and image brushes (PNG, JPEG, TIFF, tiled); and `Glyphs` runs in the
embedded font. What it does not draw (VisualBrush, JPEG XR, TrueType
collections) is counted and printed as `not drawn: …`.

An XPS file is untrusted input, so one memory budget bounds a conversion,
`MaxMemory`, 160 MiB by default, together with ceilings on parts, pages, XML
depth, image pixels and drawing work. WOFF and WOFF2 fonts are refused, because
ECMA-388 section 9.1.7 requires OpenType (TrueType and CFF) only. The charges
are measured upper bounds, not proofs: the peak was measured up to 375 MiB
under `-race` on the worst probe, and the bytes API (`xps.Convert`) buffers the
whole PDF where the command streams it to the output file.

## Input size

`--max-input BYTES` bounds each input, and a larger file is refused **before it
is read**. The default is 16 MiB for RTF and 256 MiB for every other format;
the value must be from 1 up to 9223372036854775806, and anything else is a
usage error (exit 2).

```text
doc2pdf: big.rtf is 20000000 bytes, over the 16777216-byte limit for RTF; -max-input raises it
```

## The output is written atomically

The PDF goes to a temporary file beside the output and is then published. With
`-f` it is renamed over the output; without `-f` it never overwrites an
existing file, even on a file system with no hard links, and a failed write
never leaves a partial file.

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

Fifteen of the nineteen formats are exercised end to end by the tests, and the
test asserts that number against the table — EPUB, MOBI, FictionBook and
PowerPoint each need a real package built as a fixture, which is its own work.
A recorded gap rather than an unnoticed one.
