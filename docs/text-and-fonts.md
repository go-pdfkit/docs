# Text & fonts

## Loading a font

```go
ttf, _ := os.ReadFile("font.ttf")   // or an OpenType/CFF ('OTTO') font
font, err := pdfkit.LoadFont(ttf)
```

`LoadFont` parses a TrueType (`glyf`) or OpenType/CFF (`OTTO`) font once. The
returned `*Font` is **immutable and may be shared** across documents and
goroutines — pass the same `*Font` to `SetFont` on pages in different
documents without reloading. Per-document glyph usage is tracked separately
by the `Document`, so sharing a `Font` never leaks state between documents.

```go
font.IsCFF()       // true for CFF/OpenType outlines, false for TrueType glyf
font.UnitsPerEm()  // the font's design grid size
font.NumGlyphs()   // glyph count
font.BaseName()    // PostScript name, used for the PDF /BaseFont
```

## Drawing text

```go
p.SetFont(font, 24)                          // Tf — select font and size (points)
p.Text(x, y, "Hello, pdfkit")                // Tj — baseline origin at (x, y)
p.TextLines(x, y, []string{"line one", "line two"}) // consecutive lines
```

`SetFont` registers the font with the document for embedding on first use.
`Text` and `TextLines` return `error` (a wrapped `errNoFont`-style error) if
no font has been selected yet.

Additional text state, all emitted inside the `BT`/`ET` text object:

```go
p.SetCharSpacing(0.5)   // Tc — extra spacing between glyphs, in points
p.SetWordSpacing(1)     // Tw — has no visible effect on Type0 fonts; provided for completeness
p.SetLeading(28)        // TL — baseline-to-baseline distance used by TextLines
p.SetRenderMode(pdfkit.RenderStroke) // Tr — see render-mode constants below
```

Render modes:

| Constant | Tr | Effect |
| --- | --- | --- |
| `RenderFill` | 0 | fill glyphs (default) |
| `RenderStroke` | 1 | stroke glyph outlines |
| `RenderFillStroke` | 2 | fill then stroke |
| `RenderInvisible` | 3 | neither — useful for an OCR text layer over an image |
| `RenderFillClip` | 4 | fill and add to clip |
| `RenderStrokeClip` | 5 | stroke and add to clip |
| `RenderFSClip` | 6 | fill, stroke and add to clip |
| `RenderClip` | 7 | add to clip only |

## Measuring and wrapping

```go
w := p.TextWidth("Hello, pdfkit")             // width in points at the current font/size
lines := p.WrapText(longString, pdfkit.Mm(170)) // greedy word-wrap to a max width
```

`WrapText` breaks on spaces; a single word wider than `maxWidth` occupies its
own line. Both return zero values when no font is selected.

## How fonts are embedded

Every font a page uses is written as a **Type0 composite font** with
**Identity-H** encoding:

- An **Identity CIDToGIDMap** (character code == glyph index).
- A per-glyph **`/W`** width array, so PDF viewers get correct advance
  widths without consulting the embedded program.
- A **`/ToUnicode`** CMap built from the runes actually drawn, so copy/paste
  recovers the original text.
- Only the glyphs actually drawn are embedded — the subset is computed from
  the document's recorded glyph usage at `Write` time, after all drawing has
  happened.

The outline format depends on the source font:

- **TrueType (`glyf`)** outlines embed as a **subsetted `FontFile2` /
  `CIDFontType2`**. `pdfkit` walks the `glyf`/`loca` tables, follows
  composite-glyph components so a subset never drops a referenced
  sub-glyph, and reassembles a minimal `sfnt` container (`subset.go`).
- **CFF/OpenType** outlines embed as `FontFile3` / `CIDFontType0`, currently
  with the **whole `CFF ` table** — charstring subsetting is not yet
  implemented (see [Scope and limitations](#scope-and-limitations)).

## Shaped text for complex scripts

```go
p.TextShaped(x, y, "بيت", "liga")
```

`TextShaped` runs the [go-opentype](https://github.com/go-opentype/opentype)
shaper's **GSUB substitution and GPOS positioning** tables against the
string, then places each resulting glyph individually with its own `Tm`
matrix, honouring per-glyph x/y offsets and advances. Use it for Arabic,
Indic, CJK, or any Latin text needing ligatures, mark attachment or kerning
that the default path doesn't apply. `features` names OpenType feature tags
to enable (e.g. `"liga"`).

The plain `Text` path stays a simple left-to-right codepoint→glyph (cmap)
mapping with no shaping — reach for `TextShaped` whenever script correctness
matters, and keep `Text` for simple Latin runs where the extra shaping pass
isn't needed.

## Missing upstream primitives

go-opentype/opentype decodes a font fully but does not expose the raw table
bytes, the units-per-em, the glyf/loca arrays, or a subsetting export that a
PDF embedder needs. `pdfkit` therefore **reparses the sfnt container it is
handed** (`sfnt.go`) and **implements TrueType `glyf` subsetting itself**
(`subset.go`), independently of go-opentype's own decoded model.

## Scope and limitations

- CFF/OpenType fonts embed their **whole `CFF ` table**; charstring
  subsetting is not yet implemented. TrueType fonts **are** fully
  glyph-subsetted.
- Encryption, tagged PDF / PDF-A, interactive forms and annotations are out
  of scope for v0.1.

Next: [Images](images.md) for placing JPEG/PNG artwork, or the
[API reference](api.md) for the complete signature list.
