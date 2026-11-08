---
name: mantine-headless-tailwind
description: >-
  Use when creating, editing, migrating or reviewing a UI component built on Mantine in headless mode (`HeadlessMantineProvider`, no Mantine CSS) and styled with Tailwind through tailwind-variants (`tv`) — typically a `components/ui/*` wrapper around `@mantine/core`. Also use when typing such a wrapper's variant props (`size`, `radius`, `color`, `VariantProps`, `satisfies`, `Omit<MantineProps, …>`), when styling Mantine states with `data-*`/`peer-*`, or when the wrapper recomputes styles on every render under the React Compiler. Only for projects that use, or are adding, `@mantine/core` + `tailwind-variants`. For Radix/shadcn, MUI or styled Mantine (with its CSS and `MantineProvider`), follow those libraries' own conventions instead.
---

# Mantine headless + Tailwind components

The split this skill enforces:

- **Behaviour** (focus, keyboard, ARIA, portals, positioning) comes from Mantine in headless mode.
- **Look** comes from Tailwind through one `tv` function per component.
- **Prop types** are derived from the styles, so `size` accepts exactly the values that have styles.

Checked against Mantine 9.x and tailwind-variants 4; notes about Mantine 10 are marked.

**Project conventions win.** Before writing anything, read `AGENTS.md`/`CLAUDE.md` and one or two existing components in `components/ui`. Where they differ from this skill (naming, test runner, folder), follow the project.

## 0. Setup (once, a separate commit)

```bash
pnpm add @mantine/core @mantine/hooks tailwind-variants
```

- **Do not** add `@mantine/core/styles.css`, `postcss-preset-mantine`, `ColorSchemeScript` or an app-wide `MantineProvider`. Headless Mantine ships no CSS, so it doesn't conflict with Tailwind or with another UI library living alongside during a migration.
- Each component wraps itself in `HeadlessMantineProvider`. It then works anywhere, including in tests, with no app provider.
- **`tailwind-merge` isn't needed, and conflicts already resolve.**
  - tailwind-variants 4 bundles its own merge. A variant or `className` class overrides a conflicting base class: base `bg-white` + variant `bg-blue-600` → `bg-blue-600`.
  - This differs from v3, where `tailwind-merge` was a peer dependency. So keep shared classes in the base slot. Don't move them into every variant "to avoid conflicts".
  - If in doubt, check: `node -e "import('tailwind-variants').then(({tv})=>console.log(tv({base:'bg-white',variants:{c:{p:'bg-blue-600'}}})({c:'p'})))"`.
- Import from `'tailwind-variants'`, **not** `'tailwind-variants/lite'`. Lite really does skip merging, so a passed `className` can't override a base class.
- If another dependency (HeroUI, for example) pulls in its own `tailwind-variants@3`, that's a separate copy. Import `tv` only from your direct dependency.

## 1. Mantine or a plain element

| The component… | Build it from |
|---|---|
| has behaviour: toggles, focus, keyboard, popup, portal, positioning (Switch, SegmentedControl, Checkbox, Select, Tooltip, Modal) | headless Mantine + `tv` |
| only displays something (Divider, Chip, Card) | native element (`<hr>`, `<span>`, `<section>`) + `tv` |

The folder layout and styling rules below are the same for both.

## 2. Layout

```
components/ui/switch/
├── index.ts                     # export { Switch } from './switch'; export type { SwitchProps } from './switch';
├── switch.tsx                   # the component
├── switch.styles.ts             # tv(): slots, variants, defaultVariants, exported VariantProps type
└── __tests__/switch.test.tsx    # use the project's test naming
```

Use kebab-case files and one folder per component. Re-export it from `components/ui/index.ts` if the project has one.

## 3. Styles file

