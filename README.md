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
- **Layers** — a stack drawn bottom to top. Sources: the camera, an edge
  detector (threshold, thickness, smoothing, colour, background, invert), a
  solid colour, or a two-colour gradient with independent alpha per end. Each
  layer has a blend mode, opacity, and an optional alpha mask that fades it
  along a linear or radial gradient.
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

A layers file is a JSON array; `examples/` has a few. A preset file from
`~/.config/layerbooth/presets.json` also works as `--layers`, its `layers` key
is used.

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
