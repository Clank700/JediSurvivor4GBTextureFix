# JediSurvivor_4GB_TextureFix_Builder_P9 v1.0.0

Initial public release.

This is a builder release, not a prebuilt PAK release. It contains no original game files and no generated PAKs.

## What It Does

When run from inside a user's Jedi Survivor install folder, the builder creates:

```text
zz_JS4GB_Performance_P9.pak
zz_JS4GB_Balanced_P9.pak
zz_JS4GB_Quality_P9.pak
```

The PAKs are generated locally from that user's own installed Patch 9 game files.

## Recommended First Test

Use `zz_JS4GB_Balanced_P9.pak`.

Balanced has been tested successfully on a 4 GB VRAM card and fixed the broken texture behavior in that test.

## Why No Prebuilt PAKs?

Prebuilt PAKs would contain edited copies of Jedi Survivor configuration files. To avoid redistributing EA/Respawn game files, this release only ships the builder scripts.

## Install

Extract `TextureFix4GB` into the main Jedi Survivor folder, then run:

```text
Build-And-Install-Balanced.bat
```

## Uninstall

Delete:

```text
SwGame\Content\Paks\zz_JS4GB_*_P9.pak
```

Do not delete the original `pakchunk...` game files.

## Built With Codex

Created start-to-finish with OpenAI Codex / GPT-5 as a coding assistant, including implementation, documentation, packaging, and verification.

