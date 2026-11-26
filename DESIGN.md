# PokéDex Design System

This document records the visual language currently used by the Flutter app. It
is derived from the shipped widgets and theme; it is a reference for keeping
future screens consistent, not a separate redesign specification.

## Product character

PokéDex is a friendly trainer's field guide: Pokémon artwork and useful
encyclopedia data take priority, while small details such as specimen numbers,
regional filters, and type colors make browsing feel like collecting field
notes. The interface should feel warm, clear, tactile, and playful without
making dense data harder to scan.

## Color

The app uses a Material 3 color scheme generated from PokéDex red, with a
light and dark appearance. Use theme roles for general interface elements;
reserve Pokémon-specific colors for artwork, type badges, and local accents.

| Role | Light | Dark | Use |
|---|---|---|---|
| Brand seed | `#E94B55` | `#E94B55` | Primary actions and brand marks; Material derives the rest of the scheme |
| Page background | `#F7F5EF` | `#17191F` | Main screen canvas |
| Primary surface | `#FFFEFA` | `#20232B` | Navigation and input surfaces |
| Input surface | `#FFFEFA` | `#242832` | Fields and search controls |
| Strong text | `#20232B` | `#F8F5EC` | App bar titles and high-emphasis text |

Use the active `ColorScheme` for text and controls rather than hard-coding
light-mode colors. Dashboard artwork can tint its background with the current
Pokémon's type color at low opacity. Browse cards use an ID-derived accent
because the list data does not include type information.

Type and tier colors are defined in
[`lib/utils/pokemon_utils.dart`](lib/utils/pokemon_utils.dart); use those
helpers instead of maintaining another palette.

## Typography

No custom font family is declared. Use Flutter's theme text styles so the
platform's default sans-serif remains consistent:

- Screen titles: `titleMedium` or larger, bold to extra-bold.
- Pokémon names and key values: `titleSmall` to `headlineSmall`, bold and
  high-contrast.
- Supporting labels and IDs: `labelSmall` / `labelLarge`, medium to bold.
- Small all-caps eyebrow labels may use wider letter spacing to establish
  hierarchy, as on the dashboard brand lockup.
- Keep Indonesian interface copy concise and conversational.

## Shape, spacing, and depth

- Use rounded geometry: 16–18 px for controls, around 24 px for browse cards,
  and 30 px for the featured 3D stage.
- Prefer a consistent 4 px spacing rhythm. Common layout gaps are 8, 12, 16,
  and 24 px.
- Favor warm, nearly-white surfaces and subtle borders over heavy outlines.
- Keep elevation restrained. Use soft, tinted shadows only to give the current
  Pokémon or primary action a little focus.
- Clip card artwork to the card's rounded boundary.

## Core patterns

### Dashboard

- Keep the PokéDex mark and title compact in the app bar.
- Place region and daily-Pokémon filters in a horizontally scrollable chip row.
- Give the current Pokémon the largest visual area: an inset, rounded stage with
  restrained type-color tinting, a faint Poké Ball motif, and the 3D artwork.
- Put name, number, and type information close to the artwork; keep the swipe
  hint secondary.
- Preserve swipe, pause, shuffle, and detail affordances when restyling.

### Browse cards

- Use a two-column grid of rounded cards with a faint Pokémon-specific gradient.
- Keep the artwork dominant, place the Pokédex number in a compact badge, and
  place the favorite action in the upper-right corner.
- Preserve clear tap targets and the existing loading and image-error states.

### Pokémon details

- Frame 3D artwork in an inset, rounded stage with a subtle tint from its type.
- Keep the name and type badges visually close to the artwork; show the Pokédex
  number as a compact label.
- Show base stats as thin segmented lines, with the numeric value alongside
  each label for clarity.

### Navigation and controls

- Use the Material 3 bottom navigation bar for the app's primary destinations.
- Use filled buttons for primary actions, tonal icon buttons for secondary
  actions, and chips for filters or short contextual actions.
- Inputs use filled surfaces and rounded corners, with a visible brand-colored
  focus border.
- Support both theme modes through `Theme.of(context).colorScheme`.

## Motion and interaction

- Use short, eased transitions for card entrance and selection changes.
- Keep the 3D specimen motion as the centerpiece; pause it when its tab or
  carousel page is inactive.
- Use subtle parallax or tilt only as progressive enhancement. Do not make
  essential information or actions dependent on motion.
- Maintain clear loading, empty, retry, and favorite states.

## Implementation references

- App-wide Material theme: [`lib/main.dart`](lib/main.dart)
- Dashboard and featured stage: [`lib/pages/dashboard_page.dart`](lib/pages/dashboard_page.dart)
- Main navigation: [`lib/pages/home_page.dart`](lib/pages/home_page.dart)
- Browse card and favorite button: [`lib/widgets/pokemon_card.dart`](lib/widgets/pokemon_card.dart)
- Pokémon detail and segmented stats: [`lib/pages/detail_page.dart`](lib/pages/detail_page.dart)
- Pokémon type and tier colors: [`lib/utils/pokemon_utils.dart`](lib/utils/pokemon_utils.dart)
