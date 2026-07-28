# go-pdfkit documentation

**A pure-Go, `CGO_ENABLED=0` PDF 1.7 writer** with a Go-idiomatic API. It
builds documents from pages, draws vector graphics and text, embeds TrueType
and OpenType/CFF fonts as subsetted composite (Type0) fonts, and places JPEG
and raster images. Fonts are parsed and shaped with
[go-opentype](https://github.com/go-opentype/opentype); nothing outside the
Go standard library and our own pure-Go libraries is required.

!!! success "Zero C dependencies"
    No cgo, no bundled `libpoppler`/`libharfbuzz`/`libfreetype`. `pdfkit`
    reparses the sfnt container itself (`sfnt.go`) and implements TrueType
    glyph subsetting (`subset.go`) because go-opentype exposes no raw table
    bytes, units-per-em, glyf/loca arrays or a subsetting export — see
    [Text & fonts](text-and-fonts.md#missing-upstream-primitives).

## The family

`pdfkit` is the Go-native counterpart to the Ruby Prawn port
[go-ruby-prawn](https://github.com/go-ruby-prawn); here the API is
Go-idiomatic rather than a gem port. Both draw on the same underlying text
stack:

| Repo | What it is |
| --- | --- |
| [`pdfkit`](https://github.com/go-pdfkit/pdfkit) | the writer — `document.go`, `page.go`, `text.go`, `image.go`, `embed.go`, and the public API |
| [`docs`](https://github.com/go-pdfkit/docs) | this documentation site (MkDocs Material, versioned with mike) |
| [go-opentype/opentype](https://github.com/go-opentype/opentype) | the sfnt parser and shaper `pdfkit` embeds fonts through |
| [go-ruby-prawn](https://github.com/go-ruby-prawn) | the Ruby-idiomatic PDF writer built on the same font stack |

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
  **Type0 (Identity-H)** composite font with an Identity CIDToGIDMap, a
  per-glyph `/W` width array and a `/ToUnicode` CMap for copy/paste. TrueType
  `glyf` outlines embed as a subsetted `FontFile2` / `CIDFontType2`; CFF/
  OpenType outlines embed as `FontFile3` / `CIDFontType0`.
- **Images**: JPEG embedded directly (`DCTDecode`, no re-encoding); PNG and
  any `image.Image` rasterised as XObjects (`FlateDecode`) with an `/SMask`
  for alpha.
- **Deterministic output**: with the zero `Options`, a document has no
  timestamps and a content-derived `/ID` (a SHA-256 of the body), so
  identical inputs produce byte-identical PDFs.

## What it is not (yet)

- CFF/OpenType fonts embed their **whole `CFF ` table** — charstring
  subsetting is not implemented. TrueType fonts **are** fully subsetted.
- Encryption, tagged PDF / PDF-A, interactive forms and annotations are out
  of scope for v0.1.

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
- [API reference](api.md) — the full public surface with Go examples.

Source lives at
[github.com/go-pdfkit/pdfkit](https://github.com/go-pdfkit/pdfkit).
