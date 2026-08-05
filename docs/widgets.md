# Widgets

`Page.AddWidget` and `Page.AddWidgetVector` "print" a
[go-widgets/toolkit](https://github.com/go-widgets/toolkit) widget tree onto a
page, so any UI composed from toolkit widgets can be placed straight into a
PDF. Two paths are offered, trading fidelity for selectability:

| | Output | Text |
| --- | --- | --- |
| `AddWidget` | an image XObject — pixel-identical to the screen | rasterised, not selectable |
| `AddWidgetVector` | PDF vector operators (fills, strokes, rounded rects, text-show) | real, selectable PDF text |

## Raster: `AddWidget`

```go
import "github.com/go-widgets/toolkit"

root := toolkit.NewContainer(toolkit.NewBoxLayout())
btn := toolkit.NewButton("Submit", nil)
btn.Style = toolkit.ButtonProminent
root.AddWidget(btn)
root.AddWidget(toolkit.NewLabel("Status: ready"))

rect := pdfkit.Rect{X: pdfkit.Mm(20), Y: pdfkit.Mm(200), Width: pdfkit.Mm(80), Height: pdfkit.Mm(30)}
err := p.AddWidget(root, rect, nil)
```

`AddWidget` lays `root` out to fill `rect` (in points), renders the whole
widget tree to an RGBA raster through a `painter.PixelPainter`, and places
that raster as an image XObject at `rect`. Every widget renders exactly as it
would on screen, at the cost of a bitmap: text cannot be selected or copied.
`opts` may be `nil` — `Font` is ignored on this path.

## Vector: `AddWidgetVector`

```go
opts := &pdfkit.WidgetOptions{Font: font} // font: an already-loaded *pdfkit.Font
err := p.AddWidgetVector(root, rect, opts)
```

`AddWidgetVector` lays `root` out the same way, then runs it through a
painter that emits PDF vector operators instead of pixels: fills and strokes
stay crisp at any zoom, and text becomes real, selectable PDF text. A
`WidgetOptions.Font` is **required** — it backs any run drawn through the
toolkit's built-in bitmap font — so a `nil` or fontless `opts` returns an
error (`AddWidgetVector requires WidgetOptions.Font for selectable text`).

A widget label set in a TrueType/OpenType toolkit font (a `painter.Face`, via
`toolkit.NewTrueTypeFont` + `toolkit.SetFont`) goes further: that face's own
bytes are embedded and the run is emitted as selectable Type0 text at the
face's own size, so the label is not limited to the toolkit's built-in bitmap
font either.

## `WidgetOptions`

```go
type WidgetOptions struct {
    Theme *toolkit.Theme // nil = toolkit.DefaultLight()
    Scale float64        // layout pixels per PDF point; <= 0 = DefaultWidgetScale (2)
    Font  *Font          // required by AddWidgetVector; ignored by AddWidget
}
```

`Scale` controls how many layout pixels the tree gets per PDF point before
being placed in `rect` — a larger scale gives a crisper raster (`AddWidget`)
and finer layout rounding on both paths. `rect`'s width and height must both
resolve to a positive pixel count at that scale, or both methods return an
error.

## Putting the two together

A common pattern is to draw the same tree once as a raster fallback and once
as vector, stacked in the document so the vector copy carries the selectable
text layer:

```go
rect := pdfkit.Rect{X: pdfkit.Mm(20), Y: pdfkit.Mm(200), Width: pdfkit.Mm(80), Height: pdfkit.Mm(30)}

_ = p.AddWidget(root, rect, nil) // pixel-identical to the screen

rect.Y -= pdfkit.Mm(40)
_ = p.AddWidgetVector(root, rect, &pdfkit.WidgetOptions{Font: font}) // crisp + selectable
```

Next: the [API reference](api.md) for the complete signature list.
