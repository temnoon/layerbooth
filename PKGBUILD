# Maintainer: Tem Noon <tem@temnoon.com>
pkgname=layerbooth
pkgver=0.1.0
pkgrel=1
pkgdesc='Photobooth with layers: live V4L2 camera controls, edge detection, gradients, blend modes, presets, and a stdin/stdout render CLI'
arch=('any')
url='https://github.com/temnoon/layerbooth'
license=('MIT')
depends=('python' 'ffmpeg' 'v4l-utils')
optdepends=('chromium: panel window and headless rendering (any Chromium-based browser works)'
            'libnotify: snapshot notifications outside Omarchy')
source=("$pkgname-$pkgver.tar.gz::$url/archive/v$pkgver.tar.gz")
sha256sums=('SKIP')  # set on release: makepkg -g

package() {
  cd "$pkgname-$pkgver"
  install -Dm755 layerbooth "$pkgdir/usr/bin/layerbooth"
  install -Dm644 layerbooth.desktop "$pkgdir/usr/share/applications/layerbooth.desktop"
  install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
  install -Dm644 README.md "$pkgdir/usr/share/doc/$pkgname/README.md"
  install -Dm644 contrib/hyprland.lua "$pkgdir/usr/share/doc/$pkgname/hyprland.lua"
  install -Dm644 -t "$pkgdir/usr/share/doc/$pkgname/examples" examples/*.json
}
