# GreenKid-MV - (Experimental Work)

A local Mac game builder based on **nxnative**, with the Ocarina of Time work from **kid-with-sword-remake**. Choose your own game dump, build it on your Mac, and keep the result on your machine.

GreenKid-MV packages other developers’ native-execution work with a small Mac launcher. It is not an independently developed replacement for nxnative. The game’s ARM code runs through nxnative’s runtime and Metal graphics layer rather than a conventional full-system emulator.

> [!IMPORTANT]
> The public source and the GreenKid-MV launcher exclude commercial game dumps, console keys, extracted game programs, game assets, translated game shaders and personal saves. The few binary parser fixtures in the source are manufactured test headers, checked against pinned hashes.
>
> You supply your own lawfully obtained dump. A game app produced from that dump contains game material and is **not a shareable GreenKid-MV release**. Keep that output private.

## Status

**Experimental preview.** This distribution is focused on the Switch 2 Ocarina of Time dump. It pins the engine to low requirement 60FPS, low ram spent spec.

The engine includes upstream shader-synchronization corrections, frame buffering and resolution presets. Sustained 60 FPS and lighting correctness have **not been certified for this GreenKid-MV release**. Your hardware, game dump and area affect the result. The local Zelda performance investigation remains separate from the public launcher.

## Features

- A Mac window for choosing your dump folder and following the build log.
- A bundled, pinned engine source snapshot and its existing compiler tools; the launcher contains no playable game.
- Full local shader and pipeline preparation rather than a reduced first-area shader set.
- Normal Ocarina rendering at 1280×720, or the lighter upstream preset at 960×540 with upscaling.
- Private build outputs under `GreenKid-MV-local/` in the chosen game folder.
- Separate writable engine and Python tools under `~/Library/Application Support/GreenKid-MV/`; building does not modify the signed launcher.
- Content checks and Git ignore rules that keep private game outputs out of source packages.

## Installing

1. Get the `GreenKid-MV-<version>-macOS-arm64.zip` launcher from this project’s release files and unzip it.
2. Move **GreenKid-MV.app** to Applications and open it. Preview builds are ad-hoc signed, not notarized; macOS may require you to approve opening the app and accessing the folder you select.
3. Install the prerequisites below, then choose a folder containing your own dump. Keep that folder outside any Git repository.
4. Choose Normal or the lighter performance preset, then select **Build My Local Game**.
5. When the log reports completion, select **Show Private Output** and open `Game.app`.

The first full game build can take an hour or longer. Later builds reuse matching outputs. The launcher downloads Python and Python dependencies on first use through `uv`; it does not download a game or console keys.

### Requirements

- An Apple silicon Mac. The launcher itself targets macOS 15+, but building and playing through the pinned engine requires **macOS 26.6 or later**, **Xcode 27.2**, and its Metal Toolchain.
- At least 16 GB RAM for the Ocarina workflow. Allow substantial free disk space: a full dump, build, caches and resulting game app can together occupy 100 GB or more.
- Homebrew and the tools below. Open Xcode once and complete its initial setup.

```sh
brew install uv xcodegen zstd glslang
brew install --cask dotnet-sdk
xcodebuild -downloadComponent MetalToolchain
```

The engine checks the selected Metal compiler. Fix a toolchain mismatch rather than bypassing that check. Switch 2 NUP inputs do not require `prod.keys`; other engine workflows have their own requirements in the upstream documentation.

## What belongs on GitHub

| Shareable project material | Keep private and outside the repository |
|---|---|
| This source snapshot and its original licence notices | NUP, NSP, NSZ, XCI, XCZ and extracted game modules |
| GreenKid-MV’s game-free builder ZIP | Any locally generated `Game.app` or game IPA |
| Source ZIP, content-check report and SHA-256 checksums | RomFS images, game models, textures, audio and overlays |
| Build instructions and upstream acknowledgements | Translated game shader libraries, pipeline caches, saves and console keys |

Run the publication check before staging changes:

```sh
python3 tools/check_content.py --staged
```

Ignore rules do not remove files already committed to Git. This snapshot starts without upstream Git history; its origin and revision are preserved in `UPSTREAM-REVISION`, [CREDITS.md](CREDITS.md) and [AUTHORS.md](AUTHORS.md). Do not copy an existing game build or its old Git history into it.

## Known limitations

- This is a builder, not a prebuilt copy of Zelda. Each player builds from their own files.
- Performance and visual issues can still come from the underlying engine. There is no guarantee of 60 FPS or glitch-free lighting.
- A fresh machine needs the development tools above; this is not a self-contained replacement for Xcode or the .NET SDK.
- The first local build is lengthy. Do not run a compiler-heavy build while judging gameplay performance.
- The 13 GiB Ocarina memory cap is a conservative local setting, not a guarantee against memory pressure in every area. The private `runtime.env` records the selected settings.
- Upstream gameplay screenshots are omitted from this publication snapshot. Some historical documentation still refers to that omitted gallery.
- The launcher is currently Apple silicon only. The underlying project’s iPhone and other workflows are not GreenKid-MV release claims.

## Building GreenKid-MV

This creates the **game-free launcher**, not a game:

```sh
python3 tools/check_content.py
python3 -m unittest discover -s tests -v
python3 tools/package_builder.py
```

The resulting `dist/` contains the launcher ZIP, a source ZIP, `SHA256SUMS.txt` and `CONTENT-CHECK.json`. `dist/` is ignored by Git; publish the checked ZIPs as release assets rather than committing the app bundle. No game dump is needed to package this launcher.

For a local game build without the launcher:

```sh
bash scripts/greenkid_build.sh --doctor
bash scripts/greenkid_build.sh --build /path/to/your/game-folder performance
```

## Credits

The original developers deserve the credit for the runtime, graphics and game support:

| People / project | Contribution |
|---|---|
| [seedds / nxnative](https://github.com/seedds/nxnative) | Base project, host/runtime, Metal integration, rewriter and continuing fixes. Original MIT copyright retained. |
| [cheemu21 / kid-with-sword-remake](https://github.com/cheemu21/kid-with-sword-remake) | The direct fork used here: Ocarina-specific integration, presets, upscaling work and documented Mac/iPhone experiments. |
| Xipzer | Performance work credited in the imported history and fork documentation. |
| Pedro Nascimento | Imported graphics-scale work and other contributions, as recorded in the upstream history. |
| [All recorded upstream contributors](AUTHORS.md) | The complete author list from the pinned source snapshot, with example commit links. |
| [jhaizhou-ops / d2r-mobile](https://github.com/jhaizhou-ops/d2r-mobile) | The native-execution foundation acknowledged by nxnative. |
| Ryujinx, LibHac, SPIRV-Cross, Atmosphère, MacNativeGames and the other dependency authors | Translation, extraction, system references and supporting libraries. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). |

GreenKid-MV adds the distribution boundary, local-builder launcher and packaging checks. It does not claim authorship of the imported engine fixes. The straightforward README organization was inspired by [NX2navi](https://github.com/tangerineturtle1/NX2navi); none of that project’s code, artwork or restricted additions were imported.

## Licence and project identity

The imported engine retains its [MIT licence](LICENSE). Third-party components retain their own terms and notices. The original upstream overview is retained in [UPSTREAM_README.md](UPSTREAM_README.md).

No software licence grants rights to Nintendo’s game content. Removing game data from a release is a technical distribution boundary, not legal clearance. GreenKid-MV is an independent project and is not affiliated with or endorsed by Nintendo. Game and platform names belong to their respective owners.
