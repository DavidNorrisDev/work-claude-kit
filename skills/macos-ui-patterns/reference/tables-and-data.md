# Tables and data-dense views

## 4. Tables are first-class

On the Mac, `Table` with sortable `TableColumn`s is the natural home for tabular and numeric data — exactly what a dense analytics view needs. The data-driven rules still apply, sharpened for density.

- Sortable columns, multi-row selection, selection driving the inspector/detail.
- Right-align numbers and use monospaced digits so they align by place value (`.monospacedDigit()`).
- Chips/badges for finite categorical columns; de-emphasise inactive rows.
- **Check:** is dense data in a real `Table` (sortable, selectable) rather than a hand-built stack of rows?
