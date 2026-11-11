# KhataCode

KhataCode photographs a hand-written symbolic program on an A4 sheet, recognizes its symbols, interprets them, and displays the result as HTML in a JavaScript-disabled webview.

## Run

Install Flutter, then run `flutter pub get`, `flutter analyze`, `flutter test`, and `flutter run -d <device>` on an Android phone. The camera permission must be granted.

## Paper layout

The sheet has a 12-column by 16-row grid of 4 mm cells, a row 17 variables strip for `a`, `b`, and `c`, three L-shaped registration marks, and a legend. Blank variable cells mean zero. The current demo recognizes the photographed image directly; crop/deskew is deliberately conservative until real-sheet calibration.

## Token table

`> < ^ v` move; `R` repeat; `I` conditional; `{ }` blocks; `P` print; `=` assign; digits are literals; `a b c` are variables. OCR aliases are included for common confusions (`V`, `r`, `p`, brackets, `O`, and uppercase variables).

## Language

Moves change the cursor by 20 units and add to an SVG path. `P x` prints a value, `= a x` assigns a value, `R n { ... }` repeats, and `I a { ... }` conditionally executes. Programs stop after 5000 statements.

## HTML mode

Choose **Scan HTML** on the home screen to photograph ordinary handwritten HTML
on plain paper. Write one tag or line per ruled line in large block letters with
a dark pen, good light, and the paper inside the camera frame. Make `<`, `>`,
and `/` large and distinct, and write `=` and quotes clearly. The included
`assets/html_template.png` provides a printable ruled layout.

HTML OCR cleanup changes curly quotes to straight quotes, common look-alike
brackets to angle brackets, removes spaces just inside brackets, lowercases tag
names, normalizes spacing around `=`, and collapses repeated whitespace. It
does not guess missing brackets or alter content words.

Handwriting recognition of `<`, `>`, `/`, `=`, and quotes is the weak point.
The editable **Recognized HTML** box on the result screen is the fallback:
correct the text and press **Run again** without taking another photograph.

## Hero screen, theme, and About

The app opens with a short, skippable hero animation. It respects Android's
reduced-motion setting and shows only once per app run. The Home tab contains
the HTML and symbol scan actions; the About tab contains the description,
developers, version, copyright, and appearance controls.

The default theme is dark. Use the sun/moon button for a quick light/dark
toggle, or choose System, Light, or Dark in About. Theme choice is kept in
memory only and is not persisted. Shared app strings live in
`lib/app_info.dart`.

## Decisions

- The Android-only project uses `setState` and `Navigator` with no state-management or routing package.
- The smallest available ML Kit element is split across cells; a later calibration pass can replace the fixed demo cell scale.
- Errors stay on the Result screen rather than using dialogs or snackbars.
- `messy.png` is simulated; a real handwriting test requires photographing your own sheet.
- HTML mode uses the same single Latin ML Kit recognizer as symbol mode, with a
  center A4 crop and image preprocessing rather than registration marks or a grid.
- HTML lines are kept as text cells so the existing symbol tokenizer remains
  unchanged; the HTML runner accepts unclosed or mismatched tags like a browser.
- The hero animation uses one Flutter `AnimationController`, skips on tap or
  reduced motion, and does not initialize camera or OCR work.
- Theme selection is intentionally in-memory only; restarting the app returns
  to the dark default.

## Samples

`assets/template.png` is the printable symbol layout. `assets/html_template.png`
is the printable HTML layout. `assets/samples/valid.png`,
`unclosed_block.png`, `messy.png`, and `html_valid.png` are sample fixtures.
