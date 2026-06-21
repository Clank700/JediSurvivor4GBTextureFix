# Security Notes

The public release contains scripts and documentation only. It does not contain prebuilt PAKs, original game files, or executables.

The builder downloads the open-source `repak` tool from the official `trumank/repak` GitHub release and verifies the expected SHA-256 hash before running it.

Expected repak archive SHA-256:

```text
6720d602144d75df477a99d5bedb6ea780997546afc335901d4937cafeaa73fa
```

Expected extracted `repak.exe` SHA-256:

```text
fcd538e5994b9bb833622d425ae346f4e0692f02d4b0025114a559f9b6286022
```

The locally generated release ZIP should not be redistributed because it contains PAKs built from your installed game config files.

If you do not want to use the preset switcher, build the presets and then manually copy exactly one generated `.pak` file into `SwGame\Content\Paks`.
