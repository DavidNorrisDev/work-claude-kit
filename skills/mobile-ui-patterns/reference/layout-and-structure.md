# Layout and structure

## 1. Scale — resist the urge to shrink

A smaller screen is not a licence to shrink type and spacing. iOS has a base font size of ~17pt versus ~13pt on macOS, so text and touch targets generally *hold or grow* on the phone, they do not compress.

- Do not reduce font sizes or tighten spacing to fit more on screen. If it doesn't fit, cut content, don't shrink it.
- Maintain a minimum ~44pt touch target for anything tappable.
- **Check:** would this look cramped held at arm's length? If you've shrunk Dynamic Type or spacing to make something fit, you've made the wrong trade.

## 2. One screen, one job

Each screen does one thing. The home screen is the exception; everything else is single-purpose.

- Settings is settings. An editor is an editor. Don't bolt "recent items" or "suggestions" onto a focused screen.
- When you need to add a capability, reach for a *new screen or a sheet*, not a busier layout.
- **Check:** can you name this screen's single job in one phrase? If you need "and", reconsider.

## 3. One scroll axis per section

Desktop dashboards lay content out in two directions at once (a grid of rows and columns). On a phone, pick one axis *per section*: a vertical stack **or** a horizontal carousel, not both.

- This is the key move when porting a desktop/dashboard layout to mobile: take each 2D region and choose its single axis.
- **Check:** is any section trying to scroll both ways, or implying a desktop grid? Collapse it to one axis.

## 4. Building blocks and nesting

There are effectively four building blocks: cards, text/links, images, and inputs. Cards group content where you'd otherwise use whitespace.

- Avoid double-nesting cards (a card inside a card). It stacks padding on padding and cramps the content. Group with whitespace or a divider instead of another container.
- **Check:** is there padding-on-padding from nested containers? Flatten one level.
