# Signifiers and control states

## Signifiers — let the UI explain itself

Good UI communicates how it works without instructions. A container around two items says they're related; a filled background says selected; greyed-out says inactive; a press state says tappable.

- Make selection, active, disabled, and pressable states visibly distinct.
- If you're tempted to add explanatory text, first check whether a signifier would do the job.
- **Check:** could someone tell what's selected, tappable, and inactive at a glance, with no labels explaining it?

## Icons, buttons, and states

- Size icons to the text line height beside them (e.g. 24pt icon next to 24pt line height); most icons default too large. SF Symbols scale with text weight, so match them.
- Distinguish primary, secondary, and ghost (background-on-hover/press only) buttons; keep button padding consistent.
- Every interactive element needs visible states: default, pressed (and hover on macOS), disabled, plus loading where relevant. Inputs additionally need focus, error, and sometimes warning states.
- The rule: when the user does anything, something responds. (The *feel* of that response comes from motion-system.)
- **Check:** does every control have its full set of states, and does every action produce a visible response?
