# Master implementation prompt: Fork `pi-genui` into a complete, maintainable, token-efficient generative UI and simulation system for Pi Coding Agent

> **Purpose:** Paste this entire prompt into Codex or a capable Pi Coding Agent coding session. This is an **execution specification**, not a request for an analysis-only report. The coding agent should inspect, implement, test, document, and honestly report progress. It must not falsely claim to have forked, published, tested, or implemented anything it has not actually done.
>
> **Source baseline researched:** 15 November 2026. Repositories change; first inspect current upstream commits/releases. The precise historical baseline and sources appear in Appendix A.

---

## 0. Role and mission

Act as a senior TypeScript/Node.js systems engineer, Pi Coding Agent extension developer, terminal rendering engineer, numerical simulation developer, security reviewer, test engineer, and long-term open-source maintainer.

**Fork and substantially extend [`chrischriscris/pi-genui`](https://github.com/chrischriscris/pi-genui)** into an independently maintainable Pi extension that:

1. **Reaches demonstrable functional parity with all 23 components and the important interaction, rendering, and usability behaviors of [`newtonapple/pi-openui`](https://github.com/newtonapple/pi-openui)**, so I can remove or avoid installing `pi-openui` entirely. “Parity” means equivalent *user capability and quality*, not necessarily source-code or syntax compatibility with OpenUI Lang. Identify any deliberate incompatibilities and test them.
2. **Exceeds both upstream projects** with genuinely continuous terminal-native animations, accurate numerical simulations, responsive controls, dynamic dashboards, richer charts, scalable graphics, and extensibility well beyond a double pendulum.
3. Delivers an experience as close as technically practical to **ChatGPT/Claude interactive widgets, plots, animations and simulations** while remaining inside **Pi Coding Agent in Kitty terminal**. Where terminal limitations prevent web-quality output, provide a documented, optional, strictly local fallback. Do not quietly replace terminal rendering with an external browser.
4. Preserves the strengths of `pi-genui`: a single `render_ui` tool, compact JSON-oriented spec, incremental/streaming rendering, local stateful calculators, model-independent interactions, sensible mouse/keyboard control, and aggressive management of model-context overhead.
5. Maintains first-class compatibility with my existing **`pi-vim`** extension and **`Ctrl+G`** interrupt behavior; never replace the main Pi editor or assume the fork owns all terminal keys.
6. Is independently buildable, testable, releasable, auditable, easy to update from upstream, and has a written realistic **maintenance plan, responsibilities, costs, security posture and upgrade strategy**.

**Execution goal:** Deliver working, reviewable code—not a prototype masquerading as a finished library. Do as much implementation as the environment permits, follow the staged gates below, and state precisely what remains incomplete. Never mark parity “complete” based on a feature name, screenshot, placeholder or mocked output alone.

---

## 1. My environment and absolute constraints

- I use **Pi Coding Agent with Kitty** on Linux. My live global Pi configuration is the ordinary **`~/.pi/agent/`** directory.
- **Do not introduce Nix, a flake, Home Manager, a new Pi config location or a new Pi distribution.** This is an extension project, not a rewrite of my agent configuration.
- Preserve my other installed Pi extensions, tools, settings, models, credentials, sessions and keybindings. **Do not modify, reset, delete or migrate `~/.pi/agent` without explicit approval.** Use a temporary isolated `PI_CODING_AGENT_DIR` for integration tests and demonstrate a reversible installation path.
- I use `pi-vim`: **Escape should continue to enter Vim normal mode**, and `Ctrl+G` should interrupt Pi. Do not capture those keys while the visualization is unfocused; while focused, provide explicit, tested exit/focus behavior. Detect key conflicts and document alternatives.
- I have encountered real editor ownership conflicts between `pi-vim` and `pi-open-tui`. **Never call `ctx.ui.setEditorComponent()` to install your own input editor** and avoid taking over Pi header/footer/theme unless the feature can operate without such ownership.
- My Pi setup may use `carderne/pi-sandbox` and other permission extensions. Respect restrictions; **do not disable or bypass sandboxing to display images, execute a simulation, download assets, write files or launch a preview**.
- **All visual rendering and simulation updates must happen locally**. No cloud rendering, telemetry, remote scripts, hosted CDNs, analytics or model calls per frame/interaction.
- **Default behavior must be offline at runtime** once installed, except ordinary Pi model calls explicitly initiated by the user or necessary initial installation/update steps. Optional third-party integrations must be opt-in and explicitly documented.
- **Low model-token overhead is a hard requirement**. Nothing should trigger additional LLM requests merely to animate, move a slider, inspect a graph, page through a table, hover, navigate, or change a local simulation parameter.
- Do not add a large always-loaded prompt, permanent system instructions, duplicate agent tools, extra subagents or unnecessary generated context. Prefer the existing single `render_ui` tool and selectively retrieved component reference/help.
- No automatic model-generated content such as summarization, captions, model-backed visualization validation or re-render calls during local interaction. All such operations must require explicit user intent.
- Avoid new heavy dependencies by default. Benchmark dependency size, startup time and vulnerabilities. Keep standard terminal rendering usable without Chromium, WebGL or an external service.
- Keep builds reproducible. Commit lockfiles; document compatible Node/Bun/Pi versions; never silently update the user's global packages.
- MIT licensing and third-party licenses must be preserved. If reusing code from `pi-openui`, carry over required copyright/license notices and source attribution. Do not copy copyrighted screenshots/assets blindly.

### Definition of “feature-complete with pi-openui”

Achieve **functional parity** with `pi-openui` for each documented component and behavior (including keyboard/mouse interaction, graceful fallback, accessibility, data validation and narrow-terminal presentation) in the fork's own JSON-oriented specification. A separate **OpenUI Lang source-compatibility adapter is optional**, not a prerequisite to being able to uninstall `pi-openui`; only implement it if there is a compelling compatibility need and it does not increase default model-token usage or compromise maintainability.

---

## 2. First actions: verify sources, permissions, toolchain, versions

Before making edits, do the following. Do not rely only on this prompt's version snapshots:

1. Inspect both repositories and their latest commits, releases, changelogs, README files, component references, keyboard/mouse behavior, source architecture, tests, LICENSE files and available issues/PRs:
   - `https://github.com/chrischriscris/pi-genui`
   - `https://github.com/newtonapple/pi-openui`
2. Inspect **current official Pi extension, tool-rendering and TUI APIs**: `https://pi.dev/docs/latest/extensions` and related TUI, settings, packages, models, keybindings, custom-entry and terminal graphics documentation. Confirm actual API names against installed Pi source/types instead of guessing.
3. Check `pi --version`, Node/Bun versions, Kitty version/graphics capabilities, Git status and project path. Preserve the repository's pre-existing working tree; never overwrite unrelated modifications.
4. Verify repository/fork permissions using `gh auth status` only if GitHub operations are available. If authenticated and authorized, fork into my account or organization after determining the target owner. If authentication, network access or permissions are absent, **create a normal local Git clone and feature branch**, set the original repository as `upstream`, and deliver exact GitHub fork/push steps for me. Never pretend a remote fork exists.
5. Prefer a clear independently identifiable package/repository name, e.g. `pi-genui-plus`, subject to actual npm/GitHub availability. Keep the original authors' credit. Avoid falsely attributing original authorship to me.
6. Audit `pi-genui` baseline before refactoring: run `bun test`, `bun run typecheck` and the existing local examples where supported. Record their actual results. Run the corresponding `pi-openui` tests or analyze its test fixtures as an **external comparison**; do not install its extension into my live Pi.
7. Capture and pin the two audited upstream commit SHAs in `docs/upstream-baseline.md`; record versions, URLs, dates, license and parity differences. Any later upstream update must rerun this audit.
8. Produce `docs/feature-parity.md` with individual rows: *feature*, *upstream behavior*, *fork behavior*, *implementation status*, *test coverage*, *manual evidence*, *known limitations*, *priority*. Use honest states `missing`, `partial`, `implemented`, `tested`, `released`—not unchecked “done”.

Then **proceed to implementation** rather than stopping after the audit. If the scope exceeds one execution budget, finish a coherent tested milestone, commit it, and document the remaining phases with dependencies and acceptance tests.

---

## 3. Core architecture: extend `pi-genui`, do not glue two extensions together

Use `pi-genui`'s existing concepts as the foundation:

- `src/core/` — declarative spec and registry, validation, expressions, runtime state, hit testing, pointer dispatch, layouts and terminal rendering;
- `src/components/` — built-in chart, layout, text, data and control components;
- `src/pi/` — Pi adapter, tool registration and rendering, UI focus, agent-session lifecycle, state persistence and context compression.

### Required architectural rules

1. **One Pi model tool by default:** retain `render_ui`, its streaming behavior and its concise tool schema. Do not ship a second `render_widget` tool or duplicate `pi-openui` registration by default.
2. Use a **component registry** with `registerComponent`/extension events and explicit feature contracts; do not bake each new component into a giant conditional renderer.
3. Separate **model-authored declarative spec** from **trusted implementation plugins**. A spec may describe chart data, formulas and simulation parameters, but must not arbitrarily obtain filesystem/network access.
4. Introduce a lifecycle-aware **reactive runtime**: controlled state, derived computations, events, optional time source, animation scheduler, pause/resume/step, disposal, and invalidation. Keep runtime objects independent of Pi to enable pure testing.
5. Introduce **rendering backends** with a common scene/canvas abstraction where appropriate:
   - portable Unicode/Braille/block-character renderer (mandatory);
   - Kitty graphics-protocol raster backend (optional capability enhancement);
   - plain-text/static fallback for unsupported terminals and noninteractive modes;
   - optional explicit export to local HTML/SVG/PNG/GIF or localhost browser view if useful, but **never as the only implementation**.
6. Preserve Pi's normal tool-renderer, custom-entry or other officially supported integration for chat-inline output. Prefer public APIs over private Pi internal imports. Implement fallbacks if APIs are unavailable on older supported Pi versions.
7. **No editor replacement.** Widget input may be grabbed only while intentionally focused; no interference with `pi-vim`, shell prompts, global shortcuts, custom permissions or terminal scrollback.
8. Keep layouts and widgets **bounded, resize-aware and interruptible**. Limit animation CPU load, number of active widgets, frame memory, text width and data size.
9. Support resuming sessions: old static widgets must still render; active animations must not invisibly keep running after session switch; either offer explicit resume or clearly restore a paused/snapshot state.
10. Build a stable **schema/version migration strategy** for saved widget specs. If `pi-genui`'s `render_ui` spec evolves, preserve old output through a versioned decoder or a credible fallback with an error explanation.
11. Avoid global mutable registries leaking between sessions; clean up timers, mouse capture, listeners, images and render caches on `session_shutdown`, abort, tool replacement and UI disposal.
12. Document any genuinely unsafe escape hatch as **disabled by default** with an explicit trust model, never silently enabled for model-authored widget specs.

### Security requirement for expressions

The current `pi-genui` expression evaluator uses `node:vm` and notes that its 150 ms timeout is **not a security boundary**. Do not present it as sandboxed execution. Audit whether to retain this for trusted local specs, introduce a safe expression parser/interpreter (preferable for generic model-authored specs), or require explicit opt-in for arbitrary JavaScript. The default must prevent unexpected filesystem/network/process capabilities, enforce bounded evaluation and collection sizes, reject prototype-polluting or malicious keys, sanitize output and avoid ANSI/OSC control injection from untrusted strings.

Document trade-offs and add malicious-input tests. Respect the existing Pi sandbox—this extension is **not** a substitute for process isolation.

---

## 4. Full `pi-openui` capability parity: 23-component matrix

The upstream `pi-openui` component gallery documents **23 components**. Implement **user-observable feature parity**, not merely matching component names. Keep `pi-genui`'s concise JSON schema. Add aliases only when unambiguous and backwards-compatible.

| # | `pi-openui` component | Required fork behavior and likely `pi-genui` baseline/gap |
|---|---|---|
| 1 | **Stack** | Vertical/flow layout, padding/gaps, wrapping, nested constraints; extend current `col`/`row`. |
| 2 | **Text** | Styled, wrapped, aligned text, Unicode-safe display; extend `text`. |
| 3 | **Card** | Framed container, headings, nested content, constrained layouts; extend `box`. |
| 4 | **Callout** | Tone-aware notices, labels and responsive content; extend `note`. |
| 5 | **Metric** | KPI/value/change/trend tiles, number formatting and tooltip anchors; extend `stat`. |
| 6 | **Table** | Headers, responsive scrolling, pinned columns, cell truncation/full-text inspection, focus/selection, annotation targets, 100x16 baseline-scale test; extend `table`. |
| 7 | **Tabs** | Keyboard and mouse switching, preservation of per-tab state, narrow wrap; extend `tabs`. |
| 8 | **Button** | Distinguish purely local actions from explicit user-to-agent actions; acknowledgement, disabled/loading states; adapt `buttons`. |
| 9 | **Choice** | Single/multiple selections, optional Other text, staging across questions, one explicit Send answers action, Clear, retry and lock-on-delivery; extend `select`/`multi` with an explicit choice workflow. |
| 10 | **Faq** | Expand/collapse question answers, focused navigation, optional Markdown, tooltips and annotations. |
| 11 | **Markdown** | GFM-like readable terminal formatting, code, lists, links, supported local image lines; retain `md` baseline. |
| 12 | **CodeBlock** | Language-aware syntax highlighting, wrapping/scroll, line numbers where appropriate, safe explicit copy; extend `code`. |
| 13 | **Image** | Real local image rendering in Kitty when available, captions, dimensions, optional tooltip, secure offline loading, accurate framed placeholder otherwise. |
| 14 | **BarChart** | Horizontal/vertical bars, proper axes, labels, hover values and selection, size limits; extend `bar`. |
| 15 | **LineChart** | Multiple series, axes/legends, point hover, crosshair, high-resolution Braille line plotting, responsive downsampling; extend `line`. |
| 16 | **AreaChart** | Filled and optionally stacked areas, accurate totals/baselines, axes/legends/hover; do **not** claim current `line` alias is sufficient. |
| 17 | **PieChart** | Circular/donut or justified terminal approximation, slices/legend/percentages, keyboard selection and anchored tooltips. |
| 18 | **RadarChart** | Multi-axis polygons, multiple series, scales, legend, keyboard-readable alternative and data validation. |
| 19 | **GeoMap** | Bundled offline world geography, pin placement, optional links, scale/fit, hover and keyboard details; no network tiles by default. |
| 20 | **Dag** | Layered directed graphs, cycles, labels, arrowheads, reliable routes, focus and edge/node annotations; extend but do not equate with basic `flow`. |
| 21 | **Erd** | Entity tables, fields, relationship cardinalities and connectors, accessible field navigation and reliable routing. |
| 22 | **InfraMap** | Zones, service/database/queue nodes, labeled directed connections, graph layout and route legibility. |
| 23 | **SequenceDiagram** | Participants, ordered messages, arrows, notes, alt/loop frames and large-step scrolling. |

### Cross-cutting parity behaviors: mandatory

- Interactive **tooltips** anchored to graph/chart/table/map/image elements, with tone, detailed panel, links and keyboard alternative.
- **Pinned notes/annotations** on the same semantic elements, including table cell/row/column, chart point/series/slice, diagram edge/node, map pin/link, text component and image; editable local notes; explicit batch staging into Pi's input editor; **never automatically send** a model prompt. Protect against control characters, fake file mentions and prompt injection in generated note text.
- **Keyboard parity** with mouse functionality; Tab/Shift+Tab, arrow navigation, Enter, Escape, hover/focus feedback. Do not steal normal typing from `pi-vim`. Appropriate discoverable key hints and help.
- **Mouse parity** in native fullscreen Kitty: clicks, drag, wheel, pointer target accuracy, safe hit-test bounds and hover where supported. Degrade under tmux/zellij and narrow/mobile/SSH terminals.
- Responsive **narrow-terminal panning** for diagrams/tables/code/charts, with visible scroll indicators, page/fine steps, pinned columns, no inaccessible data. Test width 40, 60, 80, 100, 120 columns and varying heights.
- Full/expanded **truncated cell values**, meaningful warnings, visually stable controls, Unicode grapheme/width handling including combining characters and wide CJK glyphs.
- **Offline local image support** via Kitty graphics protocol if the Pi TUI offers compatible capabilities; valid fallback if not, no automatic network image fetch.
- Per-element semantic annotations, charts with multiple series and accurate axis/legend data, and sensible color-blind/text-only alternatives.
- Robust **diagram routing**: edges must never silently disappear or be depicted ambiguously. Implement or adapt a routing algorithm with a **round-trip graph decoder/oracle** independent of the layout engine, and test cycles, crossings, fan-in/out, text labels, large graphs and random graphs. A failed edge must be reported explicitly.
- Bounded widget sizes, graph counts, nesting, images, cache sizes, strings and render rows; validation errors must explain what and where to fix. No infinite loops, denial-of-service via huge arrays or exploding layouts.
- **Session history**: redraw saved static widgets, readable failure when an old schema cannot load, and deterministic handling of notes/choice delivery state.
- **Existing `pi-genui` capabilities must not regress**: streaming partial JSON, scalar calculator expressions, render_ui, wait/non-wait semantics, buttons, forms, tree, flow, heatmaps, tooltips, compact old contexts and Alt+G focus behavior (except documented conflict resolution).

### Parity proof

Create `docs/feature-parity.md` with a runnable representative fixture for each of the 23 components and a test for each interaction family. Build a self-contained `/genui-gallery` (and category-specific demos) that reproduces the same *kinds* of behavior without requiring `pi-openui`. Include a `wide` gallery for narrow-screen stress tests. If practical, build a differential fixture runner comparing rendered geometry and interaction semantics against `pi-openui`, but do not copy its private source wholesale or require users to install it.

**Uninstall criterion:** all 23 component families and relevant cross-cutting behaviors are *implemented and verified* in the fork; its examples, docs and test fixtures run with `pi-openui` absent; there are no imports from `pi-openui` at runtime; Pi registers only the expected fork tool(s)/commands; any exceptional parity gaps are prominently declared, not hidden.

---

## 5. Beyond `pi-openui`: a generalized local animation and simulation engine

**Animation must mean continuous time-driven visual updates, not a slide deck, static chart, repeated LLM requests or a timer that blocks Pi's editor.** Provide physics/simulation infrastructure reusable by arbitrary components.

### 5.1 Reactive scene and animation subsystem

Build a documented reusable core, with explicit capabilities:

- `start`, `pause`, `resume`, `stop`, `reset`, `step`, `seek` and speed multiplier;
- deterministic fixed-step simulation clock independent of renderer frame rate; bound catch-up steps to prevent spiral of death;
- time-varying state and derived values, user-controlled parameters, configurable interpolation and trails;
- controlled local keyboard/mouse inputs; playback persists only where sensible;
- frame scheduling that requests a Pi redraw only when needed (prefer authoritative TUI APIs), coalesces updates, and avoids redraw storms;
- capability-aware Unicode/Braille raster output, optional Kitty image-frame output, automatic static fallback;
- scene primitives: points, polylines, circles/discs, arcs, lines/arrows, polygons, text, grids/axes, paths/trails, sprites or bitmap overlays when supported;
- simple transforms: translation, rotation, scale, pan/zoom, viewport normalization and clipping;
- scene hit testing and accessible textual equivalents for controls/graphs;
- resize, theme change, transcript scrolling, tab switch and session switching with correct state invalidation;
- no zombie loops, leaked timers, unbounded histories or repeated frame output after interruption.

Set realistic **benchmark-based** interactive goals: first measure actual Kitty+Pi costs. For portable Braille animation, target useful 10–20 FPS on an ordinary workstation and optimize higher if verified. Higher raster/Kitty rates are optional and must be justified with measurements. Never assert 60 FPS without actual packaged runtime tests. Pause rendering when hidden, off-screen, aborted or idle. Use adaptive frame skipping and CPU limits.

### 5.2 Reference implementation: physically correct double pendulum

Provide a dedicated first-class simulation/demo with:

- Two pendulum arms and bobs; user-adjustable gravity, lengths, masses, initial angles, initial velocities, optional damping, simulation speed and drawing scale;
- correct coupled equations of motion for a planar double pendulum, robust handling of singular/invalid parameters, deterministic integration (RK4 or another justified integrator), fixed simulation timestep and time/fps separation;
- animated bobs, rods, a trailing second-bob path and live angle/phase/energy plots;
- visible Play/Pause, Reset, Step, Clear Trail, Show/Hide Trails, optional preset controls;
- keyboard navigation and mouse clicks/drags that do not interfere with Pi/editor interactions;
- stable terminal output at 40/80/120 columns and correct redraw after resize;
- visible equations/units or a short model description and a disclaimer about numerical approximation;
- tests that compare numerical output against independent reference cases, check energy drift in a conservative system, prove no model calls on frame/slider changes, and confirm cleanup on navigation/disposal.

The double pendulum is a **gate**, not the end goal. Do not declare the entire fork complete once this demo animates.

### 5.3 Additional built-in simulations and animation demos

Build a reusable library and demonstrate at least these distinct simulation families. Differentiate **core acceptance demonstrations** from advanced examples without pretending every advanced idea is production-ready:

**Core demonstration targets:**

1. Spring–mass and damped/driven harmonic oscillator, adjustable coefficients and energy/position plots.
2. N-body or orbital dynamics with adjustable initial conditions, mass/force and trails; numeric stability controls.
3. Wave propagation or vibrating-string PDE approximation with speed, damping, boundary conditions and a live plot.
4. Cellular automaton (Conway's Game of Life) with live grid editing, pause/step/reset, pattern loading and deterministic updates.
5. Interactive algorithm visualization: sorting and pathfinding, with animation speed, step/back where feasible, highlighted operations and explanatory text.
6. Streaming time-series/multivariate dashboard with throttled data updates, dynamic axes and local data only.

**Stretch targets, only after core parity/animation gates are stable:**

- Parametric curves, Lissajous figures, phase portraits and attractors;
- Brownian motion, random walks, Monte Carlo sampling and distributions;
- Fractals (Mandelbrot/Julia) with zoom/pan, bounded work, cache and cancellation;
- Graph/network process simulation, data-flow animation, interactive Gantt and timeline;
- 2D rigid-body/collision visualization and basic particle systems;
- 3D projection/wireframe rotation or surface visualizations **only if terminal performance and usability justify it**;
- Local animated SVG/HTML/video/image export and optional external local browser for capabilities the terminal renderer cannot reproduce.

Do not claim support for arbitrary HTML, JavaScript DOM, WebGL, WebGPU or a complete Chrome renderer inside the ordinary `pi-genui` component API. Define the exact supported abstraction. Any optional Chromium/terminal-browser integration must be separately installable, off by default, local, security-reviewed, not required for parity, and must not interfere with `pi-vim`.

### 5.4 Generative interface capabilities beyond physics

Support reusable interactive dashboards and applications composed from declarative components, not one bespoke demo per task: linked/brushed charts; chart zoom/pan/crosshair; dynamic legends; forms with validation; local calculators; multi-step workflows; sortable/filterable tables; dates/times/timelines/Gantt where justified; parameter sweeps and comparison views; user-editable annotations; deterministic replay/export; local data import where access is explicitly authorized. Keep the extension generic enough that models can create new visualizations through the same small spec.

---

## 6. Token efficiency: design, measurement and acceptance

The source `pi-genui` README estimates roughly **570 tokens** for its current generated model-facing tool description. Treat that as a measured baseline to verify against the actual target Pi version and tokenizer, not as a universal constant.

**Non-negotiable:** native renderer ticks, simulation physics, resize, slider drags, mouse movement, hover, pan/zoom, tab changes, table sorting, local copying, notes staging and ordinary pause/resume must use **zero additional LLM requests**. A deliberate “send answers to agent”, “ask Pi to explain”, or explicit prompt may trigger a normal turn; make the distinction obvious in UI and docs.

Implement all of the following:

1. Preserve **one** default tool, `render_ui`, with compact JSON parameters and a short description. Avoid making 23+ component references appear in every turn.
2. Keep the default extension's tool-description token count as close to current `pi-genui` as feasible; an initial **<=25% growth budget** is a measurable engineering objective. If this is not achievable without harming discoverability, show exact measured overhead and a selective-reference design rather than lying about it.
3. Make advanced feature documentation **lazy/on-demand** through commands, a `reference`/`capabilities` request on the existing tool, or another mechanism that does not expand the default prompt. Provide targeted component help rather than a 100 KB reference dump.
4. Keep instructions/prompt snippets minimal. Do **not** inject AGENTS.md paragraphs or always-loaded system messages to teach the model every simulation.
5. Preserve and improve `src/pi/context.ts`'s historical widget summarization/trim approach. Ensure rich new specs, large arrays, image frames, animation ticks and simulated points never bloat previous turns or break prompt caching.
6. Do not append per-frame events or full physics trajectory data to the transcript/model context. Store ephemeral state locally; only store small declarative specs, optional user-approved checkpoints and compact scalar summaries.
7. Avoid model-facing tools returning full rendered strings/frames or huge data tables when a concise success/error summary suffices.
8. Prefer model-independent validation with precise local errors rather than repeated agent-assisted self-repair loops. If a model correction is necessary, return one focused error instead of dumping complete docs.
9. Make all model-triggering actions conspicuous; batch multi-choice answers into one explicit send. Notes should stage in the editor, not silently send.
10. Provide `docs/token-benchmark.md`: initial token count; first render; subsequent turns with 1, 10, 100 widgets; after resuming a session; when requesting advanced reference; with and without the fork. Separate **tool-schema/context tokens** from **actual API calls and inference costs**.
11. Provide an optional **local-only diagnostics** mode reporting frame rate, CPU time, memory/cache use, count of model-facing events and serialized tool/context size without model calls or external telemetry.

An extension that is visually rich but adds persistent unnecessary context is a failure against my requirements.

---

## 7. Rendering fidelity, terminal input and compatibility

### Kitty-native experience

- Discover Kitty graphics support with a documented capability test; do not blindly emit Kitty escape sequences to incompatible TTYs or logs.
- Use Pi/`pi-tui`'s supported image capabilities if available, and verify protocol support for multi-frame raster updates. If Pi only supports static images, do not claim a stable animated Kitty backend without implementing and testing the missing lifecycle/memory semantics.
- For non-Kitty terminals or image-disabled environments, use Unicode/Braille/ANSI scene rendering. No missing-controls dead ends.
- Preserve selection/copy, scrollback, CLI history, line wrapping, focus, active input and Pi hotkeys. Do not trap Escape unexpectedly.
- Handle resize, DPI scaling, Unicode width, wide glyphs, ANSI sequences and truncated output consistently.
- Ensure mouse capture is correctly enabled only in supported fullscreen UI mode and is released on exit/abort; mouse-free control is mandatory.
- Test both full-screen and inline TUI modes. In print/JSON/RPC modes render informative text/static snapshots, not broken interactive prompts.
- Test inside Kitty directly and, if feasible, under tmux/zellij with documented limitations; do not assume all terminal multiplexers support hover or images equally.

### Pi extension coexistence

- Use Pi extension APIs properly (`pi.registerTool`, `renderCall`/`renderResult`, optional UI commands, `ctx.ui.custom`, TUI redraw callbacks and lifecycle events where supported). Read their exact current signatures before coding.
- Never override `pi-vim`'s editor. Test insert mode, normal mode, Escape, `Ctrl+G` interrupt, typing, selection, paste, and a widget taking/releasing keyboard focus.
- Do not assume `pi-open-tui`, `pi-starline`, `pi-compact-tools` or alternative tool renderer extensions are absent. Detect collisions, provide diagnostics and document which extension wins if multiple tool renderers affect `render_ui`. Do not silently change another extension's configuration.
- Test allowed and denied file operations under `carderne/pi-sandbox` or another configured sandbox **without bypassing it**. The fork may render only resources the Pi process is authorized to read.
- Prevent conflicting tool names if `pi-openui` remains installed temporarily. The final supported setup must function with only the fork installed, and a migration guide should explain removing the redundant package if requested.

---

## 8. Test strategy and quality gates

Automated tests must be maintained as first-class source, not optional afterthoughts.

### Unit / property / model-independent tests

- Spec normalization, schemas, aliases, error messages and input validation;
- every component and option family, responsive layout and safe fallback;
- data transformations and chart geometry, null/NaN/infinity/huge values, multiple series;
- mouse and keyboard focus, hit testing, pointer math, scroll/pan and event capture;
- notes, tooltip anchors, sanitization, staging, single-delivery semantics and no unexpected model turn;
- strict handling of legacy and future widget schema versions;
- graph layout routing and independent reconstruction oracle (randomized property cases, cycles, crossings and Unicode);
- images, capability detection, limits, refusal of unsupported protocols, absence of unsolicited network traffic;
- numerical solvers against independent reference values and invariants, determinism/replay, fixed-timestep correctness and energy drift;
- pausing/stopping, session switch/abort/reload, stale timer cleanup and resource reclamation;
- expression evaluation limits and hostile input/escape-sequence injection;
- context compression, small model-facing tool replies, no frame/state dump in LLM context.

### Integration / acceptance tests

- Baseline `bun test` / `bun run typecheck` (or confirmed equivalent); no regressions to existing `pi-genui` tests.
- Isolated Pi extension load with a **temporary** `PI_CODING_AGENT_DIR`, no writes to actual `~/.pi/agent`.
- Real terminal fixture using the installed Pi version plus `pi-vim` and `Ctrl+G`; simulate a widget stealing focus, then verify ordinary editor behavior is restored.
- Direct Kitty smoke run for image-backed output, animation and keyboard/mouse. If CI has no Kitty-compatible renderer, document that CI tests a substitute and include a manual-release gate.
- Visual snapshots/goldens for all 23 components and demos at representative terminal widths; deterministic color/Unicode fallbacks.
- End-to-end `/genui-gallery` and `/genui-demo` with no model provider configured; ensure local demos function without API keys and without model calls.
- Reconnect/resume a previous Pi session and verify saved widget rendering does not restart an invisible simulation loop.
- Cold/warm startup, memory growth over long animation runs, CPU load under idle/paused/active, resize stress, unmount/mount and frame throttling.
- Fresh install of **only the fork**; `pi-openui` completely absent and no transitive dependency on it.
- Offline operation after installing dependencies (disable network in test where practical); no telemetry and no unexpected executable/network requests.
- Package tarball/build verification, declared Pi extension entry, release metadata and license files.

### Practical acceptance thresholds

- 23/23 component families have *runnable fixtures and passing behavioral tests*, not just `type` registration.
- Cross-cutting notes, tooltips, keyboard, mouse, narrow terminal, images, routing, validation and session restoration pass their defined tests; document any parity exception.
- Double pendulum runs with correct numerical integration and functional local controls in a real Kitty/Pi session.
- At least the six distinct core demo families in Section 5.3 are implemented and testable; any deferred stretch target must be flagged **not implemented**.
- Continuous animation neither blocks `pi-vim` nor consumes model tokens per frame and releases resources on exit.
- A model can create a dynamic chart/calculator from a normal compact `render_ui` spec; the interface can be manipulated without invoking the model again.
- Benchmarks and compatibility tests are published with real measurements and hardware/software details; no unverifiable performance claims.
- All nontrivial errors produce a readable fallback, never a blank widget or an unrecoverable crash of Pi.

**Never claim completion unless these gates are demonstrably met.** If a work session ends early, maintain a tracked, prioritized checklist and make the implemented subset useful and stable.

---

## 9. Staged implementation plan (use small reviewed commits)

Follow these stages in order; implement vertical slices rather than adding dozens of placeholders:

### Phase 0 — Discovery, fork, architecture and baseline

- Verify source, permissions, current versions, dependencies and API compatibility.
- Create local/remote fork as permitted; establish `upstream` remote and a feature branch.
- Run upstream tests and record baseline; write the parity matrix, risks and architecture decision records (ADRs).
- Add a CI baseline and an isolated local integration harness.

### Phase 1 — `pi-openui` feature parity foundations

- Strengthen text/layout/Unicode/click targets, tables, forms and responsive panning.
- Implement missing chart families: true area, pie and radar, then GeoMap.
- Implement robust diagram families: DAG, ERD, infrastructure and sequence diagrams.
- Add images, code copy, FAQ, detailed tooltips, pinned notes and batch Choice semantics.
- Build 23-component gallery and property/golden tests. Preserve existing `pi-genui` features.

### Phase 2 — Reactive animation engine

- Implement frame scheduler, fixed-step clock, scene API, render backends, frame throttling and lifecycle cleanup.
- First ship a validated terminal-native double pendulum, then spring-mass and cellular automaton.
- Add pause/resume/step controls and live plots, plus direct Kitty tests and perf measurements.

### Phase 3 — Broader simulation and data visualization

- Add orbital/N-body, waves, algorithm animations and time-series streaming.
- Add optional advanced visuals (fractal, particle, projection, local exports) only after the core is solid.
- Validate that any advanced feature remains discoverable without enlarging the always-on tool schema.

### Phase 4 — Hardening, releases and maintenance readiness

- Compatibility matrix, security review, automated tests, benchmarks and offline validation.
- Documentation, installation/migration/uninstall, change log, release automation and upstream sync plan.
- First candidate release, user-facing smoke tests and an honest parity report.

At each phase: make small commits, test them, update `docs/feature-parity.md`, record performance/token impact, and specify how to roll back. Do not merge unfinished unreviewed refactors solely to chase features.

---

## 10. Maintenance study: determine exactly what I must maintain

**This is an explicit deliverable, not a footnote.** Create `docs/MAINTAINERS_GUIDE.md` and `docs/MAINTENANCE_COSTS.md` answering the following with concrete verified facts, commands and ownership boundaries.

### 10.1 Upstream relationships, licensing and ownership

- Record original `pi-genui` and `pi-openui` remotes/SHAs and MIT license notices. Distinguish original code, adapted code, new components, copied test vectors and licensed geographic/font/image data.
- Define whether to contribute improvements upstream, maintain a downstream-only fork, or selectively cherry-pick upstream. Document the trade-offs and a realistic update process.
- Describe how to periodically pull `upstream/main`, inspect changes, resolve conflicts, rerun parity tests, update snapshots and roll back safely.
- State exactly who owns new simulation physics, renderer backends, adapters and custom user-facing API compatibility.
- Keep author credits and copyright headers appropriate. Audit licensing of world-map data, font assets, images, test fixtures, snapshots, external packages and any borrowed routing algorithms before publishing.

### 10.2 Dependency and API upkeep

- Inventory direct, peer, optional and development dependencies, pins/lockfiles and update policies.
- Watch Pi Coding Agent, `@earendil-works/pi-tui`, `@earendil-works/pi-coding-agent`, TypeBox, TypeScript, Node/Bun, Kitty graphics behavior and relevant terminal platforms for changes.
- Define a tested support matrix for the latest supported Pi plus at least one previous compatible release where feasible. Detect breaking Pi extension API changes early.
- Identify which dependencies are critical vs removable, which native addons/Chromium downloads are unnecessary, and what upgrades cost in CI and compatibility work.
- Keep custom graphics capabilities optional. A new optional backend may have separate maintenance and security ownership.

### 10.3 Release engineering

- Provide GitHub Actions or equivalent CI for formatting, lint/typecheck, unit/property tests, reproducible builds, packed-package tests, offline runtime checks and dependency/license scanning.
- Add a release checklist: freeze baseline, update changelog, test real Kitty + Pi + `pi-vim`, inspect token/frame costs, review licenses, generate package, tag release, publish only with explicit authorized credentials, verify clean install and provide rollback notes.
- Adopt SemVer with an explicit widget schema version and migration policy. Explain what changes are breaking, deprecation windows and how old Pi session transcripts are rendered.
- Avoid automatic publishing with unreviewed credentials. Recommend npm 2FA/provenance and GitHub branch protection/PR reviews for a publicly maintained project.
- Include install methods via local path and Git repo, an optional npm package after publication, and exact clean uninstall steps. Do not publish or overwrite an npm namespace without authorization.

### 10.4 Support, security and operational commitments

- Document issue templates, bug reports with sanitized reproducible widget specs, terminal/version information, reproduction commands and benchmark traces. Never ask users to post API keys or private sessions.
- Identify risk areas: model-generated expressions, malicious ANSI/OSC escapes, image parsing, path traversal/symlinks, widget data sizes, unbounded simulations, graphics memory, privileged browser control, extension conflicts and security updates.
- Establish a vulnerability-reporting channel and triage procedure, including emergency disable/rollback of an offending component.
- Define minimum tests before release and what to do when CI has no direct Kitty graphics environment.
- Clarify whether Windows/macOS/other terminals are supported or **best effort**; never promise platforms without a tested maintainer.
- Define how to handle bug reports related to unsupported Pi SDK forks, sandbox configurations, alternative editors and Terminal multiplexers.

### 10.5 Cost and sustainability estimate

Prepare a **grounded maintenance-effort estimate**, not just generic advice. Give a table that separates:

- initial engineering to reach basic parity;
- advanced graphics/physics/simulation engine work;
- recurring weekly/monthly triage and dependency review;
- upstream Pi API or Kitty protocol breakage;
- testing across Pi/terminal/OS versions;
- release preparation and release incidents;
- security incidents and dependency vulnerability remediation;
- documentation/examples/community support;
- ongoing hosted costs (GitHub CI storage/minutes, npm publishing, optional screenshots/assets, test runners)—note that normal local terminal runtime needs no model API expenditure.

Estimate hours or effort bands **with assumptions and uncertainty**, not fabricated precision. Explicitly assess whether one person can maintain the project, what skills/tools that person needs, how to minimize scope and what features are most costly to keep working. Provide a **minimal-maintenance profile** (Kitty/Linux/Pi focused) and a **broader public-maintainer profile** (multiple OS/terminals, binaries, graphics backends). Identify a maintainability ceiling and features that should stay optional or be declined.

### 10.6 Sustainable architecture and fork exit strategy

- Minimize coupling to Pi's private internal APIs and third-party extension internals.
- Prefer tests and behavioral adapters over huge vendor copies. Avoid duplicated code with two competing component registries.
- State how to merge upstream bug fixes with minimal conflict, and whether new components can be contributed back.
- Provide a plan for when the original upstream becomes inactive, when a dependency is abandoned, or when Pi adopts native generative UI features.
- Define feature removal/deprecation criteria, long-term test fixtures and a final “maintenance checklist” I can follow without needing an AI agent each time.

---

## 11. Installation, development and migration requirements

Use **no changes to my live Pi config** until I explicitly approve them. Demonstrate at least:

```bash
# Work inside the cloned fork; inspect commands against current sources first.
bun install --frozen-lockfile
bun test
bun run typecheck

# Manual test without installing into ~/.pi/agent (confirm exact supported Pi CLI syntax first):
pi -e /absolute/path/to/the-fork/src/index.ts

# Only after testing and explicit approval, demonstrate a supported local Git/path install:
# pi install /absolute/path/to/the-fork
# or: pi install git:github.com/<actual-owner>/<actual-repository>
```

Supply an **isolated test recipe** using a temporary `PI_CODING_AGENT_DIR` so tests cannot alter real credentials, sessions or extensions. Supply a verified no-network-at-runtime test recipe where practical. Do not assume the user's live settings include fullscreen TUI; document and test how to set `tuiMode: "fullscreen"` only if required and authorized.

Document migration from `pi-openui`: map its 23 components and interaction families onto the fork; distinguish functionality from syntax. An import adapter for OpenUI Lang files is optional and should be separately evaluated for value versus ongoing maintenance cost. Provide a diagnostic command to check that the fork works without `pi-openui` and does not register colliding tool names.

Documentation must include: quick start, full component gallery/spec, animation API, simulation gallery, keyboard/mouse accessibility, Kitty graphics capability check, performance tuning, security model, troubleshooting, upgrading from upstream, install/uninstall/rollback, token overhead and maintaining the fork.

---

## 12. Required repository deliverables

Deliver or update these **actual files** (adapt paths to the repository structure only where justified):

- `README.md` — what the fork adds, its constraints, setup, examples and explicit parity status;
- `CHANGELOG.md`, `LICENSE` and required `NOTICE`/attribution docs;
- `docs/upstream-baseline.md` — verified source snapshots/versions/commits and links;
- `docs/feature-parity.md` — detailed 23-component and cross-cutting parity matrix with test/evidence links;
- `docs/architecture.md` — component registry, safe expressions, simulation engine, render backends and Pi adapter boundaries;
- `docs/security.md` — trust model, sandbox interactions, filesystem/network/terminal escape handling;
- `docs/tokens-and-performance.md` / `docs/token-benchmark.md` — repeatable measurements, idle and active performance, context growth, zero-model-call checks;
- `docs/animations.md` and `docs/simulations.md` — API, numerical choices, physics validity, sample prompts and hands-on tutorials;
- `docs/kitty-compatibility.md` — graphics capability, terminal modes, keyboard/mouse interactions, fallback and Pi-vim coexistence;
- `docs/install-migrate-uninstall.md` — local and Git install, optional publication, safe migration from pi-openui;
- `docs/MAINTAINERS_GUIDE.md`, `docs/MAINTENANCE_COSTS.md` and `docs/release-checklist.md`;
- `docs/ADRs/` for major decisions: parity vs syntax compatibility, expression trust, frame scheduler, graphics backend, context compression, persistence;
- interactive demo gallery and fixture files for all 23 components plus double pendulum and additional simulations;
- automated unit/property/integration tests, Kitty manual smoke checklist and CI workflow;
- package metadata/lockfile and clear reproducible build/test commands;
- small, cohesive Git commits so changes can be reviewed and reverted.

Also create `docs/implementation-status.md` containing **completed, tested, pending, blocked, skipped**, with concrete reasons and commands to reproduce. If the work runs out of budget or requires a device/credential not available to you, leave the repository in a valid state and identify the smallest next step; do not fabricate completion.

---

## 13. Reporting contract: final answer from the coding agent

When finished, report in this exact logical order:

1. **Fork/repository status:** URL if actually created, otherwise local branch/location; original upstream SHA and current HEAD; publication state.
2. **Executive summary:** what runs now and the user-visible benefit versus pi-genui and pi-openui.
3. **Parity table:** 23 components with actual implementation/test statuses and remaining gaps. State explicitly whether it is safe to uninstall `pi-openui` for my use cases.
4. **Simulation table:** double pendulum and other examples, controls, fidelity, numerical validation and measured animation responsiveness.
5. **Architecture/security:** rendering modes, optional backends, expression handling, sandbox implications and lifecycle.
6. **Token impact:** baseline vs fork, schema-token measurement, model calls per local interaction (must be zero), session context growth and how measured.
7. **Compatibility:** Pi version(s), Kitty and other terminals, fullscreen/inline, `pi-vim`, `Ctrl+G`, sandbox and concurrent extension tests; actual outcomes.
8. **Commands to reproduce:** clean local test, isolated Pi run, demo commands, optional install/rollback; do not modify my live config automatically.
9. **Test evidence:** exact commands, passed/failed/skipped counts, benchmark environment, CI links if real, and known issues.
10. **Maintenance:** what I must update, review, test, release and monitor; realistic effort/cost bands; minimum ongoing checklist and an upstream-sync walkthrough.
11. **Next actions:** small prioritized backlog and blockers; no fake “feature-complete” claims.

Do not stop at an attractive architecture plan. Implement and validate working milestones. Do not claim guaranteed security, FPS, mathematical correctness, model-token savings, compatibility or feature parity without showing how it was verified.

---

## Appendix A — Reference sources and historical baseline (verified 2026-11-15)

**Fork base**

- `pi-genui` repository: <https://github.com/chrischriscris/pi-genui>
- Source snapshot: `0076c32a4ff596c0554b02f53dc88734541e47f1` (GitHub main at research time, 2026-10-27)
- `package.json` reported `pi-genui` **0.1.0**, MIT; Pi peer packages and `typebox`, built/tested with Bun.
- Key sources:
  - <https://github.com/chrischriscris/pi-genui/blob/main/README.md>
  - <https://github.com/chrischriscris/pi-genui/blob/main/src/core/types.ts>
  - <https://github.com/chrischriscris/pi-genui/blob/main/src/core/registry.ts>
  - <https://github.com/chrischriscris/pi-genui/blob/main/src/core/runtime.ts>
  - <https://github.com/chrischriscris/pi-genui/blob/main/src/core/eval.ts>
  - <https://github.com/chrischriscris/pi-genui/blob/main/src/pi/view.ts>
  - <https://github.com/chrischriscris/pi-genui/blob/main/src/pi/context.ts>
  - <https://github.com/chrischriscris/pi-genui/blob/main/src/pi/extension.ts>
- Current documented features: one `render_ui` tool; initial tool-reference estimate ~570 tokens; JSON components; sliders/controls/calculator recomputation; static line/bar/heatmap/etc.; context trimming; `/genui-demo`; dynamic component-registration API. No documented generalized time-driven continuous animation or full scene/physics engine. Four source test files were visible: context, pointer, render and runtime tests.

**Capability parity reference**

- `pi-openui`: <https://github.com/newtonapple/pi-openui>
- Source snapshot: `a249413bc7ee0dc8eedaa38869eb2cba3e2245cf` (GitHub main at research time, 2026-11-15)
- `package.json` reported **0.3.1**, MIT; GitHub release `v0.3.1` dated 2026-11-15.
- Docs and source:
  - <https://github.com/newtonapple/pi-openui/blob/main/README.md>
  - <https://github.com/newtonapple/pi-openui/blob/main/docs/components/README.md>
  - <https://github.com/newtonapple/pi-openui/blob/main/docs/interaction.md>
  - <https://github.com/newtonapple/pi-openui/blob/main/docs/diagrams.md>
  - <https://github.com/newtonapple/pi-openui/blob/main/docs/design.md>
  - <https://github.com/newtonapple/pi-openui/blob/main/src/pi/extension.ts>
- Documented: 23 components; native offline Unicode rendering with Kitty images; notes, tooltip panels, click/keyboard parity, Choice staging, narrow-terminal panning and pinned table columns, specialized diagram routing and independent decode-based tests, gallery demos, settings and error handling.
- Upstream widget limits include ~100 KB source, 1,500 components, 16 nesting levels, 100-row tables, 200 points/8 series for selected charts, 60 DAG nodes, and other per-component limits. These are **reference values for parity testing**, not automatic mandatory fork defaults; choose and justify safe limits.
- The upstream `pi-openui` repo includes a substantially larger test corpus than `pi-genui` (diagram, notes, choices, pan, narrow terminal, image, release and compatibility tests). Use these as coverage inspiration and evidence of why maintenance has real cost.

**Official platform APIs**

- Pi extension development and rendering: <https://pi.dev/docs/latest/extensions>
- Kitty graphics protocol: <https://sw.kovidgoyal.net/kitty/graphics-protocol/>
- Pi packages: <https://pi.dev/packages>

These links are sources for **research and verification, not implicit permission to copy code or publish**. Inspect current code before applying a plan, verify the historical hashes if using this document later, and clearly distinguish verified source capabilities from aspirational requirements.

---

### One-sentence success criterion

**I can use one secure, locally rendered, model-token-efficient Pi extension in Kitty—with `pi-vim` undisturbed—to create every class of widget I previously needed `pi-openui` for and to run real interactive animations and simulations beyond the double pendulum; the project ships credible tests, documentation, a clean install/rollback path, and a maintenance plan I can actually follow.**
