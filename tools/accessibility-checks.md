# Browser and assistive-navigation qualification

This is a task-based check, not a claim of WCAG conformance. The canvas has a
scene description; it does not expose every 3D observation as an accessible
object. Use captions, static guide posters and the readable legend table to
interpret a view without manipulating the canvas.

## Reproduce the small fixtures

Install the candidate, then run `Rscript tools/render_view_controls.R`.
Open `artifacts/annotated-animation.html`, `artifacts/readable-legend.html`,
and `artifacts/view-controls.html` in the browser under test. Record OS,
browser, screen-reader version, screen size and reduced-motion setting.

1. Identify the scene by its description. Expand **View controls** with the
   keyboard, focus **Rotate left**, activate it, then **Reset view**. Verify
   another scene does not rotate. The canvas requires WebGL; a caption remains
   readable without it.
2. Focus the **Triangle expansion Frame** slider. Press Right once. Its value
   and accessible value text must change from Initial to Middle. Play, then
   pause: the visible frame label updates, but playback must not flood speech.
   The focused slider exposes its descriptive frame label, not just its number.
3. Focus the long retinal legend. Scroll to the last category and expand
   **Read legend as table**. Read the category, color and count columns, including
   the last row. Check narrow windows without page-wide horizontal overflow.
4. Use **Show view settings**. Read or copy the R recipe from its labeled text
   area; **Download view settings** should save the same recipe. Reconstruct the
   camera and compare orientation, zoom, observer and bounds.
5. Run `Rscript tools/shiny_controls.R`, open `http://127.0.0.1:4873`, and repeat
   the controls. Change Scene revision: only the reactive scene/animation
   should update. During an update, focus in camera controls must return to the
   same control; focus in Unrelated input must stay there. No duplicate legend,
   panel, caption or player should accumulate. The CI fixture triggers a
   reactive update while a button is focused to check this precisely.

For VoiceOver use its normal navigation/interaction commands and capture the
spoken result, not just the browser accessibility tree. For NVDA use Windows
with the browser under test and record actual announcements. Repeat the label
and long-table tasks with each. DOM assertions alone cannot establish speech
comfort or usability.

## Qualification limits (September 15, 2026)

The development checks target Chromium and Firefox through the browser CI job,
plus native Safari 26.6 on macOS 26.6.1. Tests cover camera replay, frame labels,
legend/caption persistence and Shiny rerender behavior; consult the successful
CI run for the exact tested commit and engine versions.

NVDA/Windows is untested: no environment or tester was available. VoiceOver
could be enabled locally, but the automation tool could not expose its caption
window or spoken output. Safari keyboard/AX results are therefore recorded
separately from an actual screen-reader listening pass. Both speech checks
remain open qualifications; no accessibility-conformance claim is made.
