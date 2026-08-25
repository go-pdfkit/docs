# The browser workbench

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

## Every change is applied, written, and read back

Before it is drawn. So what is on the screen is what would come out of Save,
rather than a picture of what was meant to happen.

## How it is checked

The workbench is a plain Go type with no build tag, so a native test drives
the whole of it against a byte buffer: it opens a document built in the test,
presses a control **at a pixel on the strip** rather than calling its handler,
and looks at what got drawn.

Then in a real browser, over the DevTools protocol with nothing eyeballed:
Chrome loads the shell, the wasm starts, the file picker is intercepted and
handed a PDF, and the canvas pixels are read back to prove the page arrived.
That check runs in CI, and it earned its keep at once — a file arriving from
the browser has no event to be drawn on, so the canvas simply never changed.
