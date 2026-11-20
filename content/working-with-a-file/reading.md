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

A predictor's row geometry is read from the file, so it is **refused when the
stream cannot back it**: a 102-byte *file* declaring `/Columns 977777777` asks
for a row of 932 MiB, and two of them at once. Past a megabyte, a row must
be backed by at least as many bytes as it claims; below that floor a short row
is still salvaged and zero-filled, because a damaged last row is legitimately
shorter than the bytes it needs. An absolute cap cannot express this — the
limit on a decoded stream is a gigabyte, and that row was just under it.

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

**Documents whose pages share objects are written** since v0.18.0, and that is
most multi-page PDFs. The route that reaches nearly all of them is
**inheritance**: Table 30 lets a page omit `/Resources`, `/MediaBox`, `/CropBox`
and `/Rotate` and take the page tree's, so one `/Resources` on the pages node is
reached by every page. The shared object hint table (F.4.2) now says which of
part 6's and part 8's objects each page after the first depends on, in the two
runs Table F.5 describes: every first-page object, counted positionally from
`/O`, then the objects shared only between later pages.

Earlier versions **refused** such a document. The table was written valid but
**empty** — true of a document whose pages are independent and a contradiction
for one whose pages are not — so `Linearize` returned an error rather than a
hint table that disagreed with the file.

{{< callout type="info" >}}
**What it still does not say is _where_ in a page a shared object is first
used.** F.4.1 items 5 and 13 are a fraction for that position, and this writer
states `0/1`: at the beginning. A reader may therefore fetch a shared object
earlier than it needs it, never later — a loss of precision rather than a wrong
answer.

Two more values are deliberately coarse. Every group describes exactly **one**
object, where F.4.2 allows a run of adjacent ones, which costs a few bytes and
cannot describe the wrong bytes. And a page that **borrows** a content stream
from an earlier page gets `0` for Table F.4's items 6 and 7: the stream lies
before the page, the items are unsigned, and no value is representable — the
same `0` a page with no content stream at all receives.
{{< /callout >}}

`Linearized` reads the parameter dictionary of a file somebody else wrote, and
`CheckLinearized` holds every parameter against the document — the two were
built before the writer, so that it would not be its own judge. `CheckLinearized`
recomputes the page and shared group **lengths** from the file; it does not yet
recompute Table F.5's first shared object offset, which `qpdf --check` does.

## Digital signatures

Since v0.20.0, `reader` **reads and verifies** a PDF's digital signatures
(ISO 32000-1 12.7.4.5). `Document.Signatures` lists the signature fields that
hold a signature: it walks `/AcroForm /Fields` and `/Kids`, bounded in depth and
in field count, and returns one `Signature` per signed field — the field name,
`/Filter`, `/SubFilter`, `/ByteRange`, the `/Contents` DER, the signer's claimed
`/Name`, `/Reason`, `/Location` and `/M`, `DictionarySigned` and
`CoversWholeFile`. `Document.SignedBytes` returns the bytes a signature covers,
after checking the `/ByteRange` against the file. Verification lives in the
sub-package `reader/signature`, on top of
[`go-authn/cms`](https://github.com/go-authn/cms):

```go
d, err := reader.Open(file)
// ...
results, err := signature.VerifyAll(d)
// ...
for _, r := range results {
    fmt.Println(r.Signature.Field, r.Err == nil, r.Signature.CoversWholeFile)
    // r.Certificates: hand to crypto/x509 and a revocation checker
}
```

`signature.Verify(d, sig)` does one signature. A bad signature does not hide the
others: `Signature.Err` holds the refusal and `VerifyAll` goes on.
`Signatures` itself fails only on a form too large or too deep to walk
(`reader.ErrTooManyFields`).

**What is verified.** `adbe.pkcs7.detached` and `ETSI.CAdES.detached`: every
signer's signature over exactly the `/ByteRange` bytes, by the certificate the
CMS names. Every other `/SubFilter` is refused with an error wrapping
`signature.ErrUnsupported`, and so are `adbe.pkcs7.sha1` and
`adbe.x509.rsa_sha1`: SHA-1 is refused by name. That is the one deliberate
difference from poppler's `pdfsig`, which calls a SHA-1 signature valid.

**A `/ByteRange` the file does not bear out is refused** (`reader.ErrByteRange`).
That is the signature-wrapping class of attacks: not exactly two ranges, a
negative number, a first range that does not start at 0, ranges that overlap,
descend or touch, a range past the end of the file, or a gap that is not exactly
one `<hex>` string.

**"Valid" and "the whole document" are two answers.** `CoversWholeFile` says
whether the ranges end at the end of the file. A signature followed by an
incremental update is valid and not whole; that is how forms are filled and
signatures stacked, and judging what the update changed is the caller's.

**What the signature covers.** `/Name`, `/Reason`, `/Location` and `/M` are
reported only when `DictionarySigned` is true, that is, when the signature
dictionary lies inside the signed ranges. An incremental update can point `/V`
at a new dictionary that copies the original `/ByteRange` and `/Contents` and
forges those claims, and the signature still verifies; so they are left empty
otherwise. The field name is never signed.

**Bounded per document.** `VerifyAll` verifies at most **64 distinct
signatures** and **1 GiB of signed bytes**; the rest come back with an error
wrapping `signature.ErrTooManySignatures`. The gaps of one document may decode
to 32 MiB in total.

{{< callout type="warning" >}}
**Trust is the caller's.** Whether the signing certificate chains to something
you trust, was valid when the signature was made, and was not revoked is not
decided here, as in `go-authn/cms`; nor is the signing time, which `/M` merely
claims.
{{< /callout >}}

It was checked against poppler's `pdfsig` 26.10.0 on fixtures signed by
OpenSSL: RSA, ECDSA and CAdES signatures valid; a file with an incremental update
after the signature, whose earlier signature is valid and not whole-file; two
stacked signatures; and seven tamperings of one fixture, refused by both. The
"whole document" answer is compared with `pdfsig` only where both say the
signature is valid. No encrypted signed file was checked against `pdfsig`.

## What the corpus says

Of **118 863** files, 118 833 open. The thirty that do not are 27 PNGs named
`.pdf`, one PostScript file, and two truncated past recovery.

**1 536 769 753** content operations read across them, using 70 real
operators. All 118 833 rewrite to an identical fingerprint, at 94.6% of the
input size with the packed writer, and all 118 833 encrypt and decrypt in
both AES methods.
