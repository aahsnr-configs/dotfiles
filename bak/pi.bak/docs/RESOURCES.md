# Pi Coding Agent: community resources, extensions, skills, and personal configurations

**Research date:** November 7, 2026  
**Scope:** Pi Coding Agent ecosystem, excluding Oh My Pi

I found several substantial Pi-specific directories, individual extension collections, skills repositories, and public configurations from developers who have built their own Pi environments.

The most useful finding is that **Pi has an official package registry, multiple community-curated indexes, and public personal harnesses you can study without adopting an entire distribution.**

## 1. Best directories for discovering Pi resources

These are the sites I would bookmark first.

### 1. [Official Pi Package Catalog](https://pi.dev/packages)

The authoritative discovery source for packages containing extensions, skills, prompt templates, and themes. It exposes installation commands, package metadata, and resource manifests.

**Best for:** finding packages and verifying what they install.

### 2. [Pi Index](https://piindex.dev/)

A community-maintained directory of approximately 190 resources, organized into categories including MCP, subagents, permissions, persistent memory, code intelligence, and editor integrations.

**Best for:** targeted searches without sorting through thousands of results.

### 3. [Awesome Pi Coding Agent](https://awesome-pi.site/)

An automatically discovered, regularly updated index reporting over 16,000 resource entries, with more than 14,000 classified as extensions. It also indexes articles, tutorials, themes, and other projects.

This is a discovery database, not a hand-audited recommendation list; the counts should not be interpreted as unique, maintained, high-quality Pi plugins.

**Best for:** exhaustive discovery and finding obscure integrations.

### 4. [Piagent Resource Map](https://piagent.fyi/map/)

A smaller research-oriented catalog of 130 resources across functional categories, including session tooling, orchestration, security, debugging, context management, and extensions.

