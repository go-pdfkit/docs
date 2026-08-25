# Editing together

[`coedit`](https://github.com/go-pdfkit/coedit) is a PDF several people are
editing at once.

## What is shared is not the file

A file is a settled thing. Merging two people's copies of one means merging
two piles of bytes, which cannot be done.

What is shared is the **plan**: which pages, from which files, in which
order, turned and cropped how, with which bookmarks over them. That is a
list, a tree and a handful of fields — and those are things a
[conflict-free replicated data type](https://github.com/go-crdt/crdt) merges
without asking anybody.

So two people reordering the same document keep both reorderings. Two people
rotating different pages keep both rotations. Two people rotating the same
page settle on one of the two, which is what rotating a page twice means.
**Nobody waits for a lock and nobody loses work, however many of them there
are.**

```go
plan := coedit.Open(store)
plan.Files().Put("report.pdf", bytes)
first, _ := plan.Append("report.pdf", 3)
plan.Rotate(first, 90)
plan.AddBookmark(coedit.AtRoot, coedit.BookmarkID{}, "Findings", first)
out, _ := plan.Bytes()
```

## Where the files live

A file goes in once and is referred to by name from then on, so a plan taking
three pages out of a hundred-page report carries the report once. The bytes
are cut into pieces **on their content** with
[go-deltasync/chunk](https://github.com/go-deltasync/chunk), so replacing one
page sends one piece rather than the file, and two files sharing their bytes
share their pieces.

Every piece lives under the hash of what it holds and the whole file's hash
travels with the list of them, so a peer cannot quietly put something else
there — and a file whose pieces have not all arrived is **not a file yet**,
which is what keeps a half-arrived document from being built.

## Where it runs

A plan needs two things from wherever it is kept: read a map, or change one
and say what changed. That is the whole `Store` interface. `Local` is a plan
held alone; a session over
[go-crdt/collab](https://github.com/go-crdt/collab) is the same two methods,
so the same plan rides a central WebSocket or a peer-to-peer data channel
without knowing which.

## How it is checked

Not that two people can edit it — that **any number** of them can:

* 25 editors, 40 rounds each, random edits merged in a random order, all
  agreeing on the same 189 pages and all building the same file;
* two groups of four who cannot reach each other for twenty rounds and then
  meet, with nothing either group did lost;
* an editor who leaves and comes back with a snapshot.

That harness found what two browser tabs would not: one person removing a
page while another turns it leaves the item behind, because a field written
after a removal puts the record back. What it does not put back is which file
the page came from — so that is what says whether there is a page there at
all.
