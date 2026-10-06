# go-pdfkit docs

Hugo source for **<https://go-pdfkit.github.io/docs/>**.

```sh
hugo server     # preview
hugo --minify   # build into public/
```

## The theme is our fork of Hextra

```toml
# go.mod
require github.com/imfing/hextra v0.13.0
replace github.com/imfing/hextra => github.com/tannevaled/hextra v0.16.0
```

The fork keeps upstream's module path, so it is reached through a `replace`
rather than by importing a different path, and it is tagged independently and
ahead — `v0.16.0` against upstream's `v0.13.0`. **This repository is the first
in the fleet to consume it**, so the two lines above are the pattern the others
copy.

The build prints `hugo mod graph`, so a build that silently fell back to
upstream shows in the log rather than in the rendering.

## What this replaced, and why

MkDocs Material plus `mike`: a `requirements.txt`, a `pip install` and a Python
setup step in CI, to render a static site for an organisation whose whole
argument is that it needs no runtime but Go. **There is no Python here.**

The thirteen pages were converted by a small Go tool rather than by hand. It
checks the nav table against the tree **in both directions before writing
anything** — a page on disk the nav does not name, or a nav entry with no page,
is an error — then adds front matter, drops a leading `# Heading` that only
repeats the title, rewrites internal `.md` links to the sections the pages
moved into, and turns MkDocs admonitions into Hextra callouts.

⚠ That last one is why the conversion was read rather than trusted: an
admonition is delimited by **indentation**, so rewriting only its opening line
leaves the body indented four spaces — and Markdown renders that as a **code
block**. The first version did exactly that, and the opening line had converted
perfectly.

## Versioning

Not yet. `mike` published `/latest/` and a directory per version; this
publishes one current set. The fork carries a versioned-documentation kit added
on 2026-10-05, and adopting it is its own change: moving the generator and the
versioning scheme in one step would make a failure impossible to attribute.

## License

BSD-3-Clause.
