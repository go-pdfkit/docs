---
title: "Reading a file"
weight: 20
---

[`reader`](https://github.com/go-pdfkit/reader) is the parsing and writing
half: everything about the format itself, and nothing about what a page
means.

```go
d, err := reader.Open(bytes)          // or OpenWithPassword
fmt.Println(d.Version(), d.PageCount())

page, _ := d.Page(1)                  // with its inherited attributes
content, _ := d.PageContent(1)        // every stream, decoded and joined
ops, _ := d.PageOperations(1)         // and cut into operators
```

## What it reads

Objects and the lexer; cross-reference **tables and streams**, hybrid files,
`/Prev` chains and object streams; repair by scanning the file when the table
is wrong; the filters — Flate, LZW (with and without early change),
ASCIIHex, ASCII85, RunLength, and the PNG and TIFF predictors; the standard
security handler from RC4-40 through AES-128 to AES-256 revision 6; content
streams and inline images; the page tree with inherited attributes.

`Document.Protection` says how a file that opened was protected — the method
in words, the handler's revision, what it allows, and whether the password it
opened with was the owner's.

## Writing

`Writer` produces a file, and produces the **same bytes twice**:

```go
w := reader.NewPackedWriter("1.7")     // objects in compressed streams
pages := w.Reserve()
content := w.Add(&reader.Stream{Dict: reader.Dict{}, Raw: []byte("0 g 10 10 80 80 re f")})
page := w.Add(reader.Dict{"Type": reader.Name("Page"), "Parent": pages, "Contents": content})
w.Put(pages, reader.Dict{"Type": reader.Name("Pages"),
    "Kids": reader.Array{page}, "Count": reader.Integer(1)})
root := w.Add(reader.Dict{"Type": reader.Name("Catalog"), "Pages": pages})
out, _ := w.Finish(reader.Dict{"Root": root})
```

`Writer.Encrypt` protects everything written from there on, and
`Writer.Copy` brings an object across from another document with everything
it refers to.

## Linearizing

`Document.Linearize` rewrites an open document as a **linearized** file — ISO
32000-1 Annex F's eleven parts, so that a reader with byte-range requests can
show page one before the rest arrives:

```go
d, _ := reader.Open(in)
out, err := d.Linearize()
```

It writes both cross-reference sections, the parameter dictionary, and a hint
stream carrying Table F.3's page offset table and Table F.5's shared object
hint table. `qpdf --check` reports nothing about the result that it does not
also report about the input.

{{< callout type="warning" >}}
**It refuses a document that shares an object between pages,** and that is most
multi-page PDFs. The shared object hint table (F.4.2) is how a page after the
first says which objects it depends on, and this version writes a valid but
**empty** one — true of a document whose pages are independent, and a
contradiction for one whose pages are not, so `Linearize` returns an error
naming the objects instead of writing a hint table that disagrees with the file.

The route that catches most files is **inheritance**: Table 30 lets a page omit
`/Resources`, `/MediaBox`, `/CropBox` and `/Rotate` and take the page tree's,
and one `/Resources` on the pages node is reached by every page.

Written today: a one-page document; inheritable values that are **direct** (an
inline `/MediaBox` array refers to no object); each page naming its **own**
resources; and a sub-tree whose reference has one page under it. Pages that
share only the catalogue are written too — part 4 arrives ahead of the first
page, so nothing has to describe it.
{{< /callout >}}

`Linearized` reads the parameter dictionary of a file somebody else wrote, and
`CheckLinearized` holds every parameter against the document — the two were
built before the writer, so that it would not be its own judge.

## What the corpus says

Of **118 863** files, 118 833 open. The thirty that do not are 27 PNGs named
`.pdf`, one PostScript file, and two truncated past recovery.

**1 536 769 753** content operations read across them, using 70 real
operators. All 118 833 rewrite to an identical fingerprint, at 94.6% of the
input size with the packed writer, and all 118 833 encrypt and decrypt in
both AES methods.
