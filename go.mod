module github.com/go-pdfkit/docs

go 1.27.1

require github.com/imfing/hextra v0.13.0

// ⛔ The theme is OUR FORK, not upstream. It keeps upstream's module path, so
// it is reached through a replace rather than by importing a different path —
// and it is tagged independently and ahead: v0.16.0 against upstream's v0.13.0.
//
// go-pdfkit/docs is the FIRST repository in the fleet to consume it, so this
// is the pattern the others will copy.
replace github.com/imfing/hextra => github.com/tannevaled/hextra v0.16.0