```ts
import type { MantineSize, SwitchStylesNames } from '@mantine/core';
import type { ClassValue, VariantProps } from 'tailwind-variants';
import { tv } from 'tailwind-variants';

// Classes per component slot: { track: '…', thumb: ['…', '…'] }
// ClassValue, not string: tv accepts arrays, and long class lists read better split.
type Slots = Partial<Record<SwitchStylesNames, ClassValue>>;

export const switchVariants = tv({
  slots: {
    root: '',
    input: 'peer sr-only',
    track: [
      'bg-zinc-200 transition-colors motion-reduce:transition-none',
      'peer-checked:bg-primary-500',
      'peer-focus-visible:ring-2 peer-focus-visible:ring-primary-500/40',
      'peer-disabled:cursor-not-allowed peer-disabled:opacity-50',
    ],
    thumb: 'bg-white shadow-sm transition-transform [input:checked~*_&]:translate-x-4',
  },
  variants: {
    size: {
      sm: { track: 'h-5 w-9', thumb: 'size-4' },
      md: { track: 'h-6 w-11', thumb: 'size-5' },
    } satisfies Partial<Record<MantineSize, Slots>>,
  },
  defaultVariants: { size: 'md' },
});

export type SwitchVariants = VariantProps<typeof switchVariants>;
```

### Slots and states

- **Slot names must match Mantine's Styles API exactly.** Get them from the `<Name>StylesNames` type or the "Styles API" section of the component on mantine.dev. A slot Mantine doesn't have is never applied.
- **Style states through attributes, not JS.** To see which `data-*` attributes Mantine sets, read `node_modules/@mantine/core/esm/components/<Name>/<Name>.mjs` (`mod: { … }` and `"data-…"`).
  - Common ones: `data-checked`, `data-disabled`, `data-active`, `data-error`, `data-expanded`, `data-position`, `data-label-position`, `data-initialized`.
- **Don't trust an attribute until you've seen it rendered.** Switch puts `data-checked` on `root` only in controlled mode or inside `Switch.Group`; with `defaultChecked` it's missing. Style the checked state from the input instead.
- **The native `input` is not hidden in headless.** What to do with it depends on what draws the control:
  - **Another element draws it** (Switch: `track` + `thumb`). Give the input `peer sr-only` and style the siblings with `peer-checked:`, `peer-disabled:` and `peer-focus-visible:`. For an element nested inside a sibling (thumb inside track): `[input:checked~*_&]:…`.
  - **The input itself is the box** (Checkbox, Radio). Style the input with `appearance-none` plus `checked:`, `indeterminate:` and `focus-visible:`. Show the overlaid `icon` with `peer-checked:` or `peer-indeterminate:`.
  - Never `hidden`/`display: none`: that removes the control from keyboard and screen readers.
- **Elements positioned by JS** (the `SegmentedControl` indicator, `Tooltip`) don't exist before hydration.
  - Paint the selected item yourself with `not-in-data-initialized:` (for example `peer-checked:not-in-data-initialized:bg-white`).
  - Enable transitions only with `data-initialized:transition-all`; otherwise the first positioning slides in from the corner.

### Other rules

- **Tokens only.** Use the project's colour and spacing tokens. No hex values, no `style={}`, no arbitrary values where a token exists.
- **No `!important` (`!`).** Without Mantine's CSS there is nothing to override.
- **Only variants that are used.** Grep the call sites. Don't add variants "for later".

## 4. Variant types

End every variant with `satisfies <Record of keys to Slots>`. `satisfies` checks both the variant keys and the slot names (`trak` → "Did you mean 'track'?"), but **does not widen the type**. The prop then accepts exactly the keys that have styles.

Don't use the alternatives:

- **An annotation** (`const sizes: Partial<Record<MantineSize, Slots>> = { … }`) widens the type to every key, so `size='xl'` compiles with no styles.
- **`as`** checks nothing.

`Record` or `Partial<Record>`:

- **All keys present** (all five sizes): `Record<Keys, Slots>`. A missing key is then an error too.
- **A subset** (`sm` and `md` only): `Partial<Record<Keys, Slots>>`.

Which `Keys`:

| Variant | Keys |
|---|---|
| size, radius | `MantineSize` (`xs`…`xl`), or your own union |
| color | the project's palette names: `'primary' \| 'danger' \| …` |
| your own (`density`, `tone`) | your own union: `'compact' \| 'comfortable'` |

