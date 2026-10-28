---
title: "HTML to PDF"
weight: 130
---

[`go-pdfkit/html2pdf`](https://github.com/go-pdfkit/html2pdf) (v0.3.0) turns
static HTML into a **vector** PDF: go-webengine lays the page out and the
result is written through pdfkit's text, rect and stroke calls, so the text in
the PDF is real text. No headless browser is involved.

## From Go

```go
doc, err := html2pdf.Export(src, html2pdf.Options{
    MarginMm: 20,
    Title:    "Q3 report",
    Author:   "A. Writer",
})
if err != nil {
    return err
}
f, _ := os.Create("out.pdf")
defer f.Close()
doc.Write(f)
```

`Options.Title`, `Author`, `Subject` and `Keywords` fill the PDF's
information dictionary; an empty `Title` is taken from the document's
`<title>`.

## Lists

Since v0.3.0 (go-webengine v0.18.0) list markers are painted: `::marker`,
every `list-style-type` (disc, circle, square, decimal, the alphabetic and
roman ones, `none`), and the `start`, `reversed` and `value` attributes of
`<ol>` / `<li>`. CSS escapes in `content` strings are decoded as CSS Syntax 3
says, and CSS counters are supported. HTML that wrote its own bullets as text
to work around this should drop them: they would print twice.

## Page numbers and a table of contents

Since v0.2.0 the page's CSS can print on every page and can refer to pages.
`@page` margin boxes ([CSS Paged Media 3, section
5](https://www.w3.org/TR/css-page-3/#margin-boxes)) — `@top-left`,
`@top-center`, `@top-right`, `@bottom-left`, `@bottom-center`,
`@bottom-right` — take a `content` of strings, `counter(page)` and
`counter(pages)`, and `font-size`, `font-family`, `font-weight`,
`font-style`, `color` and `text-align`:

```css
@page { size: A4; margin: 20mm;
  @bottom-center { content: counter(page) " / " counter(pages); font-size: 9pt } }
```

`target-counter(attr(href url), page)` ([CSS Content 3, section
2.6.1](https://www.w3.org/TR/css-content-3/#target-counter)) prints the page
that an `href="#id"` points to, which is what a table of contents needs:

```css
.toc a::after { content: target-counter(attr(href url), page) }
```

The layout is run again until the numbers are stable (at most four passes).
`leader()` is accepted and draws nothing. The corner and side margin boxes,
`target-counters()` and `target-text()` are not supported.

## From the shell

```sh
go run github.com/go-pdfkit/html2pdf/cmd/html2pdf@v0.3.0 --in report.html --out report.pdf
go run github.com/go-pdfkit/html2pdf/cmd/html2pdf@v0.3.0 --url https://example.org/report --out report.pdf
```

The command is built on cobra with POSIX flags: `--in/-i`, `--url/-u`,
`--out/-o`, `--base/-b`, `--margin/-m` (millimetres), `--media`,
`--image-dpi`, `--timeout`, and the information entries `--title`, `--author`,
`--subject` and `--keywords`. The single-dash spellings of earlier builds
(`-in`, `-out`, `-margin` and so on) are still accepted. Exit status 2 is a
usage error, 1 a runtime failure.
