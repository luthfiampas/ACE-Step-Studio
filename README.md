# ACE-Step Studio

A fork of [timoncool/ACE-Step-Studio](https://github.com/timoncool/ACE-Step-Studio). Upstream is a desktop application that needs a local NVIDIA GPU with 4 GB to 18+ GB of VRAM. This fork runs generation on a headless server on [RunPod](https://runpod.io); the client is a browser tab.

## Requirements

- Linux or macOS with `ssh` and `scp`.
- Node.js 22 and npm.
- Rust stable. `rust-toolchain.toml` pins the channel.
- Docker for the first build. It compiles the server and the engine in a container, so no local GPU is involved.
- A RunPod account with an API key and a persistent Network Volume.

## Quickstart

```bash
cargo run --release -p launcher
```

1. `n` creates a pod. The network volume you pick fixes its region and mounts at `/workspace`.
2. `b` builds the server and `e` builds the engine and the Linux MIDI tools, once per checkout. `P` uploads the full bundle; `p` pushes only the server after it changes.
3. `Enter` opens the tunnel. `w` starts the web dev server and `o` opens `http://localhost:3000`.

Press `?` in the launcher for the other keys.

## How it works

The tunnel forwards a local port to `127.0.0.1:8792` on the pod, encrypted over RunPod's SSH port. The local port defaults to 8792, and `c` changes it. No web port is exposed.

Weights, audio caches and your library stay on the volume under `/workspace`. The bottom bar shows balance, VRAM, CPU and RAM. `x` stops the pod and ends GPU billing.

## Python runtime

**Settings → Python runtime** installs the environment the Python tools share: Python 3.12 and torch, about 8 GB, and ten to twenty minutes on the network volume, once. It is not part of any one tool. A tool adds only its own loader and model on top, and a pod restart never reinstalls it.

## Misc

The tools that are not part of making a song live under **Misc** in the sidebar. They get their own list, their own history, and no say in how a song is made. Voice swap and De-reverb are there now; the next tool goes beside them.

### Voice swap

Trains a voice from your recordings and sings a vocal stem in it. Recordings are a draft until training has made a model. Once a run succeeds they are deleted, and the voice keeps the minutes it was trained on along with one 55 MB model per saved checkpoint. A long run leaves many. **Clean up** keeps the ones you tick and deletes the rest. A swap takes an uploaded stem or a vocal stem already separated in the library, and writes a WAV into the tool's own history. No song is created or changed.

Everything lives under `/workspace/ace-step-studio/data/voice-swap`, so models and results survive the pod. Training needs an NVIDIA card; a conversion can fall back to the processor. The pinned RVC commit is in `engines/rvc-source.json`.

### De-reverb

One model, `UVR-DeEcho-DeReverb` (214 MB): a vocal stem in, the dry take and the reverb that was removed out, both kept beside the run in the history. It takes out the room a generator baked into a vocal, the part a separator cannot help with, and which a voice model otherwise learns.

It runs through `audio-separator` in the shared Python environment, so it adds a loader and a model rather than another interpreter. None of the models makes a wet vocal dry, so a dry recording still beats any of them.

## Stems

HT-Demucs runs in the service and leaves six stems. Mel-Band RoFormer leaves the vocals and the instrumental, and BS-RoFormer SW leaves six sources from one mask. Both run on the BSRoformer.cpp build the studio downloads, on the pod's card. Choose the separator under Settings → Models → Stems.

## Building the binaries

No binaries are shipped prebuilt, so the first deployment compiles them: `b` and `e` run `runpod/build-server.sh` and `runpod/build-engine.sh`. Afterwards they live in `/workspace/ace-step-studio/bin` on the volume, and later sessions only reconnect.

The engine build is the slow one. It clones the commit pinned in `engines/engine-source.json`, compiles the CUDA 12.8 backend and every processor generation from Turing to Blackwell unless you narrow `CUDA_ARCH`, and then builds the Linux `music-midi` and `music-caption` with the repo's own script. The downloadable HOT-Step pack is a Windows build. `JOBS` (default 4) sets parallel compile jobs.

Without Docker, the server script falls back to a host `cargo build`. That only produces something the pod can run when the host is a compatible Linux x86-64.
