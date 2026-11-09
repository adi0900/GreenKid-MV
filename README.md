# GreenKid-MV - (Experimental Work)

A local Mac game builder based on **nxnative**, with the Ocarina of Time work from **kid-with-sword-remake**. Choose your own game dump, build it on your Mac, and keep the result on your machine.

GreenKid-MV packages other developers’ native-execution work with a small Mac launcher. It is not an independently developed replacement for nxnative. The game’s ARM code runs through nxnative’s runtime and Metal graphics layer rather than a conventional full-system emulator.

> [!IMPORTANT]
> The public source and the GreenKid-MV launcher exclude commercial game dumps, console keys, extracted game programs, game assets, translated game shaders and personal saves. The few binary parser fixtures in the source are manufactured test headers, checked against pinned hashes.
>
> You supply your own lawfully obtained dump. A game app produced from that dump contains game material and is **not a shareable GreenKid-MV release**. Keep that output private.

## Status

**Experimental preview.** This distribution is focused on the Switch 2 Ocarina of Time dump with update `v131072`. Since 0.2.0 the engine is upstream nxnative's latest code (`seedds/nxnative` main `2a6f9b32`) plus GreenKid-MV's additions, pinned as `greenkid-v2-73463569c5e7`; it does not silently track upstream updates.

It includes upstream's Ocarina of Time lighting, terrain and stability fixes, MetalFX for the game's own upscaler, the Normal / Potato resolution presets and settings tuned to hold 60 FPS without overheating a fanless Mac (see [What's new in 0.2.0](#whats-new-in-020)). In the maintainer's own play-testing on a fanless MacBook Air, 0.2.0 runs smoothly with the lighting flicker gone. It is still a preview: results on other Macs, dumps and areas have not been certified. The local Zelda performance investigation remains separate from the public launcher.

## Download

**Latest: [GreenKid-MV 0.2.0-preview](https://github.com/adi0900/GreenKid-MV/releases/tag/v0.2.0-preview)** (Apple silicon). Get `GreenKid-MV-0.2.0-preview-macOS-arm64.zip` from that page, then follow [Setup and running](#setup-and-running). The download is the builder only: no game files are included.

## What's new in 0.2.0

- **Engine moved to upstream's latest nxnative** (all upstream commits up to `2a6f9b32`), keeping GreenKid-MV's resolution presets and game-file overlays.
- **Lighting:** fog, mist, shadow and light-shaft fixes from upstream; no more lighting flicker in Kokiri Forest.
- **Terrain:** streamed terrain tiles no longer vanish or go flat after walking (upstream PRs #1920, #1876).
- **MetalFX** now actually draws the game's own chained upscaler (upstream PR #1951).
- **Visual fixes:** light-blue dashes at Death Mountain (#1917), a hard edge in the ground mist (#1824).
- **Stability:** crash after saving, ocarina crash, a GPU-hang watchdog (#1777), an opt-in M1/M2 hang workaround (`DM_NVN_ISOLATE_TASK=1`, #1842), and uploads kept on the submit thread (no present-thread abort).
- **Performance and heat:** two CPU savings per draw, fixed resolution instead of the launcher's dynamic resolution, one frame per display refresh, a 60 FPS cap and simple window scaling. The Performance preset (960×540 upscaled) leaves GPU headroom so a fanless Mac stays at 60 instead of heating up and throttling.

## Features

- A Mac window for choosing your game folder and following the build log.
- A bundled, pinned engine source snapshot and its existing compiler tools; the launcher contains no playable game.
- Full local shader and pipeline preparation rather than a reduced first-area shader set.
- Normal Ocarina rendering at 1280×720, or the lighter upstream preset at 960×540 with upscaling.
- Private build outputs under `GreenKid-MV-local/` in the chosen game folder.
- Separate writable engine and Python tools under `~/Library/Application Support/GreenKid-MV/`; building does not modify the signed launcher.
- Content checks and Git ignore rules that keep private game outputs out of source packages.

## Setup and running

Follow these steps in order. Steps 1–3 are one-time setup. You need your own game file before step 4: GreenKid-MV does not include, download or point to one.

### 1. Check your Mac

- An Apple silicon Mac (M1 or newer) with **at least 16 GB of memory**.
- **macOS 26.6 or later.** (The builder window opens on macOS 15+, but building and playing need 26.6.)
- **About 100 GB of free disk space** for your game file, the build, its caches and the finished game app.

### 2. Install the tools (once)

1. Install **Xcode 27.2** from the App Store or Apple's developer site. Open it once and let it finish its first-time setup.
2. Install [Homebrew](https://brew.sh) if you don't have it.
3. Open **Terminal** and run:

```sh
brew install uv xcodegen zstd glslang
brew install --cask dotnet-sdk
xcodebuild -downloadComponent MetalToolchain
```

To confirm everything is in place, run the builder's check (adjust the path if the app isn't in Applications):

```sh
bash /Applications/GreenKid-MV.app/Contents/Resources/engine/scripts/greenkid_build.sh --doctor
```

It should end with `Prerequisite executables found.` Otherwise it names what is missing.

### 3. Get GreenKid-MV

1. From this project's [Releases](https://github.com/adi0900/GreenKid-MV/releases), download the newest `GreenKid-MV-<version>-macOS-arm64.zip` (currently [0.2.0-preview](https://github.com/adi0900/GreenKid-MV/releases/tag/v0.2.0-preview)) (and `SHA256SUMS.txt` if you want to check the download with `shasum -a 256 -c SHA256SUMS.txt`).
2. Unzip it and move **GreenKid-MV.app** to **Applications**.
3. The first time, **right-click the app → Open → Open**. Preview builds are not notarized, so a normal double-click is blocked once. If macOS still refuses, open **System Settings → Privacy & Security** and choose **Open Anyway**.

### 4. Prepare your game folder

1. Create a new, empty folder, for example `~/Games/Ocarina`.
2. Put **your own copy** of Ocarina of Time (Switch 2) in it, either as:
   - the game's single `.nup` file, **or**
   - the game's NSP file(s): the base game plus **update v131072**.

   This preview is built and tested only for update `v131072`.
3. Keep the folder **outside any Git repository** and outside the GreenKid-MV source. The builder refuses those locations so that game files can't be published by accident. Avoid iCloud-synced folders: the build writes tens of gigabytes.

### 5. Build your game

1. Open **GreenKid-MV** and click **Choose Game Folder…**. Select the folder from step 4 (the folder itself, not the file inside it).
2. Pick the picture quality:
   - **Ticked (default): "Prefer the lighter Zelda performance preset"** draws at 960×540 and upscales. It is easier on the Mac and the best choice for base models.
   - **Unticked: Normal** draws at 1280×720 and looks sharper, but needs more GPU.

   You can rebuild later with the other choice.
3. Click **Build My Local Game**. The log shows each stage.
   - The **first build takes an hour or more**: it translates and prepares every shader of the game on your Mac. Keep the Mac plugged in and awake. The window won't let you quit halfway.
   - The first run also installs a private Python into `~/Library/Application Support/GreenKid-MV/`. It downloads Python packages only, never game files or keys.
4. When the status line says **"Local build ready"**, the log ends with `READY:` and the path of your game app.

Building again later reuses everything that is still valid, so it is much faster.

### 6. Play

1. Click **Show Private Output**. It opens `GreenKid-MV-local` inside your game folder.
2. Open **Game.app**. The first time, **right-click → Open**, as in step 3. If macOS asks whether the app may access a folder (for example Downloads or Documents), click **Allow**: the game needs it for its files and saves.
3. A settings window appears before the game starts. Then play with the **keyboard or a controller**. Xbox, PlayStation and most Bluetooth pads work.
4. **Quit** with **⌘Q**, or hold the controller's **Home** button for 2 seconds and press **A**. Progress the game hasn't saved is lost, so save in-game first.

Tips for smooth play:

- Play **in a window** and keep the game window **visible**. Don't cover it or drag it between screens while playing.
- Short stutters the **first time** you see a new area are normal: the game prepares those graphics once and remembers them.
- Close heavy apps and keep the Mac on power. Don't build and play at the same time.
- On an external display, a 120 Hz or 60 Hz refresh rate paces more evenly than 144 Hz in a window.

### Where things are

| What | Where |
|---|---|
| Your game app (private, contains your game) | `<game folder>/GreenKid-MV-local/Game.app` |
| Build log | `<game folder>/GreenKid-MV-local/build.log` |
| Settings chosen for your build | `<game folder>/GreenKid-MV-local/runtime.env` |
| Game settings file (overrides) | `~/Library/Application Support/nxnative/0400486024DEC000/env.txt` |
| Game log (attach to bug reports) | `~/Library/Logs/nxnative/0400486024DEC000.log` |
| Builder's engine copy and Python | `~/Library/Application Support/GreenKid-MV/` |

**Never upload `Game.app`, the `GreenKid-MV-local` folder, your game file or your saves.** They contain game material.

### Troubleshooting

| Message or problem | What to do |
|---|---|
| `Missing prerequisite: …`, `uv is missing` or `The .NET SDK is missing` | Redo step 2, then run the `--doctor` check. |
| `Install Xcode 27.2 and its Metal Toolchain` or a Metal compiler version error | Install exactly Xcode 27.2, open it once, run `xcodebuild -downloadComponent MetalToolchain`. Don't bypass the version check. |
| `Choose a game folder outside a Git repository` / `Keep game files outside the builder source` | Move your game folder somewhere else (step 4). |
| `The supported Ocarina of Time v131072 RomFS image was not found` | The folder doesn't contain update **v131072**. This preview supports only that update. |
| `Builder files are missing` | Download the full ZIP again from Releases and replace the app. |
| The app or game won't open ("cannot be opened" / "unidentified developer") | Right-click → **Open**, or **System Settings → Privacy & Security → Open Anyway**. |
| Black window | Keep the window visible and in front; don't switch to fullscreen. If it stays black, quit and reopen. |
| Low frame rate | Rebuild with the performance preset ticked, close other apps, plug in power. |

Open an issue with your Mac model, macOS version, which preset you used, and the game log. Never attach game files, saves or keys.

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
| [cheemu21 / kid-with-sword-remake](https://github.com/cheemu21/kid-with-sword-remake) | The fork GreenKid-MV 0.1.0 was built on: Ocarina-specific integration, presets, upscaling work and documented Mac/iPhone experiments. Its Ocarina features are carried forward onto upstream main in 0.2.0. |
| Xipzer | Performance work credited in the imported history and fork documentation. |
| Pedro Nascimento | Imported graphics-scale work and other contributions, as recorded in the upstream history. |
| [All recorded upstream contributors](AUTHORS.md) | The complete author list from the pinned source snapshot, with example commit links. |
| [jhaizhou-ops / d2r-mobile](https://github.com/jhaizhou-ops/d2r-mobile) | The native-execution foundation acknowledged by nxnative. |
| Ryujinx, LibHac, SPIRV-Cross, Atmosphère, MacNativeGames and the other dependency authors | Translation, extraction, system references and supporting libraries. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). |

GreenKid-MV adds the distribution boundary, local-builder launcher and packaging checks. It does not claim authorship of the imported engine fixes. The straightforward README organization was inspired by [NX2navi](https://github.com/tangerineturtle1/NX2navi); none of that project’s code, artwork or restricted additions were imported.

## Licence and project identity

The imported engine retains its [MIT licence](LICENSE). Third-party components retain their own terms and notices. The original upstream overview is retained in [UPSTREAM_README.md](UPSTREAM_README.md).

No software licence grants rights to Nintendo’s game content. Removing game data from a release is a technical distribution boundary, not legal clearance. GreenKid-MV is an independent project and is not affiliated with or endorsed by Nintendo. Game and platform names belong to their respective owners.
