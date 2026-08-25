# go-pdfkit documentation

**The whole of PDF in Go, with `CGO_ENABLED=0` and no C anywhere**: read a
file, write one, rearrange it, draw it, read it back as words and pictures,
and edit it with other people. Every library here builds for `GOOS=js/wasm`,
so all of it runs in a browser tab.

Fonts are parsed and shaped with
[go-opentype](https://github.com/go-opentype/opentype) and pages are
rasterised by [go-gfx](https://github.com/go-gfx/gfx); nothing outside the Go
standard library and our own pure-Go libraries is required.

!!! quote "Measured against 118 863 real files"
    Every claim on this site is measured against a corpus of real PDFs —
    arXiv's figures, from Matplotlib and Mathematica and pdfTeX and Ghostscript
    and Adobe — rather than against files written to pass a test. Each wave of
    work is checked by **hashing the pixels of every page before and after** and
    putting the biggest changes beside what the operating system's own renderer
    draws. That is what found a stroke that came out at half its colour, a font
    that took the dots off every *i*, and a colour transform that turned every
    plot's paper yellow.

!!! success "Zero C dependencies"
    No cgo, no bundled `libpoppler`/`libharfbuzz`/`libfreetype`. Glyph
    subsetting, font-descriptor metrics and per-glyph advances all come from
    [go-opentype](https://github.com/go-opentype/opentype)'s
    `Font.SubsetTrueType` / `Font.SubsetCFF` — `pdfkit` keeps no private sfnt
    re-parse or subsetter of its own. See
    [Text & fonts](text-and-fonts.md#font-embedding-architecture).

## The family

| Repo | What it is |
| --- | --- |
| [`reader`](https://github.com/go-pdfkit/reader) | reads and writes the format itself: objects, cross-reference tables and streams, filters, encryption, the page tree, content streams — and a writer that produces the same bytes twice |
| [`ops`](https://github.com/go-pdfkit/ops) | the verbs, and the `pdfops` command: merge, split, rotate, crop, n-up, watermark, encrypt, and reading a page back |
| [`render`](https://github.com/go-pdfkit/render) | turns a page into pixels: paths, images, text in every font flavour, functions, shadings and patterns |
| [`pdffont`](https://github.com/go-pdfkit/pdffont) | what a document says about a font — encodings, widths, and what text a code stands for |
| [`extract`](https://github.com/go-pdfkit/extract) | reads a page back: the text with where it sits, and the pictures with the box each covers |
| [`coedit`](https://github.com/go-pdfkit/coedit) | a PDF several people edit at once — the plan is shared, not the file |
| [`app`](https://github.com/go-pdfkit/app) | a PDF workbench that runs in a browser tab and nowhere else |
| [`pdfkit`](https://github.com/go-pdfkit/pdfkit) | the document builder: pages, vector graphics, and text in embedded subsetted fonts |
| [`docs`](https://github.com/go-pdfkit/docs) | this documentation site (MkDocs Material, versioned with mike) |

Two libraries outside the org do the work under all of it:
[go-opentype/opentype](https://github.com/go-opentype/opentype), the sfnt,
CFF and Type 1 parser and shaper, and [go-gfx/gfx](https://github.com/go-gfx/gfx),
the rasteriser. [go-ruby-prawn](https://github.com/go-ruby-prawn) is the
Ruby-idiomatic writer built on the same font stack.

## What it is

- A **PDF 1.7 writer**: catalog, page tree, cross-reference table and
  trailer, written to any `io.Writer`, with optional FlateDecode stream
  compression (`Options.Compress`).
- **Vector graphics**: paths (move/line/cubic/rect/close), fill and stroke
  (nonzero and even-odd), DeviceGray/RGB/CMYK colour, line width/cap/join/
  miter/dash, CTM transforms (translate/scale/rotate/skew), clipping, `q`/`Q`
  graphics-state save/restore, and constant-alpha transparency via
  `ExtGState`.
- **Text as embedded, subsetted fonts**: every font used is written as a
  **Type0 (Identity-H)** composite font with a per-glyph `/W` width array and
  a `/ToUnicode` CMap for copy/paste. TrueType `glyf` outlines embed as a
  subsetted `FontFile2` / `CIDFontType2` with a `/CIDToGIDMap` stream; CFF/
  OpenType outlines embed as a **charstring-subsetted** `FontFile3` /
  `CIDFontType0`.
- **Images**: JPEG embedded directly (`DCTDecode`, no re-encoding); PNG and
  any `image.Image` rasterised as XObjects (`FlateDecode`) with an `/SMask`
  for alpha.
- **Widget bridge**: `Page.AddWidget` and `Page.AddWidgetVector` "print" a
  [go-widgets/toolkit](https://github.com/go-widgets/toolkit) widget tree onto
  a page — as a rasterised image, or as PDF vector operators with selectable
  text. See [Widgets](widgets.md).
- **Deterministic output**: with the zero `Options`, a document has no
  timestamps and a content-derived `/ID` (a SHA-256 of the body), so
  identical inputs produce byte-identical PDFs.

## What it is not (yet)

- A **CID-keyed CFF** or a **CFF2 (variable)** font cannot be
  charstring-subsetted by the preserve-numbering path, so it falls back to
  embedding the whole `CFF`/`CFF2` table. A plain (non-CID-keyed) CFF/OpenType
  font **is** charstring-subsetted, same as TrueType `glyf`.
- Encryption, tagged PDF / PDF-A, interactive forms and annotations are not
  yet implemented.

See [Scope and limitations](text-and-fonts.md#scope-and-limitations) for the
full picture, and the upstream
[README](https://github.com/go-pdfkit/pdfkit#scope-and-limitations) for the
canonical statement.

## Install

```sh
go get github.com/go-pdfkit/pdfkit
```

## Where to go next

- [Getting started](getting-started.md) — the five calls that make a PDF:
  `New` → `AddPage` → `SetFont` → `Text` → `Write`.
- [Graphics](graphics.md) — paths, colour, line state, transforms, clipping
  and transparency.
- [Text & fonts](text-and-fonts.md) — loading fonts, drawing text, measuring
  and wrapping, and the shaped-text API for complex scripts.
- [Images](images.md) — `DrawImage`, `DrawPNG` and `DrawJPEG`.
- [Widgets](widgets.md) — printing a go-widgets/toolkit widget tree to a page.
- [API reference](api.md) — the full public surface with Go examples.

Source lives at
[github.com/go-pdfkit/pdfkit](https://github.com/go-pdfkit/pdfkit).
