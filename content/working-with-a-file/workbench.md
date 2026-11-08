---
title: "The browser workbench"
weight: 70
---

[`app`](https://github.com/go-pdfkit/app) is a PDF workbench that runs in a
browser tab and nowhere else.

Open a file, turn its pages, rotate one, drop one, lay it out two to a sheet,
write across it, strip what runs rather than shows, save it back out — and
none of it leaves the machine, because **there is nowhere for it to go**. The
whole tool is one wasm binary the browser downloads once and a service worker
then keeps, so the second visit works with the network off and so does the
first, once loaded.

```sh
GOOS=js GOARCH=wasm go build -o web/main.wasm .
```

then serve `web/` over HTTP.

## What you can open

A PDF, of course. Also, because somebody who hands a file to a PDF workbench
wants a PDF of it:

- **a picture** — PNG, JPEG, GIF, WebP, TIFF, BMP, and the less common ICO,
  ICNS, PNM, QOI, JPEG 2000 and JBIG2. It becomes one page the size of the
  picture.
- **a drawing** — an SVG. It goes on the page **as paths**, so it stays sharp at
  any size and prints at any size. If the drawing uses a gradient, a clip path
  or an embedded photograph, those cannot be turned into path operators, so the
  page is a *picture* of the drawing instead — and the workbench says which of
  the two you got, because only the first keeps its sharpness.
- **a comic archive** — a `.cbz`, or any zip of pictures. Each picture becomes a
  page, in the order their **names** put them, so page 10 follows page 2 rather
  than page 1.

A `.docx` and an `.odt` are zips too. Opening one says what was found —
*"no pictures in the archive"* — rather than guessing; those formats convert
through `doc2pdf` rather than here.

Whatever you opened, the document is a PDF from that point on: every verb on the
ribbon works on it and Save hands back a PDF. A file called `book.cbz` opens as
`book.pdf`.

The **second** file may be any of these too. **Add a file after this one**, **Lay
another file over these** and **Mix another file in** take a picture, a drawing
or an archive exactly as Open does — so a scan goes after a document, a
signature lays over a page, and a photographed back page interleaves with the
front ones.

## The ribbon carries the verbs; the panel carries what they are told

The commands are a ribbon of seven tabs — **Home**, **Pages**, **Sheet**,
**Marks**, **File**, **Protect**, **Read**. Home holds the document itself:
Open, Save, Rotate, Previous, Next, Delete, and Fill in for a document that
carries a form.

That one sentence decides where every control goes. *Turn them* is a verb and
sits on the ribbon; *a quarter / a half / three quarters* is what it is told
and sits in the panel beside the page. **A tab is a panel**: choosing *Marks*
opens the Marks settings beside the page, because a group of verbs and the
settings those verbs read are the same subject seen twice.

Beside the page rather than over it, because nearly every verb changes the
document and the document is drawn from what would be saved — typing a crop box
and watching the page come back cropped is the whole point.

Every verb is one
[`toolkit.Action`](https://pkg.go.dev/github.com/go-widgets/toolkit#Action),
so a verb that cannot run greys on every surface showing it: the arrows at the
ends of a document, Delete on a document of one page, Fill in without a form,
everything with nothing open.

## Finding your way around

Down the left there is a rail you can widen by dragging its divider. It holds
two views of the same question — *where am I, and how do I get where I want* —
one above the other, with a divider of their own:

- the document's own **table of contents**, its `/Outlines` tree, each row
  indented by its depth and pressable to go to its page;
- the **minipages**, one numbered tile per page, each the shape of its own
  page, with the one you are reading marked.

A document that carries no outline gets **the links it carries** in the top
pane rather than nothing. Most documents carry no outline, so a contents view
offered only to the minority is one nobody finds — this one shipped that way
once and was reported missing by somebody running the build that added it.

The fallback was a list of pages first, and that was the wrong thing. A link is
structure the **author** wrote: *this phrase leads there*. A list of pages is
arithmetic over the document — the same list for every file of the same length,
telling a reader nothing they could not get by counting.

Each row says **the words the link sits on**, because that is the only name a
link has: a PDF link is a rectangle and a destination, and nothing in it is a
title. A link with no words under it — an image that is a link, a link over a
blank area of a scan — keeps its row and names where it goes instead.

A link that **leaves** the document is shown and not followed. Pressing it says
where it would go, at the bottom of the window. Nothing leaves this tab, and
that includes you.

Past a thousand links the last row says how many were left out, because a list
that stops without saying so misrepresents the document.

A list of pages is still what a document carrying neither an outline nor a link
gets. A document that labels its pages something other than their position —
`iv`, `A-2`, a plate number — says both, because the label is what its own index
refers to and the position is what every other control counts in.

**Widening the rail redraws the minipages at their new size.** Each tile is a
page put through the renderer at the rail's width, so they are re-made when you
let go of the divider rather than on every frame of the drag — dragging a rail
to a width you have not chosen yet should not render the whole document a dozen
times on the way there. Until you let go, the tiles are the pictures you had,
scaled into the new boxes.

For a release they never came back. Dropping the pictures so they could be made
*again* at the new width was only half the arrangement, and nothing performed
the other half: you were left with the pictures made for the old width,
stretched. A second defect sat under it — a repaint arriving in the middle of
the gesture rebuilt the band, and with it the divider you were holding, so the
drag stopped after one frame. Both were found by driving a real browser and
performing a real drag, which is now part of every check: the one thing that
could not be done from a test was the gesture the feature is made of.

## Selecting the words on a page, and marking them

Drag across a page to select its text. **Copy the words** on the Read tab puts
it on the clipboard and Escape lets go; a press anywhere else — the scrollbar,
the rail, the panel, a form being filled in — keeps the press it always had.

With words selected, the same tab offers **Highlight**, **Underline**, **Strike
out** and **Squiggle under** — the wavy line that means *look at this again*,
which is what a reviewer draws under a sentence they are not striking out. Each
says how much it marked — *"highlighted 17 characters on 1 page"* — and lets the
selection go, because a mark lands in the file rather than on the screen, and a
verb that worked in silence is one you press twice.

All four are real text-markup annotations, so another reader's PDF viewer shows
them, their notes can be read, and any of them can be taken off again.

A page is a **picture**, so none of this comes for free. The viewer shows
rasterised pages and nothing in it is text; the glyphs are read separately and
placed where they are drawn, from the same layout the pages are rendered from,
so the text cannot drift from the picture it sits on through a scroll, a zoom, a
page flip or a resize. Rendering the pages as vectors later would not change
that: a PDF renderer turns every glyph into an outline before it paints, so the
output holds paths and no text at all.

The selection is grouped **one run per word**. A PDF sets glyphs one at a time —
a real page measured here has 152 runs for four lines — so a reader who selected
a line and copied it once got `t h e f i r s t c h a p t e r`. A PDF never draws
a space either; it moves the pen. Where a word ends is therefore a judgement
about the gap to the next glyph, and a face that reports an unbelievable width
for its own space is distrusted.

A mark is an **annotation, not ink**. ISO 32000-1 §12.5.6.10: a text-markup
annotation carries `QuadPoints`, the corners of the quadrilaterals it covers, in
the page's own user space. The page's content stream is untouched, so the words
under a highlight stay selectable, searchable and extractable, and the mark can
be deleted again by anything that edits annotations. There is one quadrilateral
per run, so the mark has the same shape as what you saw lit rather than one box
drawn around it all — and one annotation per page, because no annotation can
span two of them.

That the mark lands where the highlight was is the one thing worth insisting on.
The rectangles written into the file are **the rectangles the selection paints**:
the toolkit returns them and drawing the highlight is a loop over that same
list. Deriving them twice — once to light the screen, once to write the file —
would mean two implementations of one rule, and the first time they disagreed
the saved document would be wrong while the screen looked right.

The count is characters rather than quadrilaterals for the same reason a reader
can check it. A quadrilateral is not something you can see, and how many there
are depends on how the file was produced: the page measured here would report
three for one line of text, and a page drawing that line in one go would report
one.

## Redacting a passage

**Redact**, on the same tab as the selection, takes the selected words **out of
the file**. It is the only verb there that destroys anything, and the only one a
saved document cannot be talked out of.

⛔ **It is not a black rectangle.** A rectangle drawn over a paragraph is the
standard data leak: the text stays in the page's content stream, so anyone can
copy it out from under the box, and a command-line reader prints it. So this
removes the operator that drew the text, and says which it did — *"removed 17
characters from 1 page — the text is gone from the file, not covered"*.

ISO 32000-1 §12.5.6.23 is explicit about the difference. A conforming reader
applying a redaction *"shall remove all traces of the specified content"*, and
*"clipping or image masks shall not be used to hide that data"*.

⛔ **And it refuses, out loud, where it cannot remove the words completely.** The
refusal names the page and the reason, because that reason is the useful part: a
reader told *"this line is drawn in one piece, and taking it would take more
than you asked for"* can select the whole line instead. A workbench that
swallowed the refusal and drew a box over the words would be the leak.

It refuses a passage that is:

- inside a **form XObject** — those bytes are shared with every page that draws
  it, so cleaning one page would change the others;
- across an **image** — the spec requires the pixels themselves to be
  destroyed, which is not yet done, and a mask over them is exactly what the
  spec forbids;
- under an **annotation** — a note, a highlight or a form field holds text of
  its own, which can be the very words;
- drawn by **one operator that also draws words outside the selection** —
  removing it would take text nobody asked about. A redaction betrays its
  reader in two directions, and removing too much is the quieter one.

The commonest refusal is the one you walk into: **highlight a passage, then
decide to redact it.** The highlight is an annotation over those words and its
note can quote them, so it has to go first.

Where the words are is decided **once**, by the same arithmetic the marking
verbs use. Marking and redacting are opposite acts — one is written over the
page and comes off again, the other takes the text out — but they are the same
question about *where*, and a reader who highlights a line and then redacts it
gets the same words both times.

## Drawing a picture on the pages

**Draw a picture on them**, on the Marks tab, puts a signature on a contract, a
logo on a letterhead or a seal on a certificate. Choose where it goes and how
wide it should be, in points, and then choose the picture.

The width is what sizes it, and only the width: the picture keeps its own
proportions, so a wide logo stays wide. The default is 144 points — two inches,
which is about what a signature wants on a letter.

It goes on **every page** unless *Which pages* beside it says otherwise, the
same as a watermark or a stamp.

## Redrawing the pages, and what it costs

The File tab has a group called **Redraw the pixels**: **Turn them inside out**
for reading at night, **Drop the colour**, **Draw them on a colour** (cream for
reading, grey for proofing, black for the night), **Brighten or deepen them**,
and **Make them look scanned**. On the Read tab, **Hand it over as a comic**
writes the pages as a `.cbz`, the archive a comic reader opens as a book.

⛔ **Every one of them replaces each page with a picture of it.** Afterwards
nothing can select a word, search the document or read it out, and the file
gets bigger rather than smaller. Each tip says so before you press, and the
status line says so after: *"⚠ the pages are pictures now: their text cannot be
selected, searched or read out any more"*.

That is not a shortcoming of these verbs. Turning light into dark is an
operation on pixels and there is no other way to do it. It is said this loudly
because the trade is invisible at the moment you make it: the page looks right,
you save, and what you have kept is a photograph of a document.

So: redraw to **read**, and keep the original. Redraw to **send** only when a
picture is what you meant to send.

Three things worth knowing before you press:

- **The scanner always does the same thing.** Two runs over the same file give
  the same pages — the skew, the grain and the fade are fixed, not random — so
  a redrawn file can be compared, cached or checksummed like any other.
- **Brightness and contrast are percentages**, and *contrast 100 means leave it
  alone*. 0 would flatten every page to grey, so it is read as 100 instead.
- **Choose the colour before pressing** *Draw them on a colour*: with *leave it
  white* chosen the verb says so rather than redrawing the pages for nothing.

**Hand it over as a comic** and **Hand over every page, zipped** hold the same
one picture per page. The difference is the name: a comic reader opens the
`.cbz` and not the `.zip`.

## Every change is applied, written, and read back

Before it is drawn. So what is on the screen is what would come out of Save,
rather than a picture of what was meant to happen.

**A change.** Going to a page is not one: the only difference it makes is
which number is lit, and it used to pay that whole bill anyway — on a
forty-page sample, one press on a minipage wrote 8 422 bytes, parsed them back
and re-rendered twenty pages, both of which grow with the file. A test counts
the writes a navigation makes and fails on any; its control is a verb, which
must still make them.

## Which build you are running

The status line names it, bottom right, on the empty workbench as well as an
open document: `v0.19.0-2-g0aecb79` is the tag it was cut from and how far
past it the commit is.

That is the one question you cannot answer by looking, because **an old binary
and a missing feature are the same screen** — and this family has already paid
for it: a cache-first service worker once kept five releases in a row from
everybody who had visited before, and it was reported as the layout
regressing. The deploy passes `git describe` through `-ldflags -X` and then
greps the built wasm for the string, because a `-X` naming a variable that no
longer exists is accepted in silence.

## A canvas has no DOM, so the workbench says where its controls are

Everything is painted into one framebuffer, so anything driving the workbench
from outside has nothing to find by name. `window.pdfkitControls()` publishes
the ribbon's own answer: every tab, every verb the tab now shows, whether each
may be used, and where the page and the panel are.

It exists because the alternative is guessing. The browser check used to sweep
the old button strip from `x=0` to `x=1000` and call whichever press opened a
file picker *Open* — which could never say **which** verb it had run, and is
out of reach entirely once controls sit on several rows of several tabs.

## How it is checked

The workbench is a plain Go type with no build tag, so a native test drives
the whole of it against a byte buffer: it opens a document built in the test,
presses a control **where the ribbon drew it** rather than calling its handler,
and looks at what got drawn. `Ribbon.ControlRect` is the ribbon's own answer to
where a control ended up, so the press follows the layout instead of a second
copy of it.

Then in a real browser, over the DevTools protocol with nothing eyeballed:
Chrome loads the shell, the wasm starts, the file picker is intercepted and
handed a PDF, and the pixels **where the page is drawn** are read back to prove
it arrived. The check then chooses the *Marks* tab, watches its panel appear,
presses the watermark verb, returns to *Home*, saves, and parses `(DRAFT) Tj`
out of the bytes that came back.

That check runs in CI, and it earned its keep at once — a file arriving from
the browser has no event to be drawn on, so the canvas simply never changed.
It earned it twice: its page band was written as *fractions of the canvas*, and
the moment the band above the page grew, the pixel every other pixel was
compared against was a pixel of the ribbon. **A band a caller works out for
itself goes stale silently — it still counts pixels, of something else.**
