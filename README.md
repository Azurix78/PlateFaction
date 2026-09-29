# PlateFaction

Faction icons and name colors for Blizzard player nameplates in **WoW Forever 1.60.1** (Interface **16001**).

Created by **Syntaxucre** · [Guide français](docs/README.fr.md) · [Releases](https://github.com/Azurix78/PlateFaction/releases) · [Report an issue](https://github.com/Azurix78/PlateFaction/issues)

## Features

- Icon only, name color only, or both.
- Separate Alliance and Horde icon switches. To see only Horde icons, disable **Show Alliance icon**.
- Alliance names in blue (`#3399FF`) and Horde names in red (`#FF4040`). These replace class colors on names; icon filters do not filter name colors.
- Icons to the left, right, above or below the name, with horizontal/vertical offsets from -100 to +100.
- Icon size from 10 to 64 (default 16). Default position is left with a gap of 4 and zero offsets.
- Changes apply immediately; settings are saved account-wide in `PlateFactionDB`.
- No external addon dependencies or changes to health bar colors.

## Install and configure

1. Download **PlateFaction-1.0.0.zip** from the [release page](https://github.com/Azurix78/PlateFaction/releases/tag/v1.0.0). Use the release asset, not the automatically generated source-code ZIP.
2. Extract it into your Forever client's `Interface/AddOns` folder. The resulting path must be `Interface/AddOns/PlateFaction/PlateFaction.toc`.
3. Restart WoW and enable PlateFaction in the addon list.
4. Type `/platefaction`, or open **Options → AddOns → PlateFaction**.

Enable the nameplates you want in WoW's own settings. For an addon update, replace the files and run `/reload`. Normal logout or `/reload` saves preferences. Preferences do not switch factions when you change characters.

## Languages

The interface follows the client locale automatically: English (`enUS`/`enGB`), French, German, European Spanish, Latin American Spanish, Italian, Brazilian Portuguese, Russian, Korean, Simplified Chinese and Traditional Chinese. Missing translations and unknown locales fall back to English.

Translations are in `PlateFaction/Locales.lua`. Corrections are welcome; not all translations have been reviewed by native speakers.

## Compatibility and validation

Targets **Blizzard player nameplates**. NPCs, pets and the personal nameplate are excluded. Hidden names and restricted or unavailable faction data are respected. Nameplate replacements such as Plater are not supported.

Forever is a beta client. Lua syntax and behavior are checked using simulated WoW APIs. **Multilingual rendering, actual SavedVariables persistence and restrictions in combat still require in-game verification.** See the [manual checklist](docs/README.fr.md#vérification-en-jeu).

## Development and releases

Run the Lua 5.1-compatible suite from the project root:

```sh
lua tests/run.lua
```

Build the installable archive with PowerShell 5.1 or newer:

```powershell
./scripts/Package.ps1 -Version 1.0.0
```

The output is `dist/PlateFaction-1.0.0.zip`. Only the manifest, declared Lua files and MIT license are packaged. Generated archives, personal installer scripts and editor files are excluded from Git.

The GitHub workflow validates pushes and pull requests. A `vX.Y.Z` tag matching the manifest version creates a GitHub release with its installable ZIP after successful tests. CurseForge submission is manual; [ready-to-use copy](docs/CURSEFORGE.md) is provided for the **Syntaxucre** account.

## License

[MIT](LICENSE), copyright 2026 Syntaxucre. The addon references faction textures provided by the game; it does not redistribute Blizzard artwork.
