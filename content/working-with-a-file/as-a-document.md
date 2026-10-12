---
title: "Reading it as a document"
weight: 55
---

[`document`](https://github.com/go-pdfkit/document) reads a PDF back as
headings, paragraphs, lists and tables, into the
[richdoc](https://github.com/go-richdoc/richdoc) model — which gets Markdown,
reST and HTML out of a PDF through code the fleet already has.

```go
doc := document.Parse(src)      // every page, in order
md, _ := markdown.Write(doc)    // and out as Markdown

for _, p := range document.Pages(src) {
    // p.Number, p.Blocks — a page at a time, for indexing
}
```

From the command line, that is `pdfops markdown`:

```sh
pdfops markdown report.pdf > report.md
pdfops markdown -json report.pdf    # one record per page, for a retrieval pipeline
```

## A PDF has no headings

It has instructions for drawing glyphs at places. Everything a reader sees
above that — this line is a heading, those three are a list, that block is a
table — is an **inference** from where the places are and how big the glyphs
were.

Worth saying plainly, because "convert a PDF to Markdown" suggests the
structure was in there and merely needed a different spelling. It was not. A
PDF is the output of a typesetter, and this reads the typesetter's work
backwards.

There is also **no error to return**. A page that cannot be *read* is an empty
page, which is an answer rather than a failure, and an error that is always
nil would teach every caller to write a branch that never runs.

## What a heading is

Text set larger than the body, where the body size is the one the document
draws the most *characters* at, over every page.

⛔ **But larger is not enough.** A nine-page report set in 10, 12 and 14 point
came back with **131 headings, 130 of which were paragraphs of prose**: the
report has two body sizes, and "most popular" can only pick one.

So a heading size also has to be **rare**, which is what a heading is — a line
or two per section against paragraphs per page. Measured over six real
documents, as the share of characters at each size *above* that document's own
body size:

| | |
|:--|:--|
| heading sizes | 0.01% – **5.76%** |
| second body sizes | **32.6%** – 39.4% |

An order of magnitude apart, and the threshold sits between them at 15%.

## The headings are found before the tables

A numbered heading leaves a gap after its number. The table below it leaves
that same gap empty on every row. So asking the page for its tables returns
**one two-column table that is the heading and the grid together** — and the
grid's real columns are gone, because the heading's own text reaches across all
of them:

```text
| 2. | Vue d’ensemble technique |
| --- | --- |
|  | HGX B300 GH200 NVL32 GB200 NVL36 GB300 NVL72 |
```

Nothing in the alignment says that line is a heading. Its **size** does, and
`document` is the only package that knows which sizes those are, so the tables
are looked for among the lines that are not headings.

## Joining a line to the one above

⛔ **No space after a hyphen**, because that is where a typesetter broke a
word: `cadre man-` and `ager` joined with a space is `man- ager`, which is not
what the page says.

⛔ **And the hyphen stays.** Dropping it reads `manager` — right there, wrong
for `well-known` broken at its own hyphen, and the two cannot be told apart
without a dictionary of the document's language. Keeping it loses nothing a
reader cannot undo.

## What it does not read

Multi-column page layouts, footnotes, ruled lines, and the reading order of a
page whose text was drawn out of order. Two tables side by side on one page are
read as one, because a table's box says where its words are and not which
words.

A numbered list laid out as "number here, text there" is read as a two-column
**table**, which keeps both the number and the text in cells of their own.
Taking `1.` as a list marker would mean deciding that `1990` at the start of a
line is one too, and a table of dates is nothing but those.
