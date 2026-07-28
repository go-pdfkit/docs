# API reference

The full public surface of `github.com/go-pdfkit/pdfkit`. See
[pkg.go.dev](https://pkg.go.dev/github.com/go-pdfkit/pdfkit) for the
generated reference with source links.

## Document

```go
type Options struct {
    Title, Author string          // document information dictionary; empty = omitted
    Producer      string          // defaults to DefaultProducer ("go-pdfkit/pdfkit")
    Now           func() time.Time // nil = no timestamps (reproducible output)
    Compress      bool            // FlateDecode content/font streams
    ID            [2][]byte       // explicit trailer /ID; nil = content-derived
}

func New(opts Options) *Document
func (d *Document) AddPage(size PageSize) *Page
func (d *Document) Write(w io.Writer) error
```

`Document` is not safe for concurrent use. `Write` may be called more than
once — it doesn't consume the document.

## Pages and units

```go
func (p *Page) Width() float64
func (p *Page) Height() float64

func Pt(v float64) float64
func Mm(v float64) float64
func In(v float64) float64

type PageSize struct{ Width, Height float64 }
func NewPageSize(width, height float64) PageSize
func (s PageSize) Landscape() PageSize
func (s PageSize) Portrait() PageSize

var (
    A3, A4, A5, Letter, Legal, Tabloid PageSize
)

type Rect struct{ X, Y, Width, Height float64 }
```

## Graphics

```go
func (p *Page) Save()
func (p *Page) Restore()
func (p *Page) Transform(a, b, c, d, e, f float64)
func (p *Page) Translate(tx, ty float64)
func (p *Page) Scale(sx, sy float64)
func (p *Page) Rotate(deg float64)
func (p *Page) Skew(axDeg, ayDeg float64)

func (p *Page) MoveTo(x, y float64)
func (p *Page) LineTo(x, y float64)
func (p *Page) CurveTo(x1, y1, x2, y2, x3, y3 float64)
func (p *Page) Rectangle(r Rect)
func (p *Page) ClosePath()

func (p *Page) Stroke()
func (p *Page) Fill()
func (p *Page) FillEvenOdd()
func (p *Page) FillStroke()
func (p *Page) FillStrokeEvenOdd()
func (p *Page) EndPath()
func (p *Page) Clip()
func (p *Page) ClipEvenOdd()

func (p *Page) SetLineWidth(w float64)
func (p *Page) SetLineCap(style int)   // CapButt, CapRound, CapSquare
func (p *Page) SetLineJoin(style int)  // JoinMiter, JoinRound, JoinBevel
func (p *Page) SetMiterLimit(limit float64)
func (p *Page) SetDash(pattern []float64, phase float64)

func (p *Page) SetFillColor(c Color)
func (p *Page) SetStrokeColor(c Color)
func (p *Page) SetAlpha(fill, stroke float64)
```

## Colour

```go
type Color interface{ /* unexported */ }

type Gray struct{ V float64 }
type RGB  struct{ R, G, B float64 }
type CMYK struct{ C, M, Y, K float64 }

func RGB8(r, g, b uint8) RGB
```

## Fonts and text

```go
func LoadFont(data []byte) (*Font, error)

func (f *Font) IsCFF() bool
func (f *Font) UnitsPerEm() int
func (f *Font) NumGlyphs() int
func (f *Font) BaseName() string

func (p *Page) SetFont(f *Font, size float64)
func (p *Page) SetCharSpacing(v float64)
func (p *Page) SetWordSpacing(v float64)
func (p *Page) SetLeading(v float64)
func (p *Page) SetRenderMode(mode int) // RenderFill, RenderStroke, RenderFillStroke,
                                        // RenderInvisible, RenderFillClip,
                                        // RenderStrokeClip, RenderFSClip, RenderClip

func (p *Page) Text(x, y float64, s string) error
func (p *Page) TextLines(x, y float64, lines []string) error
func (p *Page) TextShaped(x, y float64, s string, features ...string) error
func (p *Page) TextWidth(s string) float64
func (p *Page) WrapText(s string, maxWidth float64) []string
```

## Images

```go
func (p *Page) DrawImage(img image.Image, r Rect)
func (p *Page) DrawPNG(data []byte, r Rect) error
func (p *Page) DrawJPEG(data []byte, r Rect) error
```

## Example

From the package's own `example_test.go`:

```go
func Example() {
    font, err := pdfkit.LoadFont(mustRead("testdata/SourceSerif4-Regular.otf"))
    if err != nil {
        panic(err)
    }

    doc := pdfkit.New(pdfkit.Options{Title: "Hello"})
    p := doc.AddPage(pdfkit.A4)

    p.SetFont(font, 24)
    _ = p.Text(pdfkit.Mm(20), p.Height()-pdfkit.Mm(20), "Hello, pdfkit")

    p.SetStrokeColor(pdfkit.RGB8(0x0d, 0x94, 0x88))
    p.SetLineWidth(2)
    p.MoveTo(pdfkit.Mm(20), pdfkit.Mm(20))
    p.LineTo(pdfkit.Mm(190), pdfkit.Mm(20))
    p.Stroke()

    var buf bytes.Buffer
    if err := doc.Write(&buf); err != nil {
        panic(err)
    }
    fmt.Println(strings.SplitN(buf.String(), "\n", 2)[0])
    // Output: %PDF-1.7
}
```

## Testing

`GOWORK=off CGO_ENABLED=0 go test ./...` runs the suite at **exact 100%
statement coverage**. Generated documents are re-opened with
[`rsc.io/pdf`](https://pkg.go.dev/rsc.io/pdf) to verify their structure, and
the embedded TrueType subset is re-parsed with go-opentype to confirm it
still contains the glyphs that were drawn. Tests are deterministic and
network-free: they use a synthesised TrueType font and a bundled OFL
OpenType/CFF font (`testdata/SourceSerif4-Regular.otf`).

BSD-3-Clause — see the
[LICENSE](https://github.com/go-pdfkit/pdfkit/blob/main/LICENSE) in the
`pdfkit` repository.
