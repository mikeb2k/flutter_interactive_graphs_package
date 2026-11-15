# Hosted web demo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deploy the example app to GitHub Pages (WebAssembly build) and link it from the pub.dev sidebar.

**Architecture:** A GitHub Actions workflow builds `example/` for the web on each push to `main` and deploys it to Pages; `pubspec.yaml` `homepage:` points at the URL.

**Tech Stack:** Flutter web (`--wasm`), GitHub Actions, GitHub Pages.

**Spec:** `docs/superpowers/specs/2026-11-15-hosted-web-demo-design.md`

## Global Constraints

- Demo URL: `https://mikeb2k.github.io/flutter_interactive_graphs_package/`
- Build: `flutter build web --wasm --release --base-href /flutter_interactive_graphs_package/` in `example/`
- No Dart changes. Version `0.2.2`. The user runs `dart pub publish`.

## Review Focus

- Base href wrong → blank page with 404s on assets. Check: load the deployed URL, assets return 200.
- Browser without WasmGC (older Safari) → must fall back to JS. Check: `main.dart.js` present in the artifact.
- No cross-origin isolation on Pages → wasm build must still start. Check: deployed page renders in Chrome.

---

### Task 1: Deploy workflow, web metadata, pubspec

**Files:**
- Create: `.github/workflows/deploy-demo.yml`
- Modify: `example/web/index.html` (title, description, apple title), `example/web/manifest.json` (name, short_name, description)
- Modify: `pubspec.yaml` (`homepage:`, `version: 0.2.2`), `CHANGELOG.md` (`## 0.2.2`), `.pubignore` (`docs/superpowers/`)

- [ ] **Step 1:** Workflow: triggers `push: branches [main]` + `workflow_dispatch`; permissions `contents: read`, `pages: write`, `id-token: write`; concurrency group `pages`. Job `build`: checkout@v4, subosito/flutter-action@v2 (stable, `3.x`, cache), `flutter pub get` + build in `example/`, `actions/upload-pages-artifact@v3` with `path: example/build/web`. Job `deploy`: needs build, environment `github-pages`, `actions/deploy-pages@v4`.
- [ ] **Step 2:** Metadata: title "interactive_graphs demo", description "Try interactive_graphs, a Flutter package for interactive directed graphs, in your browser."
- [ ] **Step 3:** Verify locally: run the build command from Global Constraints. Expected: `✓ Built build/web`, `main.dart.wasm` and `main.dart.js` present.
- [ ] **Step 4:** `checker` agent (analyze + tests unchanged), then `rules-reviewer`.
- [ ] **Step 5:** Commit `ci: deploy the example app to GitHub Pages as a live demo`.

### Task 2: Enable Pages, push, verify live

- [ ] **Step 1:** `gh api -X POST repos/mikeb2k/flutter_interactive_graphs_package/pages -f build_type=workflow`
- [ ] **Step 2:** `git push origin main`; watch the run with `gh run watch`. Expected: both jobs succeed.
- [ ] **Step 3:** `curl -sI` the demo URL and `main.dart.wasm`: 200. Open in Chrome: Showcase renders.
- [ ] **Step 4:** Tell the user to run `dart pub publish` for 0.2.2.
