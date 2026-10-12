---
title: "Reading a page back"
weight: 50
---

[`extract`](https://github.com/go-pdfkit/extract) reads a page as words and
pictures.

```go
text, _ := extract.Text(d, 1)      // the page as words, lines put together
runs, _ := extract.Runs(d, 1)      // every piece, with its place and size
imgs, _ := extract.Images(d, 1)    // every picture, and where it lands
tabs, _ := extract.Tables(d, 1)    // the grids its text lines up into
```

`Lines` and `Join` are exported too, because the rule has to be the *same*
rule: `Text` uses them to put a page's text back together, and anything reading
structure out of a page — as [`document`](../as-a-document/) does — has to
agree with it line for line.

## A table is a stretch of page every row leaves empty

A column boundary is a stretch no row of the table draws anything in. The first
line of a block proposes its own gaps, each line after it takes away whatever
it draws in them, and a line that leaves nothing closes the block.

⛔ **Subtraction, not the intersection of the lines' gaps.** A cell whose text
wraps leaves a line with one piece of text on it and so no gaps of its own, so
intersecting ended the table there: a four-row table with one wrapped cell came
back as two tables of two rows.

Three things are not columns, each found by running this over real documents
rather than over a fixture, and measured on one 213-page document as each went
in — 588 tables, then 213, then 83, then 40:

| | |
|:--|:--|
| a **bullet** | a bulleted list *is* a two-column grid. What tells them apart is a column carrying no information: one or two characters with no letter and no digit in them. `A`/`B` are labels and `1990` is a date, so those stay. |
| a column **nothing was drawn in** | that is a stretch of page nothing was drawn in, which is what a boundary already is. |
| a line **far below** the row above | a page number sits in the left-hand column and draws nothing in any boundary, which is exactly what a row of a table does. |

The forty are that document's real `Code`/`Intitulé` pairs. A 3-page prose
report in the same run reports **none**, which is the control: a detector that
cannot say no to a paragraph says yes to every page there is.

⛔ **Ruled lines are not read.** This is the *text* strategy — the one a
bordered table does not need — so a table held apart by rules rather than by
whitespace is not found.

## A page does not hold text

It holds instructions for drawing glyphs, and the text is what those glyphs
were *meant* to say — which the document says only if it was asked to. Where
it does not, this **says so** rather than guessing: a run whose codes could
not be worked out comes back marked `Unreadable`, so a caller can tell *this
page says nothing* from *this page could not be read*.

Three things are tried, in order:

1. the font's `/ToUnicode` map, which is the document's own word on what its
   text says;
2. the name its encoding gives the code — but only a name **the document
   chose itself**, since a symbolic font read through an assumed encoding
   gives the wrong letter with nothing to say so;
3. what the **embedded font program** calls the code, which is the honest
   answer for such a font and the reason a page of mathematics comes back as
   mathematics.

Text drawn in the mode that puts no ink on the page — how a scanner writes
what it read underneath the picture it read it from — is returned and marked
`Invisible`.

## Pictures

A picture comes back as the file holds it, with the box it covers. A JPEG
comes out as a JPEG: re-encoding it would lose something for nothing. Turning
the other kinds into pixels means reading their colour space, which is
`render`'s work.

## What the corpus says

```
pages read         121946
  with text        94865 (77.8%)
  saying nothing   27081, of which 4812 did draw glyphs
characters         33976414 (17272226 of them letters)
runs               10797045
  unreadable       203607 (1.89%)
  invisible        29917
images             300685
panics             0
```

The 22% of pages that say nothing are figures — this corpus is arXiv's, and
most of it is plots. Of the pages that *did* draw glyphs and still said
nothing, nearly all are Type 3 fonts with no `/ToUnicode`: dvips bitmap fonts
whose glyphs are called `a1` and `s32`, which no reader can turn back into
letters.
