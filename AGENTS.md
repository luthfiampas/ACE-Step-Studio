# ACE-Step Studio guidelines

This branch runs the studio on a RunPod pod: a Rust/Axum service, native C++/CUDA
engines, and the React client in a browser tab on the laptop. The desktop shell
in `desktop/` is upstream and is not the path this fork deploys.

- Do not add Python or Node.js to the song-generation path.
- Python is an optional tool runtime (voice swap, de-reverb), installed from
  Settings and never required to make a song.
- Model engines are adapters; no UI or server code may hardcode one model's behaviour.
- Keep OpenRouter model identifiers in provider configuration, not source code.
- Every local engine must expose install state, capability metadata, cancellation and progress before it reaches the UI.
- Model weights, API keys, media and caches are runtime user data; never commit them.