**Never use a key type containing `(string & {})` or `number`.** That includes `MantineRadius`, `MantineColor`, `MantineSpacing` and Mantine's own `size` prop (`MantineSize | (string & {})`). They accept any string, so the check does nothing. Mantine's colour names (`teal`, `grape`) aren't the project's palette either.

Declare `type Slots` once per styles file. Don't extract a shared helper while there are only a few such files.

Adding a variant takes three steps:

1. Add it to `variants` with `satisfies`.
2. Destructure it in the component next to `size` and pass it to `xxxVariants({ size, … })`. Otherwise it flows through `{...props}` into Mantine and from there into the DOM.
3. Nothing else: the prop type comes from `VariantProps` and updates itself.

At runtime (`as any`, data from an API), an unknown value or `null` gets **no** variant classes. The default applies only to `undefined`.

## 5. Component file

```tsx
import { HeadlessMantineProvider, Switch as MantineSwitch } from '@mantine/core';
import type { SwitchProps as MantineSwitchProps, SwitchStylesNames } from '@mantine/core';

import { switchVariants } from './switch.styles';
import type { SwitchVariants } from './switch.styles';

// Mantine props minus the ones we restyle, plus our variants (derived from the styles file).
export type SwitchProps = Omit<MantineSwitchProps, keyof SwitchVariants | 'classNames'> &
  SwitchVariants & {
    classNames?: Partial<Record<SwitchStylesNames, string>>;
  };

export function Switch({ size, className, classNames, ...props }: SwitchProps) {
  // All styles are computed here, before return.
  const styles = switchVariants({ size });
  const rootClassName = styles.root({ className });
  const slotClassNames = {
    input: styles.input({ className: classNames?.input }),
    track: styles.track({ className: classNames?.track }),
    thumb: styles.thumb({ className: classNames?.thumb }),
  };

  return (
    <HeadlessMantineProvider>
      <MantineSwitch {...props} className={rootClassName} classNames={slotClassNames} />
    </HeadlessMantineProvider>
  );
}
```

Rules:

- **Compute styles before `return`. JSX receives only ready strings and objects.**
  - No `styles.x()` or `xxxVariants()` inside JSX, not even for a small icon (`<Loader2 className={styles.spinner()} />`).
  - Why: the React Compiler merges a call inside JSX into the JSX block. That block depends on the whole `props`, which is a new object on every render, so the styles are recomputed every time.
  - Fix: `const spinnerClassName = styles.spinner();` before `return`.
  - Never `xxxVariants(props)` either: pass only the variant props.
- **Destructure variant props before `...props`.** Then they don't reach Mantine, where `size`/`color` resolve to CSS variables that don't exist in headless.
- **Use `Omit<MantineProps, keyof Variants | 'classNames'>` + `Variants`.** This replaces Mantine's wide types with yours. Don't hand-write `size?: MantineSize`: it drifts from the styles.
- **The API mirrors Mantine** (`checked`/`onChange`/`disabled`/`label`/`description`). Don't add a translation layer for an old library's prop names; migrate the call sites (section 10).
- **React 19 + React Compiler: no `useMemo`, `useCallback`, `memo` or `forwardRef`.** `ref` is a plain prop. If the compiler isn't enabled in the project, follow its existing memo conventions.
- **No `'use client'`.** Mantine marks its own client components, so the wrapper stays importable from Server Components. Add it only if the wrapper itself calls hooks.
- **Hooks come from `@mantine/hooks`** (`useDisclosure`, `useUncontrolled`, `useClickOutside`, `useId`). Don't write your own.
- **For static components** (section 1) the rules are the same, but use the HTML element: `<hr className={dividerVariants({ className })} {...props} />`.

### Props that do nothing in headless

These compile and silently do nothing, because they resolve to `--mantine-*` CSS variables or Mantine's own CSS:

