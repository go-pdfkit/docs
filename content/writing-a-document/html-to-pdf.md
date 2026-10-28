---
title: "HTML to PDF"
weight: 130
---

[`go-pdfkit/html2pdf`](https://github.com/go-pdfkit/html2pdf) (v0.1.0) turns
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

## From the shell

```sh
go run github.com/go-pdfkit/html2pdf/cmd/html2pdf@v0.1.0 --in report.html --out report.pdf
go run github.com/go-pdfkit/html2pdf/cmd/html2pdf@v0.1.0 --url https://example.org/report --out report.pdf
```

The command is built on cobra with POSIX flags: `--in/-i`, `--url/-u`,
`--out/-o`, `--base/-b`, `--margin/-m` (millimetres), `--media`,
`--image-dpi`, `--timeout`, and the information entries `--title`, `--author`,
`--subject` and `--keywords`. The single-dash spellings of earlier builds
(`-in`, `-out`, `-margin` and so on) are still accepted. Exit status 2 is a
usage error, 1 a runtime failure.
