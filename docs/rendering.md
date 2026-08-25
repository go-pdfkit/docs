# Drawing a page

[`render`](https://github.com/go-pdfkit/render) turns a page into pixels. It
reads with `reader`, rasterises with [go-gfx](https://github.com/go-gfx/gfx),
and outlines text with [go-opentype](https://github.com/go-opentype/opentype)
— so it builds for `js/wasm` and a PDF can be shown in a browser tab with
nothing on the far end.

```go
img, err := render.Page(d, 1, render.Options{DPI: 150})
```

`Options` takes a `Scale` or a `DPI`, a background colour, and a `MaxPixels`
that refuses a page a file made up rather than filling memory with it.

## What it draws

The transform stack, path construction and all ten painting operators;
filling under both winding rules; stroking with the caps, joins, miter limit
and dash pattern the graphics state carries; clipping, including clips that
intersect and are let go again; the device, calibrated, profile-based,
indexed, separation and pattern colour spaces; constant transparency; form
XObjects with their own matrix, box and resources.

Images at every bit depth and colour space, with a `/Decode` array, as
one-bit stencils painted in the colour in force, and with either kind of
transparency. A JPEG is decoded by the standard library; a format nothing
here reads is left undrawn rather than drawn wrong.

Text from an embedded **TrueType**, **OpenType**, **bare CFF** or
**PostScript Type 1** program, from a composite font addressed by character
identifier, or — for a Type 3 font, whose glyphs are little content streams —
by running them. A font whose program cannot be read still advances the pen
by its stated widths, so what follows stays where it belongs.

Gradients and patterns: axial and radial shadings painted on their own with
`sh` or used as a fill or a stroke; tiling patterns, coloured and uncoloured;
and all four kinds of PDF function, which are also what a Separation or
DeviceN tint transform is written in.

Mesh shadings and the standard fourteen faces are the waves that follow. The
corpus holds 371 mesh shadings of the fourth kind and 198 of the seventh,
against 19 923 axial and 5 589 radial ones.

## How it is checked

By writing a PDF whose geometry is known and looking at the pixels: a
rectangle from (10,10) to (40,40) on a hundred-point page has to be ink at
(25,75) and paper at (25,55), which is what says the page's coordinates — which
count up from the bottom left — were mapped the right way up.

Then on the corpus: **4 108 pages** drawn from 3 999 files with no panics and
six blank. When anything underneath changes, every page is drawn before and
after and its pixels hashed, and the biggest changes are put beside what the
operating system's own renderer draws.
