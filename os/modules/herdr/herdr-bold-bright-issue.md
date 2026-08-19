# `bold` text renders as font-weight instead of the bright color under Windows Terminal

**Version:** herdr 0.8.0 (vendors `libghostty-vt` 1.3.2-HEAD @ `c5a21edf`)
**Host:** Windows Terminal (default settings)
**Surrounding apps tested:** tmux ✅ works · Ghostty (as host) ✅ works
**herdr:** ❌ broken — only this combination fails

## Summary

Windows Terminal's **bold-is-bright** behavior (SGR bold `1` → bright color) is
enabled by default and works with tmux and with Ghostty as the host terminal.
But inside **herdr**, text requested as bold no longer turns into the bright
color — it stays the normal color and is rendered as bold **font weight** instead.

Ghostty (as host) + herdr and Ghostty + tmux are both fine; Windows Terminal +
tmux is fine. Only **Windows Terminal + herdr** breaks.

## Minimal reproduction

Inside a herdr pane, emit a bold basic color. Both of these are "red":

```sh
# classic 8-color + bold
printf '\e[1;31mBOLD RED (classic)\e[0m\n'

# 256-color index + bold
printf '\e[1;38;5;1mBOLD RED (256)\e[0m\n'
```

Expected: both show **bright/bold red** (bold-as-bright).

Actual in **Windows Terminal + herdr**:

- `\e[1;31m` (classic) → renders **normal red, bold weight** (NOT bright)
- `\e[1;38;5;1m` (256) → renders **normal red, bold weight** (NOT bright)

For comparison:

- Same pane content under **tmux in the same Windows Terminal** →
  `\e[1;31m` renders **bright red** ✅
- **Ghostty + herdr** → both render **bright red** ✅

## Root cause: herdr re-encodes the color to 256-color form, which Windows Terminal refuses to brighten

herdr does not pass pane bytes through. It embeds **libghostty-vt** as the pane
terminal emulator, reads each cell back, and *re-emits* SGR to the host terminal
(full-screen redraw via `src/protocol/render_ansi.rs`).

For a bold red cell the re-emission is:

```
\e[0;1;38;5;1m        (what herdr sends to Windows Terminal)
```

i.e. reset + **bold** + **256-color index 1**. The original classic form
`\e[1;31m` was rewritten into `38;5;1` indexed form.

### Windows side — bold-as-bright only applies to classic 16-color indices

`microsoft/terminal` `src/buffer/out/TextColor.cpp`:

```cpp
bool TextColor::CanBeBrightened() const noexcept
{
    return IsIndex16() || IsDefault();    // NOT IsIndex256()
}
```

and `src/buffer/out/TextAttribute.cpp`:

```cpp
bool TextAttribute::IsBold(const bool intenseIsBold) const noexcept
{
    return IsIntense() && (intenseIsBold || !_foreground.CanBeBrightened());
}
```

When the foreground is a **256-color index (`38;5;N`, `IsIndex256()`) or RGB**,
`CanBeBrightened()` returns false, so an intense/bold attribute is rendered as
bold **font weight** and the color is *not* brightened. The brightening path only
fires for classic 16-color SGR (`30-37`/`90-97`).

So herdr's choice of emitting `38;5;N` for a palette color is exactly the form
Windows Terminal will not brighten. (tmux works because it re-emits basic colors
with classic `30-37` codes.)

## This looks like it belongs upstream in libghostty-vt

The deeper issue is **information loss in the vendored `libghostty-vt` color
model**, not something herdr's ANSI encoder can fully fix by itself.

libghostty-vt's SGR parser *does* distinguish every expression form
(`vendor/libghostty-vt/include/ghostty/vt/sgr.h`):

```c
GHOSTTY_SGR_ATTR_FG_8          = 24,  // 30-37
GHOSTTY_SGR_ATTR_BRIGHT_FG_8   = 28,  // 90-97
GHOSTTY_SGR_ATTR_FG_256        = 30,  // 38;5;N
GHOSTTY_SGR_ATTR_DIRECT_COLOR_FG = 21 // 38;2;R;G;B
```

But the rendered **cell-style** API collapses these into a single `Palette(u8)`
(`src/ghostty/mod.rs`):

```rust
pub enum CellColor {
    Palette(u8),   // ← FG_8 / BRIGHT_FG_8 / FG_256 all end up here, form lost
    Rgb(RgbColor),
}
```

By the time herdr reads `CellStyle.fg_color` for a cell it only has the resolved
palette index; it can no longer tell whether the application originally wrote the
8-color `31`, the bright 8-color `91`, or the 256-color `38;5;1`. Any re-encode
to the host is therefore a guess, and the guess (`38;5;N`) happens to be the one
form Windows Terminal will not brighten.

### What would help

- **Upstream (`libghostty-vt`):** expose the SGR color *form* (`Fg8`/`BrightFg8`/`Fg256`/`Direct`) on the cell style, not just the resolved index. That is the only way a re-rendering host like herdr can faithfully preserve the original expression and let the host terminal apply its own bold-is-bright policy per terminal.
- **herdr-side (workaround, independent):** when a bold cell carries a `Palette(0..=7)` index, herdr could explicitly emit the bright index (`91`) + bold so the result no longer depends on the host's `CanBeBrightened()` policy — making behavior consistent across Windows Terminal / tmux / Ghostty.

## Verify

- herdr 0.8.0, `libghostty-vt` 1.3.2-HEAD `c5a21edf`, vendored + locally patched (see `vendor/libghostty-vt.patches.md`)
- Windows Terminal latest, default `boldAsBright` (color scheme `boldAsBright: true`, the default)
- Reproduced only in **Windows Terminal + herdr**; same pane in tmux or with Ghostty as host is correct
