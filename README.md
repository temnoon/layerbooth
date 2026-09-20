# Layerbooth

A photobooth with layers. Layerbooth opens a live preview of any V4L2 camera
next to every control the driver exposes, then lets you stack effects on top:
GPU edge detection, solid colours and gradients, blend modes, and per-layer
alpha masks. Name the result as a preset, snapshot it, and re-apply it at
login. A `render` subcommand applies any preset to an image from stdin, so the
same look works in scripts and pipelines.

Built for [Omarchy](https://omarchy.org), where it picks up the current theme,
the webcam list, and the notification style. It runs on any Linux desktop that
has Python 3, ffmpeg, v4l-utils and a Chromium-based browser.

## Install

Arch and Omarchy, from the AUR once published:

```
yay -S layerbooth
```

By hand:

```
install -Dm755 layerbooth ~/.local/bin/layerbooth
```

## Use

```
layerbooth                      # open the panel
layerbooth --devices            # list capture devices
layerbooth --device /dev/video2 # use a specific camera
layerbooth --list               # presets (★ = applied at login)
layerbooth --apply              # apply the login preset (put this in autostart)
layerbooth --apply "Borg"       # apply a named preset
```

### The panel

- **Camera** — every V4L2 control the driver offers, live. Double-click a
  slider to return it to its default.
- **Layers** — a stack drawn bottom to top. Each layer has a blend mode,
  opacity, and an alpha mask. Masks: linear or radial gradients; an image or
  SVG read by its own transparency or by brightness (luminance matte); edge
  detection of the layer itself (keep the lines, or everything but them); and
  a chroma key with similarity, smoothness, spill reduction, and a key colour
  picked straight from the preview. Chroma-key the camera and any layer
  underneath becomes the background. Sources:
  - **Camera** — the live feed.
  - **Image / SVG** — a JPEG, PNG, WebP, GIF or SVG from a file on disk, an
    upload (copied into `~/.config/layerbooth/assets/`), or a URL. Fit
    (contain, cover, stretch, tile), scale, position, rotation. For SVGs the
    stroke colour and stroke width can be overridden so a line drawing can be
    recoloured to match a look. The **Prime…** button fetches one of the six
    prime-number patterns from [fractal-core](https://fractal-core.com)
    (tree, spiral, mandala, walk, burst, wave) for any prime.
  - **Warp** — uses the geometry of an image or SVG (the *field*, rasterised
    and blurred into a height map) to push the pixels of either the camera or
    everything composited below it:
    | effect | what the geometry does |
    |---|---|
    | displace | pixels slide along the strokes' gradient, the photo bulges around the drawing |
    | refract | the drawing becomes glass over the photo, with highlights on the slopes |
    | emboss | the strokes become lit relief; light angle and height are adjustable |
    | contour | topographic isolines of the height field, in a chosen colour |
    | chroma | red and blue split apart along the geometry |
    | flow | the photo smears along the tangents of the strokes, like brushed metal |
    | kaleidoscope | folds the source into n sectors around a centre (no field needed) |
    | 3D tilt | rotates the plane in perspective (no field needed) |
  - **Edges** — a GPU Sobel detector (threshold, thickness, smoothing, colour,
    background, invert).
  - **Colour** and **Gradient** — a solid fill, or two colours with independent
    alpha per end, linear at any angle or radial.
- **Presets** — a name holds the camera settings and the layer stack together.
  Click to load; the name fills the field so **Update** overwrites it; type a
  new name to save a copy. Star one to have it applied at login.
- **Snapshots** — a folder and a filename template with `[preset]`, `[date]`,
  `[time]`, `[datetime]` and `[n]`. A `/` in the template makes sub-folders.
  Nothing is ever overwritten. Snapshots capture the composited image.

### Rendering from the command line

```
layerbooth render --preset "Borg" < in.jpg > out.png
layerbooth render --layers examples/neon-edges.json --format jpg --out out.jpg photo.jpg
ffmpeg -i clip.mp4 -frames:v 1 -f image2pipe -c:v mjpeg - | layerbooth render --preset Borg | magick - -resize 50% small.png
```

Input is JPEG, PNG, WebP or GIF from a path or stdin. Output is PNG by default,
or `--format jpg|webp` with `--quality 0–1`, to `--out` or stdout, at the
input's own resolution. Rendering runs the panel's own compositor in a headless
Chromium, so the output is identical to what the panel shows.

A layers file is a JSON array; `examples/` has a few, including
`prime-relief.json` which needs a fractal-core SVG on disk (fetch one with the
panel's Prime… button, or `curl` it from
`https://api.fractal-core.com/api/v1/svg?n=97&mode=mandala&background=none`).
Image and warp layers reference assets by absolute path. A preset file from
`~/.config/layerbooth/presets.json` also works as `--layers`, its `layers` key
is used.

### Live into OBS (and every other video app)

The `live` subcommand composites a layer stack over a live foreground and
writes the result to a v4l2loopback device — a virtual camera that OBS, Zoom
and every browser see as an ordinary webcam.

One-time setup (Arch: `sudo pacman -S v4l2loopback-dkms`):

```
sudo modprobe v4l2loopback devices=1 video_nr=10 card_label="Layerbooth" exclusive_caps=1
# persist across reboots:
echo v4l2loopback | sudo tee /etc/modules-load.d/layerbooth.conf
echo 'options v4l2loopback devices=1 video_nr=10 card_label="Layerbooth" exclusive_caps=1' | sudo tee /etc/modprobe.d/layerbooth.conf
```

```
layerbooth live --preset Borg      # your camera, composited with the preset
layerbooth live                    # plain camera pass-through
layerbooth live --source test      # built-in test pattern instead of the camera
layerbooth live --source /dev/video2                          # another capture device
layerbooth live --input pose.png --layers examples/neon-edges.json  # a still image
layerbooth live --layers examples/greenscreen.json              # keyed camera over a gradient
```

Or click **Go live** in the panel's toolbar: it pipes the panel's own composited
preview to the loopback device — no second process, the camera stays with the
panel, and you can keep editing layers while OBS watches. The panel window must
stay visible; background windows stop painting, which would freeze the feed.

In OBS: **Sources ➜ + ➜ Video Capture Device (V4L2) ➜ Layerbooth**, then scene
switching, streaming and recording are OBS's job. The feed is video only — add
your microphone as an audio source in OBS. `live` runs until Ctrl-C.

The compositor is a headless browser, so effects cost real CPU. On a modest
machine, `--size 960x540` (or `640x360`) and `--fps 15` trade resolution and
rate for smoothness — OBS rescales either way. `--headed` runs the compositor
as a visible window (GPU-composited, and you can watch the feed being made);
`LAYERBOOTH_GPU=1` tries the real GPU even headless. `LAYERBOOTH_DEBUG=1`
prints per-stage timings. The camera can only be opened by one program at a
time: close the panel (or pass `--source test`) if `live` reports the camera
as busy — or just use the panel's **Go live** button, which shares the panel's
camera instead.

### Notebook pages for gravity-press

A look can become a writing surface. `layerbooth page` renders the layer
stack at paper size and wraps it as a gravity-press **PageSpec v1**: the
rendered look is the page's Ground (an `image`, or a faint `wash`), and an
optional ruling is added as Structure on top.

```
layerbooth page --preset "Prime 97 parchment" --paper A5 --structure dots --out page.json
layerbooth page --layers examples/prime-relief.json --paper LETTER --ground wash --wash-opacity 0.15 --structure lines --out page.json
layerbooth page --preset "Prime 97 parchment" --paper A5 --document 64 --title "Prime 97 notebook" --out notebook.json
```

- `--paper` is `LETTER`, `A4`, `A5` or `HALF_LETTER`; `--dpi` (default 150) sets the ground's pixel size.
- `--ground image` (default) uses the look at full strength; `--ground wash` keeps it faint under handwriting.
- `--structure` adds `lines`, `dots`, `grid` or `polar` with the renderer's defaults, or `none`.
- `--input` supplies a photo for camera layers; without it they are blank, which is what a pattern-only page wants.
- `--document COUNT` writes a **DocumentSpec** instead: one template page repeated COUNT times, with the Lulu trim that matches the paper (A4 has no trim).

The output includes a `layerbooth` key with the original layer stack so the page can be reopened here; gravity-press's parser drops it.

## Hyprland

The panel is a Chromium app window whose app id is derived from its URL, so a
window rule can float it. `contrib/hyprland.lua` has the two lines for
Omarchy's Lua config: a floating rule and the login autostart.

## Configuration

Everything lives in `~/.config/layerbooth/presets.json`: presets, the login
preset, and snapshot settings. Theme colours are read from the current Omarchy
theme when available and fall back to a built-in dark palette.

## Requirements

`python` (3.10+), `ffmpeg`, `v4l-utils`, and a Chromium-based browser
(`chromium`, `google-chrome`, `brave`, or `helium`) for the panel window and
headless rendering. `libnotify` for snapshot notifications outside Omarchy.

## License

MIT. See `LICENSE`.
