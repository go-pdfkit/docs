# Graphics

`Page`'s drawing methods mirror PDF's own imaging-model operators closely —
each method name maps to one or two content-stream operators, listed in
parentheses below.

## Paths

```go
p.MoveTo(x, y)                          // m
p.LineTo(x, y)                          // l
p.CurveTo(x1, y1, x2, y2, x3, y3)       // c — cubic Bézier
p.Rectangle(pdfkit.Rect{X: x, Y: y, Width: w, Height: h}) // re
p.ClosePath()                           // h
```

Paint the accumulated path with one of:

```go
p.Stroke()               // S
p.Fill()                 // f  — nonzero winding rule
p.FillEvenOdd()          // f* — even-odd rule
p.FillStroke()           // B  — fill (nonzero) then stroke
p.FillStrokeEvenOdd()    // B* — fill (even-odd) then stroke
p.EndPath()              // n  — no paint, used after Clip
```

## Clipping

```go
p.Rectangle(pdfkit.Rect{X: 0, Y: 0, Width: 100, Height: 50})
p.Clip()        // W  — intersect clip path, nonzero rule
p.EndPath()     // n  — required after Clip; discards the path without painting
```

`Clip` / `ClipEvenOdd` must be followed by a path-painting operator or
`EndPath`, matching PDF's own requirement that `W`/`W*` take effect only
after the *next* painting operator.

## Colour

Three colour spaces implement the `Color` interface:

```go
pdfkit.Gray{V: 0.5}                    // DeviceGray, 0 (black) – 1 (white)
pdfkit.RGB{R: 1, G: 0, B: 0}           // DeviceRGB, components in [0,1]
pdfkit.RGB8(0x0d, 0x94, 0x88)          // DeviceRGB from 8-bit components
pdfkit.CMYK{C: 0, M: 1, Y: 1, K: 0}    // DeviceCMYK, components in [0,1]
```

```go
p.SetFillColor(pdfkit.RGB8(0xf5, 0x9e, 0x0b))    // rg
p.SetStrokeColor(pdfkit.Gray{V: 0})               // G
```

## Line state

```go
p.SetLineWidth(2)                       // w
p.SetLineCap(pdfkit.CapRound)           // J — CapButt, CapRound, CapSquare
p.SetLineJoin(pdfkit.JoinMiter)         // j — JoinMiter, JoinRound, JoinBevel
p.SetMiterLimit(4)                      // M
p.SetDash([]float64{4, 2}, 0)           // d — empty pattern restores a solid line
```

## Transforms

```go
p.Save()                    // q — push graphics state
p.Transform(a, b, c, d, e, f) // cm — concatenate an affine matrix
p.Translate(tx, ty)         // cm 1 0 0 1 tx ty
p.Scale(sx, sy)             // cm sx 0 0 sy 0 0
p.Rotate(30)                // counter-clockwise, degrees, about the origin
p.Skew(axDeg, ayDeg)        // shear by x/y angles in degrees
p.Restore()                 // Q — pop graphics state
```

`Transform`'s matrix maps points as `x' = a·x + c·y + e` and
`y' = b·x + d·y + f`, exactly as PDF's `cm` operator does. Always bracket a
temporary transform in `Save()`/`Restore()` so it doesn't leak into
subsequent drawing.

## Transparency

```go
p.SetAlpha(0.5, 1.0)   // gs — constant fill alpha 0.5, stroke alpha 1.0
```

`SetAlpha` registers an `ExtGState` resource (deduplicated by `(fill,
stroke)` pair) and selects it with `gs`. Alpha values are in `[0,1]`.

## Example

```go
p.Save()
p.Translate(pdfkit.Mm(100), pdfkit.Mm(150))
p.Rotate(15)
p.SetFillColor(pdfkit.RGB8(0xef, 0x44, 0x44))
p.SetAlpha(0.6, 1)
p.Rectangle(pdfkit.Rect{X: -40, Y: -20, Width: 80, Height: 40})
p.Fill()
p.Restore()
```

Next: [Text & fonts](text-and-fonts.md) for embedding and drawing text, or
[Images](images.md) for placing JPEG/PNG artwork.
