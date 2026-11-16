# omarchy-branding-text

Brand every Omarchy surface from one wordmark — a line of text or a logo image —
and keep the colours in step with your active theme.

> AI Genrated code, which also requires elivated access (root) to update `initramfs`; use it at your own risk!!

| Surface | Where it shows | What the tool changes |
|---|---|---|
| Session | lock screen saver and About | block-character art in `~/.config/omarchy/branding/` |
| Login | SDDM greeter | wordmark, themed background, lock/field/bullet artwork |
| Splash | Plymouth at boot | wordmark embedded in the unified kernel image |
| Boot menu | Limine | `interface_branding` title and accent colour |

```
   ▄██▄      ▄▄████▄▄   ▄███    ▄███   ████████▄
   ████     ▄██▀▀▀▀██▄  ████▄   ████   ██▀▀▀▀▀▀▀
  ██▀███    ██▀     ▀▀  █████  ▄█▀██   ██
 ▄██  ██   ███          ███▀█  ██ ██   ████████
 ███  ███  ███          ███ █▄ █▀ ██   ██▀▀▀▀▀▀
▄████████▄  ██▄    ▄██  ███ ██▄█  ██   ██
██▀    ███  ▀██▄▄▄▄██▀  ███ ████  ██   ██▄▄▄▄▄▄▄
██▀      ██   ▀▀████▀▀   ▀█▀  ██▀  ██   █████████
```

Colours come from the active Omarchy theme (`accent`, `background`,
`foreground`, `red` in `colors.toml`) by default, and a `theme-set` hook repaints
the login screen and boot menu whenever you switch themes. You can also fix the
palette or use a logo image instead of text.

## Requirements

- Omarchy with the stock SDDM, Plymouth and Limine setup
- `magick` (ImageMagick), `omarchy-transcode-ascii`, `python3`, `gum`, `sudo`
- `limine-mkinitcpio` for the boot splash
- optional: `hyprpicker` to sample colours and `omarchy-file-select` (or just
  `gum file`) to pick a logo image

Install any missing dependency with `omarchy pkg add <package>` or `pacman`.

## Install

Run the installer as your normal user, **not** with `sudo`:

```bash
git clone https://github.com/ronaksuchak/omarchy-branding-text.git
cd omarchy-branding-text
bash install.sh
```

The checkout can live anywhere; the installer copies what it needs. It asks for
your password once and then:

- installs `omarchy-branding-text` to `~/.local/bin`
- installs the root helper to `/usr/local/sbin/omarchy-branding-text-system`
  with a sudoers rule for **that one path only**
- registers the command with the `omarchy` dispatcher
- installs the `theme-set` hook and the Appearance ▸ Branding menu
- runs the first `apply`

Options:

```bash
bash install.sh --quick      # apply without rebuilding the initramfs
bash install.sh --no-apply   # install only, apply later
```

Verify the result and try a preview:

```bash
omarchy branding text status
omarchy branding text preview
```

Re-running `install.sh` is safe: it updates the command and helper, keeps your
configuration and adds configuration keys introduced by newer versions.

## Quick start

```bash
omarchy branding text ACME                  # set the text and apply it
omarchy branding text ui                    # configure everything interactively
omarchy branding text preview               # print the art, write the login PNG
omarchy branding text status                # show config, colours and installed state
```

`set`, `style`, `surface` and `option` apply immediately. Use `apply` whenever
you have edited the configuration file by hand.

## Settings UI

`omarchy branding text ui` (aliases: `menu`, `edit`, `settings`) opens a `gum`
menu in the floating terminal. It is also under **Appearance ▸ Branding ▸
Settings** in the Omarchy menu.

- **Text** — the wordmark; blank is allowed when an image is set.
- **Font** — five presets, any `.ttf`/`.otf` file, or a system font family
  resolved through `fc-match`.
- **Image** — use a PNG/SVG/JPEG/WebP instead of rendered text, optionally
  tinted with the accent colour.
- **Colours** — follow the theme or fix the accent, background, foreground,
  failure red and boot-menu colour. Values can be typed as `#rrggbb` or sampled
  from the screen with `hyprpicker`.
