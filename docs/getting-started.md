# Getting started

## Install

```sh
go get github.com/go-pdfkit/pdfkit
```

## Coordinate system

User space is measured in **points** (1/72 inch), with the origin at the
**lower-left corner** and y increasing **upward** — matching PDF's own
imaging model. The `Pt`, `Mm` and `In` helpers convert physical units:

```go
pdfkit.Pt(72)   // 72 points, unchanged — documents intent at call sites
pdfkit.Mm(210)  // 210mm converted to points
pdfkit.In(8.5)  // 8.5in converted to points
```

Standard page sizes are predefined in points: `A3`, `A4`, `A5`, `Letter`,
`Legal`, `Tabloid`. Each has `.Landscape()` and `.Portrait()` to reorient it,
and `NewPageSize(width, height)` builds a custom size.

## A minimal document

```go
package main

import "os"
import "github.com/go-pdfkit/pdfkit"

func main() {
    ttf, _ := os.ReadFile("font.ttf")
    font, _ := pdfkit.LoadFont(ttf)

    doc := pdfkit.New(pdfkit.Options{Title: "Hello"})
    p := doc.AddPage(pdfkit.A4)

    p.SetFont(font, 24)
    p.Text(pdfkit.Mm(20), p.Height()-pdfkit.Mm(20), "Hello, pdfkit")

    p.SetStrokeColor(pdfkit.RGB8(0x0d, 0x94, 0x88))
    p.SetLineWidth(2)
    p.MoveTo(pdfkit.Mm(20), pdfkit.Mm(20))
    p.LineTo(pdfkit.Mm(190), pdfkit.Mm(20))
    p.Stroke()

    f, _ := os.Create("out.pdf")
    defer f.Close()
    doc.Write(f)
}
```

Five calls carry the whole shape of the API:

1. **`pdfkit.New(pdfkit.Options{})`** — creates an empty `*Document`. The
   zero `Options` is valid: no title/author, no compression, no timestamps
   (so output is byte-identical across runs with the same input).
2. **`doc.AddPage(pdfkit.A4)`** — appends a page of the given size and
   returns a `*Page` to draw on. `p.Width()` / `p.Height()` report its size
   in points.
3. **`p.SetFont(font, 24)`** — selects a loaded `*Font` at a point size for
   subsequent text on this page. The font is registered with the document
   for embedding on first use.
4. **`p.Text(x, y, s)`** — draws `s` with its baseline origin at `(x, y)`.
5. **`doc.Write(w)`** — serialises the complete PDF 1.7 file to any
   `io.Writer`. `Write` doesn't consume the document — it may be called more
   than once.

`Document` and `Page` are **not safe for concurrent use**: build one document
per goroutine, or synchronise access externally.

## Multiple pages, mixed sizes

```go
doc := pdfkit.New(pdfkit.Options{})
doc.AddPage(pdfkit.A4)
doc.AddPage(pdfkit.Letter.Landscape())
doc.AddPage(pdfkit.NewPageSize(pdfkit.In(4), pdfkit.In(6)))
```

Each `AddPage` call is independent — a document can freely mix page sizes and
orientations.

## Determinism

With the zero `Options`, `Write` produces **no timestamps** and a
content-derived `/ID` (a SHA-256 hash of the serialised body), so identical
inputs produce byte-identical documents — useful for reproducible builds and
snapshot testing. Set `Options.Now` to a `func() time.Time` to stamp
`/CreationDate` and `/ModDate`; leave it `nil` to keep output reproducible.
`Options.ID` can also supply an explicit trailer `/ID` pair.

Next: [Graphics](graphics.md) for paths and colour, or
[Text & fonts](text-and-fonts.md) for embedding and shaping.
