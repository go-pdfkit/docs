---
title: "Widgets"
weight: 120
---

The subpackage `github.com/go-pdfkit/pdfkit/widget` "prints" a
[go-widgets/toolkit](https://github.com/go-widgets/toolkit) widget tree onto a
page, so any UI composed from toolkit widgets can be placed straight into a
PDF. It is a separate package so that a program which only writes PDFs does
not link the toolkit. Importing `pdfkit` alone pulls 196 packages, against
403 in v0.19 when the bridge was in the root package. Two paths are offered,
trading fidelity for selectability:

| | Output | Text |
| --- | --- | --- |
| `widget.Add` | an image XObject — pixel-identical to the screen | rasterised, not selectable |
| `widget.AddVector` | PDF vector operators (fills, strokes, rounded rects, text-show) | real, selectable PDF text |

## Raster: `widget.Add`

```go
import (
    "github.com/go-pdfkit/pdfkit"
    "github.com/go-pdfkit/pdfkit/widget"
    "github.com/go-widgets/toolkit"
)

root := toolkit.NewContainer(toolkit.NewBoxLayout())
btn := toolkit.NewButton("Submit", nil)
btn.Style = toolkit.ButtonProminent
root.AddWidget(btn)
root.AddWidget(toolkit.NewLabel("Status: ready"))

rect := pdfkit.Rect{X: pdfkit.Mm(20), Y: pdfkit.Mm(200), Width: pdfkit.Mm(80), Height: pdfkit.Mm(30)}
err := widget.Add(p, root, rect, nil)
```

`widget.Add` lays `root` out to fill `rect` (in points). It renders the whole
widget tree to an RGBA raster through a `painter.PixelPainter`, and places
that raster as an image XObject at `rect`. Every widget renders exactly as it
would on screen, at the cost of a bitmap: text cannot be selected or copied.
`opts` may be `nil`; `Font` is ignored on this path.

## Vector: `widget.AddVector`

```go
opts := &widget.Options{Font: font} // font: an already-loaded *pdfkit.Font
err := widget.AddVector(p, root, rect, opts)
```

`widget.AddVector` lays `root` out the same way, then runs it through a
painter that emits PDF vector operators instead of pixels: fills and strokes
stay crisp at any zoom, and text becomes real, selectable PDF text.

`Options.Font` is **required**. It backs any run drawn through the toolkit's
built-in bitmap font, so a `nil` or fontless `opts` returns `widget.ErrNoFont`.

A widget label can also be set in a TrueType/OpenType toolkit font, a
`painter.Face` made with `toolkit.NewTrueTypeFont` and `toolkit.SetFont`. That
face's own bytes are then embedded, and the run is emitted as selectable Type0
text at the face's own size.

## `widget.Options`

```go
type Options struct {
    Theme *toolkit.Theme // nil = toolkit.DefaultLight()
    Scale float64        // layout pixels per PDF point; <= 0 = widget.DefaultScale (2)
    Font  *pdfkit.Font   // required by AddVector; ignored by Add
}
```

`Scale` sets how many layout pixels the tree gets per PDF point before it is
placed in `rect`. A larger scale gives a crisper raster (`Add`) and finer
layout rounding on both paths. `rect`'s width and height must both resolve to a
positive pixel count at that scale, or both functions return
`widget.ErrEmptyRect`.

## Upgrading from v0.19

| v0.19 (`pdfkit`) | v0.20 (`pdfkit/widget`) |
| --- | --- |
| `p.AddWidget(root, rect, opts)` | `widget.Add(p, root, rect, opts)` |
| `p.AddWidgetVector(root, rect, opts)` | `widget.AddVector(p, root, rect, opts)` |
| `pdfkit.WidgetOptions` | `widget.Options` |
| `pdfkit.DefaultWidgetScale` | `widget.DefaultScale` |

## Putting the two together

A common pattern is to draw the same tree twice: once as a raster fallback,
and once as vector, stacked in the document so that the vector copy carries the
selectable text layer:

```go
rect := pdfkit.Rect{X: pdfkit.Mm(20), Y: pdfkit.Mm(200), Width: pdfkit.Mm(80), Height: pdfkit.Mm(30)}

_ = widget.Add(p, root, rect, nil) // pixel-identical to the screen

rect.Y -= pdfkit.Mm(40)
_ = widget.AddVector(p, root, rect, &widget.Options{Font: font}) // crisp + selectable
```

Next: the [API reference](/docs/api/) for the complete signature list.