- **Surfaces** — toggle the screensaver/About, login, splash and boot menu.
- **Advanced** — logo size, letter spacing, art bounds, image threshold, boot
  menu title, theme following and the initramfs rebuild.
- **Preview**, **Apply now** and **Reset to stock Omarchy branding**.

Changes are saved as you make them; **Apply now** installs them. The UI rejects
fonts that cannot draw your text, so you cannot end up with a blank wordmark.

## Images instead of text

```bash
omarchy branding text option IMAGE ~/logo.png
omarchy branding text option IMAGE_TINT true     # single-colour logo
omarchy branding text apply
```

The image is fitted into `LOGO_SIZE` for the login screen and splash, and its
alpha (or dark pixels, for images without transparency) becomes the block art.
`ART_THRESHOLD` tunes that transcription. `TEXT` still supplies the boot-menu
title unless `BOOTMENU_TITLE` is set.

Use a transparent PNG or SVG for the cleanest result; an opaque image is used as
a rectangle, and tinting recolours the whole thing.

## Fonts

`STYLE` selects a bundled preset (`narrow`, `heavy`, `wide`, `serif`, `mono`) or
`custom` with an explicit `FONT` path. The UI can also resolve a system family.

The font must contain glyphs for every character in `TEXT`. Icon and symbol
fonts — including Omarchy's own `/usr/share/fonts/omarchy/omarchy.ttf` — carry
only a handful of letters and render a blank wordmark. `apply` refuses to install
one, and the UI rejects it when you pick it.

## Configuration

`~/.config/omarchy-branding-text/config.conf` is a plain shell file of
assignments. Edit it with `omarchy branding text config edit` (or any editor),
then run `omarchy branding text apply`.

| Key | Default | Meaning |
|---|---|---|
| `TEXT` | `OMARCHY` | the wordmark, single line, up to 64 characters |
| `STYLE` | `narrow` | `narrow`, `heavy`, `wide`, `serif`, `mono` or `custom` |
| `FONT` | empty | font file; overrides `STYLE` when set |
| `IMAGE` | empty | PNG/SVG/JPEG/WebP wordmark; replaces rendered `TEXT` |
| `IMAGE_TINT` | `false` | recolour `IMAGE` with the accent |
| `LOGO_SIZE` | `800x188` | wordmark canvas used by SDDM and Plymouth |
| `LETTER_SPACING` | `0` | extra tracking in pixels, may be negative |
| `COLORS` | `theme` | `theme` or `fixed` |
| `ACCENT` / `BACKGROUND` / `FOREGROUND` / `RED` | empty | manual palette used when `COLORS=fixed` |
| `SURFACES` | `session,login,splash,bootmenu` | which surfaces to brand |
| `ART_WIDTH` / `ART_HEIGHT` | `81` / `10` | screensaver art bounds |
| `ABOUT_WIDTH` / `ABOUT_HEIGHT` | `54` / `26` | About art bounds |
| `ART_THRESHOLD` | `50` | brightness cut-off when transcribing an image |
| `BOOTMENU_TITLE` | empty | defaults to upper-cased `TEXT` |
| `BOOTMENU_COLOR` | empty | six hex digits; defaults to the accent |
| `FOLLOW_THEME` | `true` | repaint login/boot menu on theme changes |
| `THEME_UPDATE_SPLASH` | `false` | also rebuild the splash on theme changes |
| `REBUILD_INITRAMFS` | `true` | embed the splash on every apply |

`omarchy branding text get <KEY>` prints one value, and
`omarchy branding text option <KEY> <VALUE>` sets one and applies.

### Per-theme overrides

Drop a file in `~/.config/omarchy-branding-text/themes/<theme-slug>.conf`
(`catppuccin.conf`, `tokyo-night.conf`, …) and it is loaded after the main
config whenever that theme is active:

```bash
# ~/.config/omarchy-branding-text/themes/catppuccin.conf
STYLE="serif"
LETTER_SPACING=4
TEXT="ACME"
```

`omarchy branding text status` names the override in use. Theme changes only
repaint the surfaces your configuration enables.

## Commands

