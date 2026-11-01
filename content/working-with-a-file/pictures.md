---
title: "Pictures in and out"
weight: 45
---

[`convert`](https://github.com/go-pdfkit/convert) is the pair of jobs either
side of [drawing a page](../rendering/): pictures into a PDF, and a PDF back
into pictures.

```go
pages, _ := convert.FromPDF(pdf, convert.RasterOptions{
    DPI:     150,
    Format:  "webp",
    Quality: 80,
})
for _, p := range pages {
    os.WriteFile(fmt.Sprintf("page%03d.webp", p.Number), p.Data, 0o644)
}
```

From the command line that is `pdfconv`:

```
$ pdfconv from-pdf -format webp -quality 80 -o pages/ report.pdf
$ pdfconv formats
```

## What can be read and written

| | |
|---|---|
| **read** | PNG, JPEG, GIF, BMP, TIFF, WebP, PSD |
| **write** | PNG, JPEG, GIF, BMP, TIFF, WebP |

{{< callout type="info" >}}
`pdfconv formats` answers this by **asking the package**, not by reciting a
list somebody typed. A list in prose is a snapshot of what its author believed
that day — two flag descriptions here went on naming five formats after a
sixth became writable, and nothing failed, because a help string is prose.
{{< /callout >}}

**A format that can be read and not written is refused by name.** PSD is the
one in that position: the flattened composite Photoshop leaves at the end of
the file reads perfectly well, and writing a layered document is a different
job. "I do not know that format" would be a lie, and writing a PNG under a
`.psd` name would be worse than either.

## An SVG stays vector

An SVG is not in the table above, because it is not a picture: it is a drawing,
and a PDF can hold the drawing itself. `convert.SVGToPDF` turns its outlines
into PDF path operators, so the page scales without pixels and a figure that
would be tens of kilobytes of raster is about a kilobyte of geometry.

⛔ **What makes that safe is the refusal, not the translation.** Two vector
languages look alike until you meet the parts that do not correspond —
gradients in two unit systems, clip paths, embedded rasters — and a converter
that silently drops those produces a file that opens and is quietly wrong,
which is worse than a picture. go-gfx's `svg.Walk` **reports** what it could
not hand over, so a document using one of them is **drawn whole** instead.
There is no third outcome where some of it survived.

`convert.SVGToPDFVector` is the same translation without the fallback, for a
caller who would rather be told no than be given a picture.

Measured: the page rendered from the vector PDF against go-gfx's own drawing of
the same SVG differs by a mean of **0.03 of 255** per channel, with a blank
page of the same size scoring 38.19 as the control — the measure can tell
drawing from nothing. `qpdf --check`, `mutool info` and ghostscript all accept
the output.

{{< callout type="info" >}}
`DPI` is consulted only when the document is drawn. On the vector path it has
nothing to say, because the output has no resolution — the same document at 72
and at 144 is byte for byte the same file.
{{< /callout >}}

## WebP writes in both of its codecs

⛔ **Quality 100 means the lossless codec**, not the finest lossy one. They are
two different codecs — VP8L is always exact, VP8 never is — and which one wins
depends entirely on the page:

| | lossless | lossy at 50 |
|---|---:|---:|
| a 160×160 detailed page | 10 586 B | **886 B** |
| a flat swatch | **102 B** | 176 B |

A VP8 frame carries a fixed header — 1 056 bits of *"every coefficient
probability is unchanged"* alone — that a nearly empty picture can never pay
back. So the knob has to reach both codecs, and the only honest place to put
the boundary is the end of the range.

Both are written by [go-images/webp](https://github.com/go-images/webp), in
pure Go. Until it existed the fleet could **read** WebP and not write one.

## The content decides the format, never the name

A scanner writing JPEG into `page.png` is ordinary. A converter that believed
the extension would hand the decoder the wrong reader, or refuse a file it can
read perfectly well.

## Only the DPI says which page a picture is

2480×3508 is A4 at 300 dots to the inch, and a page a metre tall at 72. A
picture carries no paper size of its own, so one has to be chosen, and fitting
onto paper uses **one scale for both axes** and only ever shrinks — enlarging a
small picture to fill a page makes it blurry and nobody asked for that.
