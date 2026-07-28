# Images

Three methods place raster artwork into a `Rect` given in points (the
rectangle's `X`/`Y` is its lower-left corner, matching PDF's coordinate
system):

```go
p.DrawImage(img image.Image, r pdfkit.Rect)      // any decoded image.Image
p.DrawPNG(data []byte, r pdfkit.Rect) error       // decodes PNG bytes, then DrawImage
p.DrawJPEG(data []byte, r pdfkit.Rect) error      // embeds JPEG bytes directly
```

## DrawImage

```go
f, _ := os.Open("chart.png")
img, _, _ := image.Decode(f)
p.DrawImage(img, pdfkit.Rect{
    X: pdfkit.Mm(20), Y: pdfkit.Mm(40), Width: pdfkit.Mm(80), Height: pdfkit.Mm(60),
})
```

`DrawImage` accepts any `image.Image` — the result of `image.Decode`,
`png.Decode`, a `*image.RGBA` you drew into, or anything else satisfying the
interface. It walks the image's pixels via `.At(x, y).RGBA()`, packs them as
8-bit `DeviceRGB` sample data, and **detects an alpha channel automatically**:
if any pixel's alpha is not fully opaque, an `/SMask` (DeviceGray soft mask)
is embedded alongside the colour data so partially transparent images
composite correctly. Sample data is always `FlateDecode`-compressed.

## DrawPNG

```go
png, _ := os.ReadFile("logo.png")
err := p.DrawPNG(png, pdfkit.Rect{X: 0, Y: 0, Width: 100, Height: 100})
```

`DrawPNG` decodes the bytes with the standard library's `image/png` and
calls `DrawImage` — a convenience for the common case, with the same alpha
and compression behaviour. It returns an error if the data isn't a valid
PNG.

## DrawJPEG

```go
jpg, _ := os.ReadFile("photo.jpg")
err := p.DrawJPEG(jpg, pdfkit.Rect{X: 0, Y: 0, Width: 200, Height: 150})
```

`DrawJPEG` embeds the **original JPEG bytes directly** with `DCTDecode` — no
decode/re-encode round trip, so image quality and file size are preserved
exactly. It parses just enough of the JFIF/EXIF marker structure to read the
frame's width, height and component count from the SOF marker, and maps
component count to colour space:

| Components | Colour space |
| --- | --- |
| 1 | `DeviceGray` |
| 3 | `DeviceRGB` (YCbCr JPEGs decode to RGB in the viewer) |
| 4 | `DeviceCMYK` |

An unsupported component count, or data that isn't a valid JPEG (bad SOI, a
corrupt segment, or no SOF marker at all), returns a descriptive error.

## Placement

All three methods place the image with the same graphics-state sequence:
`Save()` → `Transform(width, 0, 0, height, x, y)` → paint the XObject → `Restore()`
— so the image is mapped into exactly the rectangle you specify, regardless
of its native pixel dimensions. Each distinct image is registered once per
document as an `/Im<n>` XObject resource, even if drawn on multiple pages.

Next: the [API reference](api.md) for the complete signature list, or back to
[Text & fonts](text-and-fonts.md).