```bash
omarchy branding text <text>              # set the text and apply it
omarchy branding text set [text]          # same, with an explicit command
omarchy branding text ui                  # interactive settings editor
omarchy branding text preview [--open]    # print the art, write the PNG
omarchy branding text apply               # re-render and reinstall
omarchy branding text apply --surfaces=login,bootmenu
omarchy branding text apply --no-rebuild  # keep the current initramfs
omarchy branding text style heavy         # narrow|heavy|wide|serif|mono|custom
omarchy branding text surface splash off  # session|login|splash|bootmenu
omarchy branding text option IMAGE ~/logo.png
omarchy branding text get TEXT
omarchy branding text toggle FOLLOW_THEME
omarchy branding text status
omarchy branding text config show|path|edit
omarchy branding text reset [--no-rebuild]
omarchy branding text help
```

`apply --surfaces=` is a partial apply: it updates only the listed surfaces.
`preview --open` also opens the generated PNG in your image viewer.

## How it works

- `~/.local/bin/omarchy-branding-text` renders the wordmark with ImageMagick
  (or fits a supplied `IMAGE`), turns it into block art with
  `omarchy-transcode-ascii`, recolours the stock SDDM widgets, and stages
  everything under `~/.local/state/omarchy-branding-text/stage/`.
- `/usr/local/sbin/omarchy-branding-text-system` copies the stock `omarchy`
  SDDM and Plymouth themes to `omarchy-branding`, installs the staged wordmark
  and a root-owned `Main.qml`, writes `/etc/sddm.conf.d/99-omarchy-branding.conf`,
  and edits `/boot/limine.conf`. It validates every path, PNG and hex colour,
  and refuses to delete theme directories it did not create.
- The staging directory holds only images; the QML and the colour values come
  from the root-owned helper, so a compromised staging directory cannot inject
  code into the greeter or the boot configuration.
- The splash lives inside the unified kernel image, so changing it needs
  `limine-mkinitcpio` (about a minute). That is why theme following repaints the
  login screen and boot menu only. Set `THEME_UPDATE_SPLASH=true` to include the
  splash.
- Backups: `/boot/limine.conf.bak.omarchy-branding`,
  `/etc/plymouth/plymouthd.conf.bak.omarchy-branding`,
  `~/.config/omarchy/branding/*.bak.omarchy-branding`.

## Troubleshooting

**Preview shows solid blocks, or apply prints
`magick: geometry does not contain image`.** The configured font has no glyphs
for your text. `omarchy branding text status` reports a `font issue` line; pick
a text font under **Font** in the settings UI or use a preset `STYLE`.

**The login branding never appears at boot.** Autologin skips the SDDM greeter.
Log out to see it, or disable autologin.

**The splash still shows the old logo.** The splash lives in the initramfs.
Apply with a rebuild (`omarchy branding text apply --rebuild`) or set
`REBUILD_INITRAMFS=true`.

**The boot menu did not change.** This surface needs Limine at
`/boot/limine.conf`. Check `omarchy branding text status`; if the helper is
missing or outdated, re-run `bash install.sh`.

**Theme changes do not recolour the login screen.** Theme following needs
`COLORS="theme"` and `FOLLOW_THEME="true"`. The splash only follows when
`THEME_UPDATE_SPLASH="true"`.

**`the system helper failed` or a sudo password prompt appears mid-apply.**
The passwordless rule exists only for
`/usr/local/sbin/omarchy-branding-text-system`. Re-run `bash install.sh` to
restore (or update) both the helper and its sudoers rule.

**The boot menu drops accents or non-ASCII characters.** Limine accepts
printable ASCII only, so the boot-menu title is stripped; the login and splash
wordmark keep the original text.

## Uninstall

```bash
bash uninstall.sh                 # restore stock branding, keep the config
bash uninstall.sh --purge         # also delete the configuration
bash uninstall.sh --keep-branding # remove the tool, leave the branding installed
```

Backups are left in place so you can inspect or restore them.

## License

MIT — see [LICENSE](LICENSE).

## Contributing

Issues and pull requests are welcome. Please keep the privileged helper small:
it is the only code that runs as root, and it must keep validating every path,
file type and colour it receives.