Also has a [29-resource curated shortlist](https://piagent.fyi/extensions/) with practical installation guidance.

**Best for:** a manageable shortlist with use-case guidance.

Two additional GitHub collections are particularly useful:

- [thevibeworks/awesome-pi-agent](https://github.com/thevibeworks/awesome-pi-agent) — Organized community list with dedicated sections for extension packs, skills, safety, memory, context, subagents, and personal dotfiles.
- [micuintus/pi-ecosystem-wiki](https://github.com/micuintus/pi-ecosystem-wiki) — A structured knowledge base comparing competing implementations, particularly useful when choosing between multiple subagent, compaction, or permission extensions.

The first list includes some alternate Pi distributions; I'm excluding those from the recommendations below.

## 2. Public personal Pi configurations worth studying

These repositories are particularly valuable because they show how developers actually organize their agents, rather than just providing isolated plugins.

| Configuration | What makes it interesting |
|---|---|
| [amosblomqvist/pi-config](https://github.com/amosblomqvist/pi-config) | Extensions for permission guards, browser automation, observational memory, interactive subagents, and context management. Explicitly designed for copying selected components. |
| [HazAT/pi-config](https://github.com/HazAT/pi-config) | Comprehensive personal setup with model configuration, skills, MCP settings, and a structured `/plan` → `/todos` → `/execute` → `/review` workflow. |
| [aliou/pi-harness](https://github.com/aliou/pi-harness) | Extensive custom multi-model harness with hooks, tools, commands, skills, tests, and a modular TypeScript project structure. |
| [rfgamaral/pi-config](https://github.com/rfgamaral/pi-config) | Personal harness with automatic session naming, handoffs, custom UI, coding workflows, memory, and extension packaging. |
| [abhinand5/pi-setup](https://github.com/abhinand5/pi-setup) | Git-tracked Pi setup with backup/restore, safety guards, diff review, token statistics, local model integration, and Catppuccin Mocha among its themes. |
| [Miskamyasa/pi-agent-config](https://github.com/Miskamyasa/pi-agent-config) | Custom subagents, project-specific model persistence, on-demand context loading, custom provider integration, and terminal UI modifications. |
| [abboskhonov/pi-dotfiles](https://github.com/abboskhonov/pi-dotfiles) | Small, straightforward example with `settings.json`, `models.json`, a custom theme, header, and agent-mode cycling. |
| [tmustier/vibes](https://github.com/tmustier/vibes) | Personal Pi setup with bundled extensions, skills, prompts, reusable libraries, and configuration profiles. |

My top three to study are **amosblomqvist**, **HazAT**, and **aliou**. They demonstrate three different approaches: selectively composing features, building a structured development workflow, and constructing a deeply customized harness.

For a smaller setup that's easier to understand from top to bottom, start with abboskhonov or Miskamyasa.

## 3. Collections of extensions and plugins

These are repositories containing multiple independently useful Pi extensions.

| Repository | Interesting components |
|---|---|
| [narumiruna/pi-extensions](https://github.com/narumiruna/pi-extensions) | Model-account switching, usage tracking, LSP, planning, automation, browser integrations, and status-line customization. Most packages are independently installable. |
| [kcosr/pi-extensions](https://github.com/kcosr/pi-extensions) | `toolwatch` for auditing and approving tool calls, `skill-picker`, `apply-patch-tool`, and a file browser. |
| [prateekmedia/pi-hooks](https://github.com/prateekmedia/pi-hooks) | Git checkpoints, rewind functionality, permission levels, LSP integration, and agent loops. |
| [mitsuhiko/agent-stuff](https://github.com/mitsuhiko/agent-stuff) | Armin Ronacher's personal extensions, prompt commands, skills, and themes, including programming and Git workflows. |
| [tmustier/pi-extensions](https://github.com/tmustier/pi-extensions) | Usage dashboard, session recap, code actions, file widgets, and iterative agent loops. The maintainer points to `tmustier/vibes` for his newer setup. |

These are verified public repositories, not a compatibility-tested combination.

## 4. Individual extensions to investigate

I've prioritized capabilities relevant to building a custom development and research agent.

| Capability | Extension | Purpose |
|---|---|---|
| Permissions | [pi-permission-system](https://github.com/MasuRii/pi-permission-system) | Centralized tool, shell, MCP, and agent-specific authorization. Particularly interesting for migrating OpenCode-style permission rules. |
| Code intelligence | [pi-lens](https://github.com/apmantza/pi-lens) | LSP diagnostics, linters, formatters, type-checking, structural searches, and symbol navigation. |
| Subagents | [pi-subagents](https://github.com/nicobailon/pi-subagents) | Delegation, parallel workers, isolated child contexts, and scripted multi-agent workflows. |
| MCP | [pi-mcp-adapter](https://github.com/nicobailon/pi-mcp-adapter) | Alternative MCP implementation with tool exposure and context-efficiency controls. |
| Web research | [pi-web-access](https://github.com/nicobailon/pi-web-access) | Web searches, content extraction, PDF extraction, GitHub access, and video processing. |
| Token optimization | [pi-rtk-optimizer](https://github.com/MasuRii/pi-rtk-optimizer) | RTK-based shell-command rewriting and tool-output compaction. |
| Scientific experimentation | [pi-autoresearch](https://github.com/nicobailon/pi-autoresearch) | Repeated experiment-and-evaluate workflows. |
| Code indexing | [pi-agent-scip](https://github.com/austinm911/pi-agent-scip) | SCIP-based semantic code intelligence. |
| Skills UX | [pi-skill-palette](https://github.com/nicobailon/pi-skill-palette) | Interactive palette for selecting skills. |
| Usage monitoring | [pi-sub](https://github.com/marckrenn/pi-sub) | Subscription and usage information in the terminal interface. |
| Isolation | [nono](https://github.com/nolabs-ai/nono) | OS-enforced runtime isolation using platform security mechanisms. |
| Emacs integration | [pilish](https://github.com/dnouri/pilish) | Emacs-oriented interface and agent workflow integration. |

One important warning about MCP: **current Pi already has native MCP support**. An extension such as `pi-mcp-adapter` can replace the built-in implementation rather than simply complement it. Consult the [official MCP documentation](https://pi.dev/docs/latest/mcp) before deciding whether an external adapter is necessary.

## 5. Pi-specific skills collections

I found a particularly relevant scientific skills port in addition to the general-purpose collections.

### [badlogic/pi-skills](https://github.com/badlogic/pi-skills)

Created by Pi's original author. Includes browser automation, Brave Search, Google Workspace command-line tools, speech transcription, VS Code integration, and YouTube transcripts. A good reference for relatively small, self-contained skills.

### [danieldoesbio/pi-scientific-skills](https://github.com/danieldoesbio/pi-scientific-skills)

A Pi-native distribution of K-Dense scientific Agent Skills covering bioinformatics, drug discovery, structural biology, physics, statistics, scientific writing, and research databases.

Particularly interesting is its `/sci` interface, which allows you to select scientific skill profiles rather than placing every skill description into the context. The README reports a larger skill count than the repository tagline, so check the actual package manifest for the current number.

### [PriNova/pi-agent-codebase-workflows](https://github.com/PriNova/pi-agent-codebase-workflows)

Skills and prompt templates for understanding unfamiliar repositories, architecture-aware reviews, and safer code modifications. Useful for Fedora, Bash, and software maintenance workflows.

### [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills)

The upstream scientific collection, with a dedicated [Pi Agent integration guide](https://github.com/K-Dense-AI/scientific-agent-skills/blob/main/docs/skill-guides/pi-agent.md). Useful for sourcing skills independently rather than adopting a complete science package.

For your scientific workflows, `pi-scientific-skills` is the most directly relevant collection I found. I would explore its profile-based discovery before deciding which parts to integrate.

## 6. Official documentation and learning resources

If you're developing your own agent, the official documentation is as important as the community packages.

| Resource | What to learn |
|---|---|
| [Extension API](https://pi.dev/docs/latest/extensions) | Hooks, tool registration, events, commands, custom UI, and lifecycle control |
| [Package system](https://pi.dev/docs/latest/packages) | Publishing and installing bundles, Git-based dependencies, and selective resource loading |
| [Agent Skills](https://pi.dev/docs/latest/skills) | `SKILL.md` structure, discovery, and progressive skill loading |
| [Settings reference](https://pi.dev/docs/latest/settings) | Global versus project settings and configurable resource paths |
| [Native MCP](https://pi.dev/docs/latest/mcp) | Connection management, Codemode, tool exposure, and authorization hooks |
| [Official extension examples](https://github.com/earendil-works/pi/tree/main/packages/coding-agent/examples) | Reference implementations to adapt into your own agent |

For community learning, [amosblomqvist's configuration](https://github.com/amosblomqvist/pi-config) also links to videos showing his setup after two and six months. These are useful alongside the source code.

## 7. How to install selected components without bloating Pi

Pi supports both temporary package testing and persistent installation.

```bash
# Inspect your current packages
pi list

# Try an extension for a single Pi invocation
pi -e npm:pi-lens

# Install a selected extension
pi install npm:pi-subagents

# Review and toggle loaded resources
pi config

# Update installed extension packages
pi update --extensions
```

The official package manager also supports **resource-level filtering**, so a collection can remain updateable while only selected extensions or skills are enabled. You can specify filters in `~/.pi/agent/settings.json` rather than copying files out of a repository.

For example, the `narumiruna/pi-extensions` repository documents how to install the collection and select just specific extension entrypoints. That's particularly useful for your goal of maintaining a custom harness without inheriting unnecessary features.

Security note: testing with `pi -e` avoids permanently adding a package to settings, but it **still executes its extension code**. It is not a sandbox. Review source code and dependencies before running untrusted packages, and avoid Git-tracking authentication or session-history files.

## 8. Where I would start for your custom agent

Based on the resources found, I would study these in this order rather than install everything:

1. **Architecture:** `aliou/pi-harness` and the official Pi extension examples. Learn how to construct your own modular harness.
2. **Workflow design:** `HazAT/pi-config` and `amosblomqvist/pi-config`. Compare orchestration, planning, approvals, and session memory.
3. **Permissions:** `pi-permission-system` and `kcosr/pi-extensions`. Evaluate policy enforcement and detailed tool-call audit logging.
4. **Development tools:** `pi-lens` and `pi-agent-scip`. Assess code intelligence before writing your own LSP or indexing integration.
5. **Scientific skills:** `pi-scientific-skills` and its K-Dense upstream. Select only the relevant scientific domains and verify actual computational tools independently.

My strongest recommendation is to use **the official Pi package registry for discovery, Pi Index for comparisons, and individual developers' GitHub repositories for implementation examples**. That combination will give you more control than starting with a preassembled extension stack, while still letting you reuse maintained community components.

The resources above are source-verified, but I have not installed or runtime-tested their combined compatibility.
