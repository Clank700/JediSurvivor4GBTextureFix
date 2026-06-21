# Star Wars Jedi: Survivor 4 GB VRAM Texture Fix

A legally safer builder for texture-streaming presets for **Star Wars Jedi: Survivor PC Patch 9** on very low VRAM GPUs, especially 4 GB cards.

This is meant for players whose textures or meshes look extremely low quality after Patch 9. Four gigabytes of VRAM is below the game's official PC minimum, so the goal is damage control:

- stop the constant "PS2 texture" collapse
- keep terrain, clothing, faces, and props readable
- reduce VRAM paging stalls
- make 1080p with FSR feel playable on a 4 GB card

In my own testing on a 4 GB VRAM card, the **Balanced** preset fixed the broken texture behavior and was the best starting point.

## Why Is This A Builder Instead Of Just 3 PAK Files?

Because I do not want to redistribute EA/Respawn game files.

The working presets are PAK files that contain edited copies of Jedi Survivor configuration files. Even though those files are "just config," they still come from the game. Uploading prebuilt PAKs would be easier for users, but it could also mean redistributing copyrighted game content.

So this release does it the safer way:

1. You download this builder.
2. You put it in your own Jedi Survivor install folder.
3. It extracts the required config files from your own legally installed copy of the game.
4. It applies the 4 GB VRAM preset changes.
5. It builds the three PAK files locally on your PC.

That means the public GitHub release contains no original game files. The final PAKs are created on your machine from your own game install.

## Download

Go to the **Releases** page and download:

```text
JediSurvivor_4GB_TextureFix_Builder_P9.zip
```

Extract it into the main Jedi Survivor folder so it looks like this:

```text
STAR WARS Jedi Survivor\TextureFix4GB\build.ps1
STAR WARS Jedi Survivor\TextureFix4GB\Build-And-Install-Balanced.bat
STAR WARS Jedi Survivor\SwGame\Content\Paks\pakchunk0-WindowsNoEditor.pak
```

If `TextureFix4GB` is not next to `SwGame`, it is in the wrong place.

## Recommended Install: Build, Then Manually Copy

Manual copying is the recommended install method because it is transparent: you can see exactly which `.pak` file goes into the game folder, and uninstalling is just deleting that one file.

1. Close the game.
2. Extract `TextureFix4GB` into the main Jedi Survivor folder.
3. Open the `TextureFix4GB` folder.
4. Double-click:

```text
Build-Presets.bat
```

5. After the build finishes, open:

```text
TextureFix4GB\dist
```

6. Copy this file:

```text
zz_JS4GB_Balanced_P9.pak
```

7. Paste it into the game's PAK folder:

```text
SwGame\Content\Paks
```

No original `pakchunk...` files are modified.

## Optional One-Click Balanced Installer

There is also a convenience file:

```text
Build-And-Install-Balanced.bat
```

That builds the presets and installs Balanced automatically. Manual copying is still recommended because it is easier to understand and verify.

## What Gets Created?

After building, the three generated presets will be in:

```text
TextureFix4GB\dist
```

Files:

```text
zz_JS4GB_Performance_P9.pak
zz_JS4GB_Balanced_P9.pak
zz_JS4GB_Quality_P9.pak
```

Only one preset should be installed at once.

## Which Preset Should I Use?

Start with:

```text
zz_JS4GB_Balanced_P9.pak
```

| Preset | Use this if... |
|---|---|
| Performance | Balanced is still too slow or textures take too long to recover. |
| Balanced | Recommended first test for 4 GB VRAM. |
| Quality | Balanced runs comfortably and you want to risk more texture detail. |

## Manual Install After Building

This is the recommended way to install or test presets:

1. Close the game.
2. Open:

```text
SwGame\Content\Paks
```

3. Remove older texture fix PAKs if you installed any:

```text
z_targetheadroom*.pak
z_improved_meshes.pak
z_increasedpool*.pak
```

4. Copy exactly one generated preset PAK from `TextureFix4GB\dist` into `SwGame\Content\Paks`.

Recommended first file:

```text
zz_JS4GB_Balanced_P9.pak
```

## Uninstall

Close the game, then delete:

```text
zz_JS4GB_*_P9.pak
```

Do not delete the original game files named `pakchunk...`.

## Testing Another Preset

1. Close the game.
2. Delete the currently installed `zz_JS4GB_*_P9.pak` from `SwGame\Content\Paks`.
3. Copy in a different preset from `TextureFix4GB\dist`.
4. Start the game again.

Again: only one preset should be installed at once.

## Optional PowerShell Switcher

Manual copying is recommended for first-time users. The switcher is only a convenience script for people who are comfortable with PowerShell.

After building, you can switch presets with:

```powershell
powershell -ExecutionPolicy Bypass -File .\TextureFix4GB\Switch-Preset.ps1 -Preset Balanced
powershell -ExecutionPolicy Bypass -File .\TextureFix4GB\Switch-Preset.ps1 -Preset Performance
powershell -ExecutionPolicy Bypass -File .\TextureFix4GB\Switch-Preset.ps1 -Preset Quality
powershell -ExecutionPolicy Bypass -File .\TextureFix4GB\Switch-Preset.ps1 -Preset Off
```

If PowerShell is opened somewhere else, either move to the main game folder first or pass the game path explicitly:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Path\To\TextureFix4GB\Switch-Preset.ps1" -Preset Balanced -GameRoot "C:\Path\To\STAR WARS Jedi Survivor"
```

If the script detects older conflicting texture-fix PAKs, either remove them manually or run:

```powershell
powershell -ExecutionPolicy Bypass -File .\TextureFix4GB\Switch-Preset.ps1 -Preset Balanced -DisableConflictingFixes
```

## Recommended Game Settings

For a 4 GB card, start with:

- Resolution: 1920x1080
- Ray tracing: Off
- FSR: Quality first, Balanced if heavy areas are still below 30 FPS
- Graphics preset: Medium or Low, then adjust shadows/effects downward first

Do not expect 60 FPS everywhere. A good result on 4 GB VRAM is "not broken anymore," not "looks like an 8 GB card."

## What This Changes

These presets do not include replacement textures. They only override texture streaming configuration.

The presets adjust:

- VRAM headroom reserved for non-texture resources
- minimum texture streaming pool
- dedicated mesh streaming pool
- per-texture mip bias
- texture upload rate
- effective screen size used for texture streaming decisions
- maximum texture size for selected texture groups

Balanced keeps important color textures up to 2K where possible, while capping many normals and secondary maps at 1K to reduce VRAM pressure.

## Source And Privacy

The public repo intentionally does **not** include:

- extracted stock game configuration files
- prebuilt PAKs containing game-derived config files
- the `repak` executable
- local build folders
- private paths from my machine

The builder downloads the open-source `repak` packaging tool from its official GitHub release, verifies its SHA-256 hash, extracts the config files from your installed game, builds the three local PAKs, and verifies the output.

## Built With Codex

This fix, builder, documentation, packaging, and verification workflow were created start-to-finish with OpenAI Codex / GPT-5 as a coding assistant. The actual working result was tested on a 4 GB VRAM card before public release.

## Credits

Built after community investigation into the Patch 9 texture streaming issue. The original public workaround showed that changing texture streaming headroom could fix broken textures, but its settings were too blunt for some 4 GB cards.

This project uses a more conservative 4 GB-focused set of presets.





