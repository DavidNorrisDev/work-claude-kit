# Data surfaces

## 7. Let the data drive the form

The shape of a data surface should come from the data, not from a default table. This matters most on analytics and finance surfaces, where numeric and categorical data are the point.

- Finite categories (status, department, type) → chips or a segmented control, not free text in a cell.
- Numbers → right-align and use monospaced digits so they align by place value and scan vertically. (`.monospacedDigit()` / `Font.system(..., design: .monospaced)`.)
- Long text → truncate to give the important columns room.
- Inactive/deactivated rows → de-emphasise (reduced opacity), don't give them equal weight.
- Time-series data → a timeline or a chart usually beats a time-sorted table; a chart shows the trend instantly instead of making the user read a timestamp column.
- **Check:** is a table being used by default where a chip set, timeline, or chart would fit the data better?

## 8. Colour and emphasis come from meaning

On a data surface, colour is signal, not decoration. Spend it where it carries information.

- Semantic colour (error/urgent/positive) earns attention precisely because it's rare; if everything is coloured, nothing reads as urgent.
- Use recognisable markers (an avatar, a status dot) where they let the eye associate faster than reading a label.
- **Check:** does each use of colour mean something, or is it there to look lively? Remove decorative colour from data views.
