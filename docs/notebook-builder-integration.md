# Layerbooth as the gravity-press page editor

Status: design, 2026-09-04. Nothing in gravity-press is changed by this document.

## The idea

The notebook builder on gravity-press.com lets a person assemble a book from
pages. Today each page is a configuration of one of the proven renderers
(lined, dot, grid, polar, prompt, image) expressed as a PageSpec v1: one
Ground, then Structure, Content and Overlay layers, composed by one
compositor. Layerbooth becomes the editor for the **Ground**: the surface the
person designs, which the ruling and text are then drawn on.

Everything Layerbooth produces already fits the grammar. `layerbooth page`
emits a PageSpec whose Ground is an `image` or a `wash`, with any Structure
layer on top. The compositor renders it unchanged; the PDF composer embeds it
as an image XObject. So the integration is about workflow and assets, not
about a new page type.

## Roles

| Layer (S01)   | Who owns it              | Layerbooth's part                                    |
|---------------|--------------------------|------------------------------------------------------|
| Ground        | Layerbooth               | Gradient, colour, image, SVG, warp and edge layers    |
| Structure     | gravity-press renderers  | Chosen in the builder; Layerbooth previews it on top  |
| Content       | gravity-press            | Not touched                                          |
| Overlay       | gravity-press (S04)      | A recoloured prime SVG is a natural `ornament` later  |

Camera layers are optional. A notebook page is usually pattern-only, so the
default input is blank and the camera never has to exist on the builder host.

## The editor surface

One panel, no modes. The SVG tools sit first because they are the vector
heart of the product, but the image tools stay in plain sight; both are
entries in the same Add menu and share the same fit, scale, position,
rotation and blend controls.

Add menu, in this order:

1. **Prime pattern** — the six fractal-core modes for any prime, fetched from
   `api.fractal-core.com`, with colour scheme. Lands as an SVG layer with
   stroke recolouring and stroke width.
2. **SVG** — upload or URL. Same controls.
3. **Image** — JPEG, PNG, WebP, GIF. Upload or URL.
4. **Warp** — geometry effects driven by any SVG or image on the page:
   displace, refract, emboss, contour, chroma, flow, kaleidoscope, tilt.
5. **Gradient**, **Colour**, **Edges**.
6. **Camera** — present but last; only meaningful where a camera exists.

Below the stack: the page settings that belong to the builder, previewed
live in the same canvas so the person sees the ruling on the surface they
are designing:

- **Size**: every Lulu trim (see below), shown as name and inches, drawn at
  the true aspect ratio.
- **Ground strength**: image (full) or wash with an opacity slider. Wash is
  the right default for pages people will write on.
- **Structure**: none, lines, dots, grid, polar, using the renderer defaults;
  the renderer's own configurator opens for detail.

Presets remain "looks" and carry the whole stack; the builder stores a look
per page, so a notebook can vary page by page or repeat one template.

## Assets: deduplicate, then compress

Data URIs are fine for one page and wrong for a book. The builder should hold
a content-addressed asset store and pages should reference into it.

- **Address**: `asset:<sha256>` in `ImageLayerConfig.src`, which the schema
  already allows and the compositor already resolves through a resolver hook.
- **Dedupe**: the hash is of the rendered ground bytes, so 64 pages made from
  one template share one file; two looks that render identically also share.
  Layerbooth's `--assets DIR` does exactly this on the CLI today.
- **Source assets** (the uploaded SVGs and images that looks reference) are
  also stored by hash. Layerbooth already names uploads `<stem>-<sha10>.<ext>`;
  in the builder they move to the same store, and looks reference them by
  hash rather than by path, which makes looks portable between machines.
- **Format**: PNG for pattern-only grounds (SVG, gradient, colour, edges), JPEG
  for anything containing a photo. Layerbooth's `--image-format auto` applies
  this rule; PNGs are re-compressed with ImageMagick when available. WebP is
  not used for grounds because the PDF composer embeds DCT (JPEG) and Flate
  (PNG) streams directly and would have to transcode WebP.
- **Resolution**: 150 dpi is enough for a wash under handwriting; 300 dpi for
  a full-strength image ground on a cover-quality page. The builder picks by
  ground strength; the person can override.
- **Ceiling**: a Lulu interior PDF is cheapest under a few hundred MB. Sixty-
  four pages of a single 300 dpi JPEG ground at 6×9 is about 20 MB total with
  dedupe, and 64 distinct grounds about 60–100 MB. That is the budget the
  builder should show while a book is being assembled.

## Sizes

Lulu's public OpenAPI spec names these trim codes (hundredths of an inch,
width × height):

| Code        | Size            | Name        |
|-------------|-----------------|-------------|
| 0425X0687   | 4.25 × 6.875 in | Pocket Book |
| 0500X0800   | 5 × 8 in        | Novella     |
| 0550X0850   | 5.5 × 8.5 in    | Digest      |
| 0583X0827   | 5.83 × 8.27 in  | A5          |
| 0600X0900   | 6 × 9 in        | US Trade    |
| 0700X1000   | 7 × 10 in       | Executive   |
| 0827X1169   | 8.27 × 11.69 in | A4          |
| 0850X1100   | 8.5 × 11 in     | US Letter   |

Lulu's pricing calculator also lists Royal (6.14 × 9.21), Crown Quarto
(7.44 × 9.68), Comic (6.625 × 10.25), Small Square (7.5 × 7.5), Square
(8.5 × 8.5), and landscape variants; their exact codes should be confirmed
against Lulu's downloadable product sheet before they enter the enum, since a
wrong `pod_package_id` fails at order time, not at build time.

gravity-press's `PaperSize` enum (LETTER, A4, A5, HALF_LETTER) and
`TrimSize` enum (four codes) both need extending. The clean change is to make
the trim code the identity and derive dimensions from it (`0600X0900` →
6 × 9), keeping the four names as aliases so existing specs and golden
masters keep parsing byte-for-byte. Layerbooth already accepts either form and
`WxH` inches.

## Embedding

Layerbooth's compositor is one self-contained block of browser JavaScript
(`LAYER_DEF`, `RENDER_CORE`, `LOAD_LAYERS`) with no dependencies beyond WebGL
and Canvas 2D. Two ways to put it in the builder:

1. **Same code, builder host.** Extract the compositor block into a module
   that both the Layerbooth page and the builder's Svelte page import. The
   builder supplies its own asset fetcher (the content-addressed store) and
   its own UI; the compositor draws into a canvas the builder owns. This is
   the right long-term shape and keeps one implementation of every effect.
2. **Iframe.** Run the Layerbooth page as-is inside the builder and exchange
   the layer stack and the rendered PNG with `postMessage`. Fast to try, but
   two UIs and two asset stores.

Server-side rendering for previews and PDFs uses the same block in headless
Chromium, as `layerbooth render` and `layerbooth page` do now. On a Cloudflare
Worker there is no Chromium; page renders for the store either happen in the
person's browser at save time (the canvas is right there) or on a small render
host. Rendering at save time is simpler and is what the builder should do.

## Order of work

1. Extend `TrimSize` and `PaperSize` in page-schemas; add the trim table.
2. Add an asset resolver in the builder that serves `asset:<sha256>` from the
   store; accept `layerbooth page --assets` output as an import.
3. Lift the compositor block into a shared module; render into the builder's
   canvas; save the ground at save time.
4. Move the layer UI in, with the Add menu order above and the page settings
   below the stack.
5. Retire the data-URI path except for single-page export.
