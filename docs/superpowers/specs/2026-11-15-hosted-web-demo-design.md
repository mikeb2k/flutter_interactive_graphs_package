# Hosted web demo

## Intent

Anyone reading the package page on pub.dev can try the example app in a browser, without installing Flutter.

## Goals / non-goals

- Goal: a public, always-current demo URL, linked from the pub.dev page info (sidebar).
- Non-goal: new screens or Dart changes; the demo is the existing example app (opens on the Showcase tour).
- Non-goal: a README link (not required; can be added later).

## Approaches

1. **GitHub Pages deployed by a GitHub Actions workflow (picked):** repo is public, no accounts or secrets, redeploys on every push to `main`.
2. Firebase / Netlify / Vercel: same result, needs an account and a deploy token secret.
3. Hand-built files on a `gh-pages` branch: goes stale.

## Design

- `.github/workflows/deploy-demo.yml`: on push to `main` and `workflow_dispatch`, build `example/` with
  `flutter build web --wasm --release --base-href /flutter_interactive_graphs_package/`, deploy with
  `actions/upload-pages-artifact` + `actions/deploy-pages`. URL: `https://mikeb2k.github.io/flutter_interactive_graphs_package/`.
- WebAssembly: verified the example compiles with `--wasm`; the build also emits the JS fallback for browsers without WasmGC.
- `example/web/index.html`, `manifest.json`: real title and description instead of the template placeholders.
- `pubspec.yaml`: `homepage:` set to the demo URL (pub.dev shows it in the sidebar); bump to `0.2.2` with a `CHANGELOG.md` entry, since pub.dev freezes metadata per version. The user publishes.
- Enable Pages with build type "workflow" via `gh api` (approved by the user).
- `docs/superpowers/` added to `.pubignore`.
