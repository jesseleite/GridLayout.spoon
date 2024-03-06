# GridLayout.spoon

Save preset layouts for your most commonly used apps using hs.grid for positioning!

> _NOTE: Experimental! Things may change without notice._

## Rationale

Window managers like Divvy, Spectacle, Moom, etc. are rad, but are often too simplistic.

Automatic tiling managers like Yabai are also rad, but are often too intrusive.

This spoon is an opinionated 'best-of-both-worlds' approach, allowing you to control your own floating windows, but with an easy way to automatically position your most common used apps into nice grid-based preset layouts.

## Credit

This has largely been a back-and-forth collab between my lovely co-worker [Jason Varga](https://github.com/jasonvarga) and I, but Jason deserves much of the credit for this layout system ❤️‍🔥

Also special thank you to my brother-in-arms [Evan Travers](https://github.com/evantravers) for all the insanely helpful [Hammerspoon blog posts](https://evantravers.com/articles/tags/hammerspoon/) and example [Spoons](https://github.com/evantravers?tab=repositories&q=spoon), which have proven immensely useful in this Hammerspoon journey 💘

## Install

1. MacOS
2. [Hammerspoon](https://www.hammerspoon.org/go/)
3. Download a [release](https://github.com/jesseleite/GridLayout.spoon/releases) to `~/.hammerspoon/Spoons/Headspace.spoon`
4. Load the Spoon by adding the following code snippet to `~/.hammerspoon/init.lua`:

```lua
local layout = hs.loadSpoon('GridLayout'):start()
```

## Grid Configuration

```lua
layout
  :setGrid('60x20')
  :setMargins('15x15')
```

> _NOTE: These methods will set the above mentioned `hs.grid` methods for you, but will also inform GridLayout.spoon of your grid configuration as well._

## Apps Configuration

```lua
layout:apps({
  WezTerm = { id = 'com.github.wez.wezterm' },
  Brave = { id = 'com.brave.Browser' },
  Slack = { id = 'com.tinyspeck.slackmacgap' },
  Tower = { id = 'com.fournova.Tower3' },
  Ray = { id = 'be.spatie.ray' },
  Obsidian = { id = 'md.obsidian' },
})

```

> _NOTE: Extracting an [apps.lua](https://github.com/jesseleite/dotfiles/blob/master/hammerspoon/apps.lua) object/module in your hammerspoon config is recommended; It's a nice pattern for assigning app-specific hotkeys, etc. for use throughout your hammerspoon config, but inline is fine too!_

## Layouts Configuration

```lua
layout:setLayouts({
  {
    name = 'Standard Dev', -- Define a 'Standard Dev' layout
    cells = {
      { '0,0 7x20' },   -- Cell 1
      { '7,0 21x20' },  -- Cell 2
      { '28,0 32x20' }, -- Cell 3
      { '42,2 16x16' }, -- Cell 4
    },
    apps = {
      Ray = { cell = 1, open = true },     -- Assign to cell 1, and ensure app opens
      Brave = { cell = 2, open = true },   -- Assign to cell 2, and ensure app opens
      WezTerm = { cell = 3, open = true }, -- Assign to cell 3, and ensure app opens
      Tower = { cell = 3 },                -- Assign to cell 3, app being open is optional
      Slack = { cell = 4 },                -- Assign to cell 4, app being open is optional
    },
  },
  {
    name = 'Code Focused', -- Define a 'Code Focused' layout
    cells = {
      -- etc.
    },
  }
})
```

> _NOTE: You may define as many layouts as you wish! Extracting [layouts.lua](https://github.com/jesseleite/dotfiles/blob/master/hammerspoon/layouts.lua) object/module in your hammerspoon config is recommended, but inline is fine too!_

### Defining Layout Variants

WIP

## Available Action Methods

| Method | Params | Description |
| :--- | :--- | :--- |
| `layout:selectLayout()` | `layout_key?`, `variant_key?` | Open fuzzy layout selector, or pass params for specific layout and/or variant. |
| `layout:selectNextVariant()` | | Select next [layout variant](#defining-layout-variants). |
| `layout:bindToCell()` | | Bind currently focused app to a specific layout cell. |
| `layout:resetLayout()` | | Reset currently selected layout state. |
| `layout:resetAll()` | | Reset all in-memory GridLayout.spoon state. |
