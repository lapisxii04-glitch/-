# RedM Web Access System (rodin_webaccess)

A RedM resource that lets players open external web content (Google Docs/Sheets, web apps, etc.) at specific in-game locations.
Access is controlled server-side by job/grade, and blips are shown only to eligible players.

## Features

- Location-based interaction (press **R** near a configured spot)
- Job/grade permission checks on the server
- Blips visible only when the player can access the location
- Supports multiple coordinates per location
- Supports multiple links per location (opens a menu)
- NUI iframe viewer with auto-close when you walk away

## Requirements

- RedM
- VORP Core (`getCore` + `VorpCore.getUser(src).getUsedCharacter`)
- `redemrp_menu_base` (for the link selection menu when a location has multiple links)

## Installation

1. Put this folder into your server resources directory (example: `resources/[local]/rodin_webaccess`).
2. Ensure dependencies are started before this resource.
3. Add to your `server.cfg`:

```cfg
ensure redemrp_menu_base
ensure vorp_core
ensure rodin_webaccess
```

## Configuration

Edit `config.lua`.

### Config.Debug

```lua
Config.Debug = false
```

### Config.Locations structure

Each entry supports:

- `name`: string (displayed in the prompt group title and blip name)
- `coords`: list of `vector4(x, y, z, yaw)` (multiple positions supported)
- `model`: object model name or `false` (spawns an interaction prop within 30m)
- `requiredJobs`: table of `{ [jobName] = minGrade }` or `false` (everyone)
- `blip`: `{ enable = boolean, sprite = number }` (only shown if player can access)
- `links`: array of `{ label = string, url = string }`

Example:

```lua
{
  name = "PD Manual",
  blip = { enable = true, sprite = 587827268 },
  model = "p_book08x",
  coords = {
    vector4(-762.52, -1267.62, 43.844, -140.0),
    vector4(-276.74, 807.24, 119.18, -34.0),
  },
  requiredJobs = {  ["admin"] = 0,　["police"] = 0 },
  links = {
    { label = "Calculation Sheet", url = "https://example.com/calculation-sheet" },
    { label = "Policy", url = "https://example.com/pd-policy" },
  }
}
```

## Language / Strings

User-facing strings are centralized in `language.lua`:

- `Lang.PromptOpen`
- `Lang.NoPermission`
- `Lang.MenuSelectSubtext`

You can edit these to match your server language.

## How it works

### Permission flow

1. Player presses **R** near a location.
2. Client triggers `rodin_webaccess:canUse` with the location name.
3. Server checks job/grade and replies with `rodin_webaccess:useResult`.
4. If allowed:
   - If multiple links: opens a menu.
   - If a single link: opens the NUI iframe directly.

### Blip visibility

- On spawn and every 5 seconds the client asks the server for visible blips.
- The server returns only locations the player can access.

## Controls

- **R**: Open the location link/menu (when within ~1.5m)
- **ESC / Backspace**: Close the NUI
- Walk away > ~4m: Auto-close the NUI

## Troubleshooting

- If you always get “no permission”, verify:
  - VORP is running and character data contains `job` and `jobgrade`.
  - `requiredJobs` matches your job names and grades.
- If the menu doesn’t open for multi-link locations:
  - Ensure `redemrp_menu_base` is running and `redemrp_menu_base:getData` works.
- If a prop doesn’t spawn:
  - Check `model` is valid and streamed; enable `Config.Debug = true` to see logs.

## Security notes

- Access control is server-side; client checks are not trusted.
- The NUI uses an iframe to load external pages. Only use trusted URLs.
