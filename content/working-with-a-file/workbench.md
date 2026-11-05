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

```
GOOS=js GOARCH=wasm go build -o web/main.wasm .
```

then serve `web/` over HTTP.

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

A document that carries no outline gets a **list of its pages** in the top
pane rather than nothing. Most documents carry no outline, so a contents view
offered only to the minority is one nobody finds — this one shipped that way
once and was reported missing by somebody running the build that added it. A
document that labels its pages something other than their position — `iv`,
`A-2`, a plate number — says both, because the label is what its own index
refers to and the position is what every other control counts in.

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
