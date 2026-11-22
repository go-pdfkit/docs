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

## A PDF page as SVG

Since `convert` v0.17.0 a page can also come back as a **drawing** instead of
pixels:

```
$ pdfconv to-svg [-pages 1,3,5-9] [-password-file f|-] [-o dir] in.pdf
$ pdfconv to-svg -pages 1-3 -o ./svg scan.pdf      # scan_svg.zip
$ pdfconv to-svg -pages 2 -o ./svg scan.pdf        # scan.svg
```

One selected page is `name.svg`; several are `name_svg.zip` holding
`page_N.svg`, the way BentoPDF names them. `-pages` is an addition (BentoPDF
offers no page selection). The shape follows the pages *selected*, so `-pages 2`
of a long file is a single `.svg`. One PDF is one run: BentoPDF also takes
several PDFs at once into one zip, and this does not.

In Go, `convert.StreamSVG` hands the pages over one at a time,
`convert.NewSVGArchive` writes the zip as they arrive, and `convert.PDFToSVG`
and `convert.SVGArchive` do the same with every page held in memory.
`convert.SVGEntryName(n)` is `page_n.svg`; no byte of the PDF reaches an entry
name.

```go
err := convert.StreamSVG(pdf, convert.SVGOptions{Pages: []int{1, 2}},
    func(page, of int, svg []byte) error {
        return os.WriteFile(fmt.Sprintf("page_%d.svg", page), svg, 0o644)
    })
```

Paths, clips, images and transparency groups become SVG elements, and text
becomes **outlines**, so the file needs no font. What SVG 1.1 cannot say
(tiling and shading patterns, soft masks) is drawn by the pixel renderer and
embedded as an `<image>` where it falls.

⛔ **All or nothing.** The first page that cannot be written stops the run, the
error leads with the page number, the exit status is 1 and **no file is left
behind**: a zip with page 4 of 9 missing opens, counts and looks complete. The
pages are streamed into a temporary file in the output directory, so the peak
memory is one page, and the file takes its name only when every page is in it,
never over an existing file and never through a link.

⚠ **A page with millions of operators is expensive to parse.** One such page
can use about 1 GiB while its content stream is parsed, before the output limit
below applies (go-pdfkit/render#146).

The input is untrusted, and everything is bounded before it is spent:

| bound | value |
|---|---|
| pages in one run | 1000 (`convert.MaxSVGPages`) |
| SVG of one page | 64 MiB (`convert.DefaultSVGPageBytes`) |
| SVG of the whole run, hence the zip | 256 MiB (`convert.MaxSVGBytes`) |
| time for the whole run | 5 min (`convert.MaxSVGRunTime`) |
| time for one page | 10 s (`convert.DefaultSVGPageTime`) |

{{< callout type="warning" >}}
**Two limits of the renderer show through.** The time limit is a request, not a
promise, while [render#142](https://github.com/go-pdfkit/render/issues/142) is
open: render's deadline is checked only now and then, and one page has been
seen to overrun it about seventy times. And clips nested past 64 are refused
(`render.ErrSVGTooDeep`) until
[render#143](https://github.com/go-pdfkit/render/issues/143) gives it a raster
fallback.
{{< /callout >}}

### Passwords: `-password` is gone (breaking)

⛔ **`-password` was removed from `to-svg`, `from-pdf`, `to-archive` and
`redraw`**, because an argument is visible in `ps` and stays in the shell's
history. It is a **breaking** change of the command line (a MINOR bump, below
v1). Replace it with `-password-file`:

```
$ pdfconv from-pdf -password-file pw.txt -o pages/ locked.pdf
$ printf '%s' "$PW" | pdfconv redraw -password-file - locked.pdf out.pdf
```

`-password-file <path>` reads the password from a file, `-password-file -` from
standard input; one trailing newline is stripped, and at most 4096 bytes are
read. The Go API never took a password on a command line and is unchanged.

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