- style props: `m`, `mt`, `p`, `w`, `h`, `c`, `bg`, …;
- `color`, `radius` (unless it's your variant), `variant`;
- `styles`, `vars`, `unstyled`;
- component-specific visuals such as Switch `withThumbIndicator` and `onLabel`/`offLabel`.

Use `className` and your variants instead. You may add these props to the wrapper's `Omit`, so callers get a type error instead of a silent no-op. Do that only once someone actually trips over them.

## 6. States and accessibility

- **Every control has an accessible name:** the `label` prop, or `aria-label` when there's no visible text. A text `div` next to the control doesn't count.
- **Disabled vs pending.**
  - `disabled` drops focus and reads as "unavailable".
  - For "saving…" use a `loading` prop built from `readOnly` + `aria-busy="true"` + an `aria-hidden` spinner in the thumb. In Mantine 9.x `readOnly` on Switch/Checkbox skips `onChange` (`if (rest.readOnly) return;`) and keeps focus. Mantine 10 also sets `aria-readonly`.
- **Focus and motion:** a visible focus ring (`peer-focus-visible:`) is required, and so is `motion-reduce:` on transitions.
- **Which element is the `<label>`** (from `bodyElement`/`labelElement` in the component source):
  - **Switch:** `body` is a `<label>` wrapping the input, the track and the label/description. The whole row is clickable, and the description becomes part of the accessible name. Screen readers may read it twice (name, then `aria-describedby`), so keep descriptions short.
  - **Checkbox, Radio:** `body` is a `div` and only `label` is a `<label>`. Only the box and the label text are clickable, not the description.

## 7. Verify

1. **Baseline first.** Run typecheck, lint and tests before the change, then again after.
2. **Type probes** (temporary, remove afterwards). Run them separately: adding `custom` to the styles makes `size='custom'` valid.
   - an unknown variant key in the styles (`custom: {}`) must give TS2353;
   - a slot typo (`trak`) must give "Did you mean 'track'?";
   - a usage with `size='custom'` or `radius={8}` must give an error.
3. **React Compiler** (if enabled). From the project root run `node <this skill>/scripts/compiler-check.cjs --print path/to/x.tsx`. It resolves Babel and `babel-plugin-react-compiler` from the project.
   - Every function must print `ok`.
   - The cache block holding the `tv` call must depend only on the variant props, `className` and `classNames.*`, never on `props`.
   - If the project uses only Next's Rust compiler without the Babel plugin, the script says so; skip this step.
   - If Node runs only in a container (DDEV, Docker), copy the script into the project root, run it there, then delete it.
4. **Browser:**
   - Tab and Space work;
   - the accessibility tree shows the name and state;
   - there are no hydration warnings;
   - the demo's before/after columns match.

## 8. Tests

At minimum:

- role and accessible name: `getByRole('switch', { name: 'SMS reminder' })`;
- keyboard and pointer interaction, and that `onChange` is called;
- `disabled`, `readOnly` and `loading` don't change the value;
- `className` and `classNames` are appended to the right slots.

The component wraps its own `HeadlessMantineProvider`, so the test wrapper needs no app providers.

## 9. Demo page

One page per component, with the sections that make sense for it:

- default;
- every size, variant and colour from the styles file;
- states: disabled, read-only, error, loading, checked;
- label and description;
- controlled: `useState` with the current value shown next to it;
- one real case copied from the app.

## 10. Migrating from another library (HeroUI, MUI, …)

- Change the call sites to Mantine's props, for example:
  - `isSelected` → `checked`;
  - `onValueChange(v)` → `onChange(e => e.currentTarget.checked)`;
  - `isDisabled` → `disabled`.
- The old look is the target. On the demo page every section has two columns with **the same props**: Before (old library) and After (new component). Delete the Before column once the old one has no usages.
- Migrate one component at a time, in two commits:
  1. the component, its styles, test and demo;
  2. the call sites.

## Related

[`vercel-react-best-practices`](https://github.com/vercel-labs/agent-skills) covers app-level React/Next performance (data fetching, bundles, re-renders). It complements this skill, which is about building the components themselves.
