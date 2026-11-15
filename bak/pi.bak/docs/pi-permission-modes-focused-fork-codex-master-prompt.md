# Master implementation prompt: a security-focused, session-only fork of `pi-permission-modes`

**Prepared:** 2026-11-15  
**Intended executors:** OpenAI Codex, a finished Pi Coding Agent installation, or a comparable interactive coding agent  
**Status:** **DESIGN REVIEW IN PROGRESS — D01–D10 APPROVED; D11–D54 PENDING — NOT AUTHORIZATION TO IMPLEMENT OR INSTALL**  
**Primary upstream:** https://github.com/wynainfo/pi-permission-modes  
**Optional UI-design reference:** https://github.com/felipeadeildo/pi-harness/tree/main/packages/ask-permission  
**Existing temporary safety systems:** `pi-permission-system` and `pi-sandbox`  
**User environment known so far:** Kitty terminal; Pi config is intended to remain in `~/.pi/agent`, **not managed by a flake or Home Manager**. Verify every other environmental detail instead of assuming it.

> **How to use this document:** Give the **entire contents**, starting at “BEGIN EXECUTOR PROMPT,” to Codex or Pi. The executor must **first inspect, research, ask the decisions in Section 4, and stop for explicit approval**. Suggested answers are recommendations, not approvals. Do **not** interpret the presence of this prompt as permission to change live configuration, disable either existing extension, or access secrets.
>
> **For the human owner:** Sections 4, 5, 10, and 13 are the main approval checkpoints. The executor should present decisions in manageable batches and accept replies such as `D01=B, D02=A ...`, with explanations for disagreements. The owner can revise decisions at any checkpoint.

---

# BEGIN EXECUTOR PROMPT

## Current owner-approved decision ledger (binding for this design review)

**Recorded 2026-11-15.** These are explicit owner decisions, not suggested defaults. **They authorize specification work only, not implementation, installation, sandbox changes, or migration.** They supersede the generic recommendations in the questionnaire below. The owner may revise them explicitly.

| ID | Approved | Binding meaning | Status / follow-on detail |
|---|---|---|---|
| **D01** | **C** | The normal option 4 is **full agent autonomy while retaining the OS sandbox**. A **separate emergency host-access override** may disable containment only after its own strong, explicit confirmation; it is **not** a fifth normal popup choice. | APPROVED; emergency-override details remain gated by D26, D27, D34 and later review. |
| **D02** | **A** | **None** of the four ordinary popup approvals may disable or bypass the OS sandbox. | APPROVED; consistent with D01=C. |
| **D03** | **B** | “Allow for this project” grants **low-risk in-project autonomy for the current session**, not arbitrary host access. | APPROVED; exact low-risk taxonomy and evaluation of actual accessed paths remain to be defined/tested. |
| **D04** | **A** | Dangerous or destructive operations require **separate, operation-specific confirmation**, even under project approval or full sandboxed autonomy; immutable hard denies stay denied. | APPROVED in principle; exact dangerous-operation categories/thresholds/exceptions need follow-on approval. |
| **D05** | **A** | “Always allow this command” is **exact-command matching**, not an executable-name wildcard or an AST-equivalent normalization. | APPROVED; match exact command bytes plus relevant execution context. |
| **D06** | **A** | Command grants do **not** cross security-relevant context changes: canonical project, resolved cwd, tool, effective mode, shell/user identity, material environment, or background execution. | APPROVED; design canonical fingerprints and tests before implementation. |
| **D07** | **A** | All four ordinary permissions and any associated authority expire with the **current Pi process/extension instance**; reload, process restart, crash, or exit clears grants. Resuming a conversation never restores them. | APPROVED; D42 must elaborate mode/session transitions without weakening this requirement. |
| **D08** | **A** | Subagents have **independent authority and permission gates**; no implicit inheritance of parent session, project, command, or autonomy approvals. | APPROVED; spawned processes and external agents must not be falsely assumed sandboxed. |
| **D09** | **A** | **Fail closed** if OS sandbox initialization or enforcement is absent, fails, or becomes uncertain. No fallback to unsandboxed execution or permission-UI-only checks. | APPROVED; separately initiated emergency host override under D01=C remains a different, strongly confirmed flow. |
| **D10** | **A** | **Strict hard denies** for reading credentials, key material, tokens, and sensitive `.env` files; **strict hard denies** for writing Git metadata (`.git` incl. worktree metadata), project `.pi` metadata, Pi config/state and protected secrets. Four ordinary popup choices cannot override them. | APPROVED; exact canonical path inventory and Git workflow exceptions to be considered later under D17–D18, never assumed allowed. |
| **D11–D54** | **PENDING** | Not yet decided. Never infer approval from the recommendations in Section 4. | Ask in manageable batches. |

**Recorded A2 approval:** On 2026-11-15 the owner explicitly replied `D07=A, D08=A, D09=A, D10=A` after approving D01–D06. This is **design authority only**; it does not authorize code, package installation, or live Pi configuration changes.

**Session-grant meaning:** D07=A is now binding: grants exist only in the current process/extension lifetime and are cleared on `/reload`, restart, crash, and exit. D42, still pending, must refine conversation-switch/fork/mode-reset behavior **without restoring grants**. **Subagents:** D08=A requires independent gates, not inherited approvals. **Sandbox failure:** D09=A forbids automatic fallback to host execution. **Hard-deny list:** D10=A makes sensitive reads and metadata/config writes non-overridable by the four ordinary options. **Emergency override limitation:** the separately confirmed D01=C override intentionally disables OS containment, so OS-enforced hard-deny protections are not guaranteed once it is active. Do not misrepresent this risk.

---

## 0. Your role, authority, and execution contract

You are the lead security architect, TypeScript engineer, Pi extension maintainer, terminal-UI designer, test engineer, and release engineer for a **focused fork of `wynainfo/pi-permission-modes`**.

Your job is to deliver, **only after owner-approved checkpoints**, a maintainable fork providing one modern, keyboard-friendly Kitty terminal permission popup with **four session-only approval choices**. Replace overlapping permissions and sandbox extensions **only after** independent validation, migration review, and final owner authorization.

### Non-negotiable behavioral instructions

1. **Ask, propose, await approval.** Do not turn defaults or recommended choices into silently approved decisions. For any security-relevant ambiguity, ask the owner; where execution must proceed without interaction, stop at a safe checkpoint and produce the proposal and question set, not a risky implementation.
2. **No live modifications during discovery.** Initial operations must be read-only, apart from creating agreed working documents in a new, isolated fork worktree once the owner approves its location. Do not edit `~/.pi/agent`, project-local `.pi` configuration, settings, install manifests, credentials, or shell initialization files until the specific migration gate is approved.
3. **Preserve the old guards during development.** `pi-permission-system` and `pi-sandbox` remain installed and active in the owner's normal Pi environment. Never stack a new sandbox-capable Bash wrapper alongside them in the same **test** Pi runtime. Use a separately validated isolated execution context for integration testing.
4. **No background promises.** Complete the active approved phase, then report findings, artifacts, tests, and the next required approval. Do not state that future work has been done.
5. **Never turn approval into automatic host escape.** An allowed tool call does not imply an unsandboxed Bash execution. Prevent the upstream approved-escape path from silently removing OS enforcement. Deny when a safe mechanism cannot fulfill the request.
6. **No persistent approval grants by default.** The four interactive options must expire at the approved session boundary. No session grants in `permission-mode.json`, project `.pi` files, Pi's session transcript, state snapshots, shared databases, or other durable stores unless the owner explicitly chooses otherwise—which would depart from the core requirement and must be identified as such.
7. **No extra model decisions.** No classifier/judge-model permission gateway, no per-command LLM analysis, and no model-initiated changes to approval stores. Use deterministic local logic and a local TUI; measure token impact instead of merely claiming it is zero.
8. **No configuration pinning of installed Pi extensions.** Do not require pinning installed extension package versions or git refs. You **may record the upstream baseline commit for audit** and use normal dependency lockfiles for the fork's development/release reproducibility; distinguish this clearly from pinning installed Pi extensions.
9. **Work with upstream, not against it.** Keep the fork a small, understandable delta. Retain viable upstream security fixes, architecture, tests, functionality, and licensing/attribution. Avoid copying the entire `pi-ask-permission` extension if only UI ideas or a small properly licensed module are needed.
10. **Never claim an OS sandbox covers the whole Pi process.** Bash subprocesses can be sandboxed; native file tools and other extensions running within Pi need their own enforcement path. Extensions themselves run with host-process privileges and are part of the trusted computing base.
11. **No secret exposure.** Never print, transmit, commit, test against, or copy real credentials, tokens, SSH keys, session data, personal files, or unrelated project content. Use synthetic fixtures. Avoid `cat`-ing secrets even in diagnostics.
12. **Fail closed** on uninitialized sandbox, missing mandatory sandbox dependencies, invalid configuration, unsupported backend, untrusted workspace, command parser uncertainty, lost UI, timeout, cancellation, crashed prompt controller, concurrent state change, or unrecognized policy outcome; report the reason and a safe recovery path.
13. **No changes on the owner's behalf without explicit consent** to network access, package installation, moving/removing packages, opening firewall or local ports, publishing releases, creating GitHub repos, writing configuration, or executing destructive tests.
14. **Honor approvals exactly.** A global `yes` to the project is not a yes to every security-sensitive design decision. Obtain phase-specific acceptance.
15. **Adversarially test the design.** Assertions and unit tests alone are insufficient for a sandbox replacement. Use real OS-backed subprocess tests and manual TUI review in Kitty before declaring readiness.

### Initial response format

Your first reply must contain: (a) verified environment and upstream facts, (b) discrepancies/risks relative to this document, (c) proposed phased implementation plan, (d) **Approval Batch A** from Section 4, and (e) the exact next gate. **Do not write implementation code or modify Pi configuration in that first reply.** If sources are unavailable, label them UNVERIFIED and do not invent an API or config key.

---

## 1. Goal and exact meaning of the four approval choices

The requested popup appears when a proposed operation is not automatically permitted under the active policy. It must be modern, legible, keyboard-first, compatible with Kitty, deterministic, and local-only.

The popup must expose exactly the following **four positive choices** (with an additional **Deny / Cancel** control, which is not counted as a positive approval):

| UI choice | Required conceptual semantics | Non-negotiable restriction |
|---|---|---|
| **1 — Allow once** | Authorize the specific pending operation one time, identified by call ID and validated call details | No grant beyond the current invocation; keep sandbox and hard denies |
| **2 — Allow for this project (session only)** | Create a temporary rule scoped to one canonical project root in this local session | No other projects, no permanent file writes; cannot override system-level hard denies; exact breadth requires owner decision |
| **3 — Always allow this command (session only)** | Reuse a grant for the same precise command and approved execution context for the remainder of this local session | Not a wildcard over an executable name; `git status` must not silently authorize `git push` |
| **4 — Full access for this session** | **APPROVED D01=C:** full *agent autonomy* for routine work **inside** the OS sandbox; dangerous operations and hard denies still apply | A **separate**, strongly confirmed emergency host-access override can disable containment; it is not a popup option |

### One critical ambiguity — DO NOT ASSUME

**“Full access” can mean either:**

- **Recommended: full *agent autonomy* within the configured sandbox**. It suppresses routine policy prompts, while hard-denied files, filesystem confinement, network policies, explicit privilege restrictions, and protected paths remain enforced.
- **High-risk: full *host execution* for the session**. This removes the sandbox and gives code the user's host permissions, comparable in impact to upstream YOLO.

These are fundamentally different security properties. **The owner approved D01=C:** implement normal option 4 as sandboxed autonomy, and design a separate high-risk emergency override with its own later approval. **Do not call sandboxed autonomy unrestricted host access.** Never let a normal command approval invoke the emergency override.

### Additional ambiguity — project-wide approval

“Allow for this project” may mean (i) allow a specific operation/pattern while the current project is active, (ii) allow all normally restricted project-local operations, or (iii) allow all project-local operations except dangerous classes. Present these choices in D03/D04. **Do not implement unrestricted project-wide tool execution based solely on the current working directory**: a command launched in the project can still read or write elsewhere.

### No silent privilege escalation from grants

The effective operation is allowed only if **all relevant constraints** permit it:

```
Authorized tool invocation
  = active session grant OR explicit current approval OR static policy allow
  AND no immutable hard deny
  AND acceptable risk class
  AND verified scope and live session identity
  AND OS sandbox can enforce the required execution constraints
```

A tool-level approval is **not** permission to change OS sandbox settings. No tool, generated code, agent message, or subagent can grant itself a session exception.

---

## 2. Read and verify the actual upstream code before designing changes

Consult these source documents **at the actual commit you inspect**, not only summaries:

1. Repository: https://github.com/wynainfo/pi-permission-modes
2. Architecture: https://github.com/wynainfo/pi-permission-modes/blob/main/docs/architecture.md
3. Security model: https://github.com/wynainfo/pi-permission-modes/blob/main/SECURITY.md
4. Configuration schema/docs: https://github.com/wynainfo/pi-permission-modes/blob/main/docs/configuration.md
5. Permissions: https://github.com/wynainfo/pi-permission-modes/blob/main/docs/permissions.md
6. Modes: https://github.com/wynainfo/pi-permission-modes/blob/main/docs/modes.md
7. Sandbox: https://github.com/wynainfo/pi-permission-modes/blob/main/docs/sandbox.md
8. Network: https://github.com/wynainfo/pi-permission-modes/blob/main/docs/network.md
9. Background shells: https://github.com/wynainfo/pi-permission-modes/blob/main/docs/shells.md
10. Contribution/test instructions: https://github.com/wynainfo/pi-permission-modes/blob/main/CONTRIBUTING.md
11. Pi extension API: https://pi.dev/docs/latest/extensions
12. Existing containment extension: https://github.com/carderne/pi-sandbox
13. Existing permission extension: https://pi.dev/packages/pi-permission-system
14. UI reference: https://github.com/felipeadeildo/pi-harness/tree/main/packages/ask-permission and https://github.com/felipeadeildo/pi-harness/blob/main/packages/ask-permission/docs/reference.md

**Baseline architectural clues (verify against checked-out source; these may evolve):**

- `src/index.ts` handles lifecycle, commands, `tool_call`, tool registration, prompt sections.
- `src/resolve.ts` resolves allow/ask/deny rules; `src/bash-parse.ts` analyzes Bash commands.
- `src/bash-enforce.ts` builds the Bash execution decision.
- `src/approvals.ts` owns session approval behavior; `src/modes.ts` owns mode/session state.
- `src/sandbox.ts` wraps Bash with `@anthropic-ai/sandbox-runtime`.
- `src/config-load.ts` merges stock, global, and tighten-only project configuration; it also has persistent grant paths.
- `src/network.ts` contains interactive domain grants and potentially persistent approvals.
- `src/paths.ts` canonicalizes paths and enforces native-tool protected paths.
- `src/status.ts`, `src/prompt-sections.ts`, `src/awareness.ts` affect TUI and token footprint.

**Known upstream risks to verify explicitly:** approved outside-project Bash escapes run unsandboxed; ordinary Bash session grants can be command-name-based rather than exact-command-based; some network/tool grants support “allow forever”; sandbox default read protections are based largely on `denyRead` rather than comprehensive outside-project read containment; normal native file tools are policy-gated rather than OS-sandboxed; modes and possibly grants may have session persistence behavior; network-open/YOLO/`--no-sandbox` paths bypass some boundaries; background shells and subagents have their own lifecycles. These facts affect the design, not just its UI.

**Deliver a source audit** with file:line references for every statement that matters to execution or security. Include an upstream behavior vs. desired behavior matrix and a list of source modules that must change. If upstream has changed, adapt the proposal and re-request the affected owner decisions.

---

## 3. Inventory the user's environment (read-only; sanitized output)

Collect and report, without revealing secrets:

- Operating system, distribution/version, kernel, CPU architecture, filesystem semantics, Nix/home-manager involvement **in installing Pi binaries**, and the currently running Pi version/API.
- Kitty version, terminal color capabilities, accessibility/keyboard constraints, whether TUI popup should be embedded or use Kitty-specific overlays, and any conflicting shortcuts.
- Locations and provenance of `pi` binary, `node`, package manager, sandbox runtime packages, `bwrap`/`sandbox-exec`, `rg`, `socat`, and user namespaces.
- Pi global configuration base, checking `PI_CODING_AGENT_DIR`; expected `~/.pi/agent`. Do not assume environmental overrides are absent.
- Current Pi settings: installed packages/extensions, discovery paths, order of competing handlers, keyboard bindings, `/perm` or `/sandbox` command conflicts, and project config trust behavior. **Sanitize values and do not print credentials or auth files**.
- Whether `pi-permission-system` and `pi-sandbox` are installed via npm, Git, local files, or configuration; their enabled states and configuration source paths.
- The existing sandbox-boundary test fixture (including `~/.pi`/`.git` protection, outside read/write and symlink behavior). **Only inspect it; never run destructive checks against real resources.**
- Expected number/type of subagents (the broader setup may contain multiple roles), background Bash tools, MCP/external tools, remote tools, user-entered `!` commands, and prompt/skill extensions.
- Existing Git tracking for Pi configuration, and desired Git location/remote for the fork. The fork's source repository should normally live **outside** `~/.pi/agent`; installing/loading it is a separate decision.
- Existing tests, linters, typecheck, CI, security policy, licenses, dependency audit warnings, and any open upstream issues relevant to permissions.

Do not require disabling existing guards to gather this information. If data cannot be obtained without risky access, ask the user to provide sanitized excerpts.

Produce `docs/environment-inventory.md` in the approved **new** fork worktree **only after** the owner approves the worktree location. Before then, show the inventory in chat.

---

## 4. OWNER APPROVAL QUESTIONNAIRE — mandatory decision register

**Rule:** Ask every applicable question. Provide A/B/C choices, recommended answer, exact security/maintenance consequence, and whether the choice is reversible. Mark each `PENDING`, `APPROVED`, `REJECTED`, or `NEEDS-DISCUSSION` in `docs/DECISIONS.md`. Do not conflate “the agent suggests A” with “the owner approved A”. Preserve exact replies and decision dates without copying sensitive content.

To reduce overload, ask the batches below **one at a time**. After each batch, summarize choices and consequences, then request an explicit `APPROVE BATCH ...` response. The owner may request a redesign. **Never start the next risky phase based on an unanswered default.**

### Approval Batch A — core security semantics (MUST approve before implementation)

| ID | Question and options | Recommended default; why |
|---|---|---|
| **D01** | What exactly does option 4 mean? **A:** full autonomy *inside* OS sandbox; **B:** full host access with sandbox off; **C:** provide both as separately confirmed modes | **A**, to preserve confinement |
| **D02** | Should any of the four positive choices ever authorize unsandboxed execution automatically? **A:** never; **B:** only a separate privileged, typed confirmation; **C:** allowed through option 4 | **A**, with optional separate emergency procedure requiring its own later design |
| **D03** | What does option 2 approve? **A:** only the original operation category/pattern within this project; **B:** all low-risk in-project operations; **C:** all project-local operations other than immutable hard denies | **B**, but require explicit risk taxonomy |
| **D04** | Which “dangerous even inside project” operations must remain blocked or require a separate confirmation despite project/full-autonomy grants? Choose from `rm -rf`, `git reset --hard`, `git clean`, force pushes, executable install scripts, privileged commands, filesystem permission changes, destructive DB commands, credential access, mass deletes, other | **Ask on dangerous/destructive actions**; list exact thresholds and exceptions |
| **D05** | Option 3 matching: **A:** exact raw command string + resolved cwd + project identity + execution mode + tool; **B:** normalized AST-equivalent representation; **C:** command name/argument pattern | **A**, least surprising and narrowest; never broad executable grants |
| **D06** | May a recognized exact command grant span different working directories, projects, environment variables, user/shell identities, interpolated placeholders, or background execution? Choose allowed dimensions | **No** across changed security-relevant context; conservative fingerprint |
| **D07 — APPROVED A** | Every ordinary approval expires at the current Pi process/extension boundary: reload, process exit, crash, and restart clear it; conversation resume does not restore it. | **Owner approved A (2026-11-15)**; D42 remains for finer lifecycle semantics. |
| **D08 — APPROVED A** | Subagents use independent permission scopes and gates; no automatic inheritance from a parent, including full autonomy. | **Owner approved A (2026-11-15)**. |
| **D09 — APPROVED A** | On sandbox initialization/enforcement failure or unsupported backend, block affected operations and never silently run them unsandboxed. The separate D01 emergency procedure is user-initiated, not a fallback. | **Owner approved A (2026-11-15)**. |
| **D10 — APPROVED A** | Hard-deny sensitive credential/key/token/`.env` reads and writes to `.git` metadata, project `.pi` metadata, Pi config/state and secrets in all four ordinary choices. Later decide named Git-workflow exceptions and enumerate exact canonical paths. | **Owner approved A (2026-11-15)**; ordinary UI approval cannot override hard denies. |
| **D11** | Outside-project reads: **A:** strict, verified OS-enforced read allowlist with only essential runtime dependencies; **B:** upstream broad reads except an explicit deny-list; **C:** selectable per trusted profile, never overriding D10 hard-denied secrets. | **A**; independently test runtime/toolchain compatibility. If OS-enforced confinement cannot be verified, deny rather than silently revert to B. |
| **D12** | Outside-project writes: **A:** always deny under four ordinary choices; **B:** permit a narrowly scoped, explicit, **sandbox-enforced** write exception only after an additional confirmation for one path/operation, expiring no later than D07; **C:** allow via unsandboxed host execution (conflicts with D02=A). | **A** for simplest secure default; B if the owner needs safe cross-project workflows and the OS backend can actually enforce it. **C conflicts with already-approved D02=A and requires reopening D02.** |
| **D13** | Can interactive/session grants loosen a **tighten-only project policy**? **A:** never; **B:** only with an independently confirmed, temporary exception that does not override immutable hard denies; **C:** always (conflicts with intended tightening). | **A**; a project-local restriction must remain a restriction despite option 2, 3, or 4. |
| **D14** | Network exceptions: **A:** dedicated destination/port/protocol prompt with only memory-scoped approval, not the ordinary four-choice command popup; **B:** integrated four-choice UI with **network-specific** explicit scope, no implicit wildcard domains and D07 expiry; **C:** option 4 bypasses network approval/filtering (unsafe and inconsistent with retained sandbox). | **A**; separate command authorization from network destination grants, retain filtering under option 4, do not approve wildcard hosts by accident. |
| **D15** | In sandboxed full autonomy, high-risk prompts/warnings for **dangerous commands, privilege escalation, out-of-project access, blocked destinations**, and **hard-denied resources**: **A:** keep mandatory confirmation for approvable high-risk actions, show denial for blocked resources (no override); **B:** suppress duplicate informational notices, but never suppress enforcement or a required high-risk confirmation; **C:** owner-specified per-category rules, never weaken D02/D04/D09/D10. | **A**; full autonomy is not full host trust. For hard-denied actions, report a denial rather than offering an approval. |

### Approval Batch B — filesystem, processes, networks, tools (MUST before code affecting execution)

| ID | Question and options | Recommended default; why |
|---|---|---|
| **D16** | What is the canonical project root: **A:** verified Git worktree top-level; **B:** starting cwd; **C:** explicitly selected directory? How should nested repos and worktrees behave? | **C** with Git root offered as a suggestion; never trust cwd alone |
| **D17** | Are `.git` writes (commits, checkout, branch, stash, index locks) allowed at all? **A:** protected and blocked; **B:** narrow separate Git workflow with explicit approval; **C:** broad Git metadata writes | **B** if Git automation is necessary; otherwise A; existing boundary fixture appears to expect protected `.git` |
| **D18** | Are project `.pi` files immutable? **A:** deny all writes; **B:** permit named config paths with separate approval; **C:** permit all within project | **A** for agent tool execution, matching security-focused config protections |
| **D19** | Which temp/scratch paths may be writable (`/tmp/pi`, per-session scratch, Nix store, caches, test dirs)? How are secrets and old scratch directories treated? | Per-session `0700` scratch, strict cleanup; no blanket `/tmp` or home writes |
| **D20** | Network defaults: allowlist/denylist, wildcard rules, DNS rebinding, localhost, local binding, raw sockets, proxy auth, proxy bypass, Git-over-SSH and SSH agent? | Narrow host/port allowlist, session-only exceptions, localhost denied unless needed |
| **D21** | User-entered `!` commands: sandbox them, bypass gate as explicit human commands, or prompt separately? | Sandbox by default; label human-initiated vs model-initiated distinctly |
| **D22** | Which tools are in scope: built-in Bash/file tools, `grep/find/ls`, background shells, MCP/server tools, skills, custom extension tools, web tools, subprocess spawners? Which are trusted bypasses? | Enumerate actual registered tools; unknown mutating tools **ask/deny**, never implicitly trusted |
| **D23** | How to handle `sudo`, `su`, `doas`, `pkexec`, setuid binaries, namespaces, ptrace, signals, Docker/Podman/SSH/remote execution, package scripts? | Deny privilege escalation and remote execution by default, except separately reviewed workflows |
| **D24** | Follow symlink, mount, inode/hardlink, renamed-path and TOCTOU threats: prefer strict denial over broad compatibility? | Yes; check realpath and containment at decision and execution; no false security claims for unsolved hardlink/races |
| **D25** | May project config files ever relax global rules? | **No**, maintain upstream tighten-only behavior; fail if ambiguous merge |
| **D26** | Can a user turn off the network filter via `/net open`, `Alt+N`, other commands or config? **A:** remove/lock for protected modes; **B:** leave but add high-risk confirmation; **C:** unchanged upstream | **A**, or B only under explicitly approved break-glass policy |
| **D27** | What to do with upstream `YOLO`, `--no-sandbox`, `sandbox.enabled:false`, `bypassProtectedPaths`, and privileged escape paths? **A:** disable/reject within protected fork; **B:** retain behind two-step unlock; **C:** unchanged | **A** for default product; B only if explicit owner sign-off and security test |
| **D28** | Background shells and long-lived dev servers: allow, restrict, or turn off by default? What happens on revoke, mode switch, reload, timeout, shutdown? | Allow only in explicit sandboxed mode; revoke/cancel outstanding work and avoid inheriting removed grants |
| **D29** | Do you need browser/headless/Playwright/Chromium/Docker local workflows requiring nested namespaces, loopback ports, or weakened runtime options? | Strict by default; add named per-project opt-in only after tests |
| **D30** | What should happen in noninteractive Pi/CI/subagents/no TTY/remote UI: **A:** deny new privileged requests; **B:** use preapproved narrow static policies; **C:** automatically allow? | **A**, with B permitted for audited static CI rules; never C |

### Approval Batch C — UI, exact popup language, interaction (MUST before UI implementation)

| ID | Question and options | Recommended default; why |
|---|---|---|
| **D31** | UI technology: **A:** Pi's built-in TUI `ctx.ui.custom()` (Kitty-compatible); **B:** external Kitty-specific popup; **C:** hybrid | **A**, fewer dependencies, headless fallback, no external IPC control plane |
| **D32** | Visual style: **A:** compact IDE-style dark panel; **B:** colorful dashboard; **C:** neutral/native Pi styling. Specify accent colors, width, spacing, borders, and compact mode | **A** with restrained contrast and themes; no hard-coded terminal assumptions |
| **D33** | Keymap: **A:** `1/2/3/4` select; `Y` allows once; `Enter` confirms highlighted; `Esc/N` denies; **B:** custom keys. Note all four cannot share unqualified `Y` | **A**, with no inadvertent option-4 selection via a single key |
| **D34** | Require extra typed confirmation for option 4? **A:** yes (`ENABLE SESSION AUTONOMY` or selected phrase); **B:** one confirmation; **C:** none | **A**, especially if option 4 has elevated authority |
| **D35** | Prompt placement: top editor overlay vs modal vs above-editor nonmodal panel; should it defer while user types or another dialog owns focus? | Non-destructive, focus-aware UI; do not overwrite drafts or steal an active modal's input |
| **D36** | Detail view: full untruncated command, cwd, resolved project, tool name, modified paths, network domains, duration, mode and protection badges; what is collapsed? | Show risk-relevant essentials; provide expandable full command with scroll/copy; never hide destructive suffixes |
| **D37** | Do users need arrow-key navigation, Vim-style `j/k`, mouse, screen readers, reduced motion, ASCII fallback and 8/16-color terminals? | Yes for arrows; Vim keys optional; accessible contrast and no required animation |
| **D38** | Prompt timeout/queueing: timeout length, queue vs parallel, max queued, cancellation, signal behavior, deadlock prevention? | Default deny on timeout, serialized ownership and FIFO with cancellation; no stale approvals |
| **D39** | Status/footer: show mode, OS sandbox ready/failed, network filtering state, project root, grant count, time remaining, and risk/warning; how noisy? | Short persistent status; drill-down via `/perm status` |
| **D40** | Should user be able to add denial reason/annotation to tool result? Should it be sent to model? | Optional short denial reason; never send hidden policy internals or private paths gratuitously |
| **D41** | Which existing shortcuts/commands must remain intact, and how to resolve `Alt+M`, `Alt+N`, `Alt+S`, `/perm`, `/sandbox` collisions? | Audit installed extensions before assigning; never silently override conflicting commands |

### Approval Batch D — persistence, configuration, token budget, repository design (MUST before rollout)

| ID | Question and options | Recommended default; why |
|---|---|---|
| **D42** | Session approvals on `/reload`, Pi conversation switch, resume, fork, process restart and crash: clear vs retain? | **Clear on all** by default; mode should reset to conservative startup; no stale grant replay |
| **D43** | In-memory rule revocation: `/perm reset`, revoke single grant, revoke all, manual downgrade, shutdown, project change; should running background shells be killed? | Expose revoke/status; kill or suspend affected background commands when enforceable; document unavoidable already-run effects |
| **D44** | Default mode at Pi startup: prompt-based Default, Plan (read-focused), Build, or full-autonomy? | **Default** with sandbox available and explicit status, never YOLO |
| **D45** | Preserve upstream Default/Plan/Build modes, plan approval, network management, background shells? Customize vs remove? | Retain compatible features but make them subordinate to new session-only security invariants |
| **D46** | Prompt token budget: always inject a small sandbox awareness block, inject only on changes, or expose only a command the model may query? Specify acceptable extra baseline tokens | Prefer minimal changed-state only; permission checks purely local; measure exact token delta |
| **D47** | Logging/audit: terminal-only, memory-only log, locally persisted redacted audit log, or opt-in? What identifiers/paths may appear? | Memory-only operational trace by default; opt-in sanitized diagnostics; never persist approval grants |
| **D48** | Fork repo directory, Git host/remote, private/public, license, package name, command namespace, release tags, and primary maintainer? | New independent repo, preserve MIT attribution, unique package and command names; **ask for exact paths** |
| **D49** | Distribution: local Pi extension path, npm package, Git-based Pi install, or both? Auto-update policy and verification? | Local/dev first, then approved Git/npm distribution; no installed Pi extension pinning |
| **D50** | Upstream strategy: minimal patch series/rebase vs long-lived reimplementation; contribution upstream first? | Minimal patch series tracking upstream; propose PRs for generally useful hardening |
| **D51** | Dependency and build governance: allow network during `npm install`, package scripts, SCA audit, signed releases, CI environment, SBOM? | Require review before installs/network/scripts; lock dev dependencies; CI tests + audit + attribution |
| **D52** | Supported platforms: only owner's current OS or Linux+macOS+Windows? Separate best-effort from guaranteed security behavior | Guarantee only tested target platform; deny unsupported rather than promising equivalence |
| **D53** | Test inventory and performance budget: max startup latency, Bash overhead, TUI latency, allowed memory increase, expected Pi API versions? | Establish baseline and set measured thresholds with the owner |
| **D54** | Final migration authority: who authorizes disabling/removing existing guards, changing `settings.json`, registering global extension paths and cleanup? | **The owner, explicitly, at last gate** |

### Approval protocol to use verbatim

At each batch, produce:

```text
APPROVAL BATCH [A/B/C/D] — NO CHANGES MADE

Verified facts that affect these decisions:
- ...

For each Dxx:
- Choice A / B / C ...
- My recommendation: [choice]
- Security effect: [...]
- Maintenance/UX effect: [...]
- Needs explicit owner response: YES

Reply using D01=A, D02=A, ... and then:
APPROVE BATCH [A/B/C/D]
Or reply CHANGE Dxx: ... to request a revised proposal.
```

If the owner replies to only some questions, mark the others pending and **ask only the missing/unclear items**, rather than silently applying defaults or restarting the entire form. If the owner changes an earlier decision, identify invalidated downstream designs/tests and re-approve only those dependent items.

**The existence of this questionnaire does not itself authorize answers.**

---

## 5. Proposed architecture — draft, subject to owner approval

Implement **one permission engine, one sandbox runtime/controller, and one TUI approval controller**. Avoid installing `ask-permission` as a second active gate. Consult it only for UI design patterns/license-compliant reuse.

### 5.1 Reference module separation

Prefer adding small, testable modules rather than massive rewrites:

```text
src/
  session-authority.ts       # lifecycle identity, zero durable grants
  grant-types.ts            # type-safe grants and scopes
  approval-store.ts         # in-memory operation/project/exact-command grants
  operation-fingerprint.ts  # strict command+context matching
  risk-classifier.ts        # deterministic guardrails; never sole containment
  approval-dialog.ts        # one Kitty-friendly Pi TUI with 4 positive options + Deny
  approval-queue.ts         # FIFO, timeouts, cancellation, focus safety
  policy-coordinator.ts     # compose global/project rules, hard denies, grants
  execution-plan.ts         # sandbox required, constrained, or denied; no implicit host escape
  sandbox-adapter.ts        # narrow interface to upstream SandboxController
  diagnostics.ts            # safe redacted status/errors
  ... retain relevant upstream modules ...
```

Names are suggestions. The source audit may justify modifying existing files instead; preserve the architecture's pure-core approach and Pi SDK separation.

### 5.2 Explicit decision pipeline

1. Capture immutable, typed tool-call parameters, originating agent, actual cwd/project and session epoch.
2. Determine whether request is native Pi file tool, Bash, skill, network request, MCP/custom tool, user Bash, or background shell.
3. Resolve **immutable denies first**, then project tighten-only rules, policy rules, current-session grants and risk exceptions. Deny always wins.
4. For commands, parse using upstream AST as one source of risk information; **never trust the parser as the only OS-enforced containment boundary**. Unknown shell structures must not broaden privileges.
5. Ensure a valid sandbox can enforce the intended tool execution. If not, **deny** in protected modes; do not silently offer unsandboxed execution.
6. If a prompt is required, acquire one UI request owner, show precise impact, and ask 1–4 or Deny. Bind the answer to the unchanged request fingerprint and current session epoch. On mismatch, cancel and re-evaluate.
7. If a session grant was selected, store it **only in process memory**; do not write it to session entries or configuration.
8. Execute **sandboxed Bash** using one verified wrapper. For explicit narrowly scoped out-of-project access, either extend the sandbox for that call using a fully tested capability **or deny** with instructions. **No approved Bash escape may automatically use the host executor.**
9. Native file tools run inside Pi's process: perform canonical path checks, enforce denies and project boundaries, validate at the actual operation interface, and document that this is *not* a kernel sandbox. Do not weaken or drop upstream protected-path backstop.
10. Return precise, minimal result; clear one-time grants and transient buffers; keep a redacted, opt-in audit trail if approved.

### 5.3 Session authority and grant data model

Suggested grant record shape (design illustration, not an accepted API):

```ts
interface SessionGrant {
  kind: "once" | "project" | "exact-command" | "full-autonomy";
  ownerSessionEpoch: string;       // random process-lifetime in-memory identifier
  originAgentId: string;          // independent by default for subagents
  projectRootRealpath: string;
  toolId?: string;
  operationFingerprint?: string;
  commandLiteral?: string;
  cwdRealpath?: string;
  environmentClass?: string;
  riskLimit?: string[];
  issuedAtMonotonic?: number;
  expiresAtMonotonic?: number;
}
```

Refine for minimal storage/zero leakage. Never serialize this record into agent-visible conversation history. Show session grants in human-readable `/perm grants` / `/perm status` UI **without giving the model a privileged API to mutate them**. If an existing `request_network_access` tool remains, it must be **request-only**, not approval-capable.

Grant matching must use exact tool/context values and consider command string, resolved cwd, project root, effective mode, execution type, and risk class. Avoid executable-prefix matches, regex/glob-based session grants, wildcard environment inheritance, or parser-based claims of semantic equivalence. Handle normalized line endings, terminal control sequences, Unicode, NUL bytes, quoted arguments, path changes, and secret-containing commands safely and explicitly.

### 5.4 What session-only means

Unless owner decision D07/D42 says otherwise:

- A new Pi process starts with **zero grants**.
- `/reload` starts a new extension-instance epoch and **clears grants**.
- Resume/fork/switch conversation does **not** replay grants from the session file.
- Each subagent has its own independent authority.
- Project-root change or tool-context change invalidates relevant grants.
- `/perm reset` revokes all grants at once; `/perm revoke <id>` revokes one grant.
- Pending prompts are canceled on shutdown, reload, mode change, switch, timeout, signal or session invalidation.
- Never persist grants through `pi.appendEntry`, local JSON, global JSON, project JSON, history, exported shell variables, or IPC shared storage.
- A process with an already-running background shell needs a separately approved policy for what revocation means; do not falsely claim immediate rollback of already-executed effects.

### 5.5 Immutable sandbox boundary

For normal modes, apply at least the owner's approved invariant set:

- Sandbox initialized, healthy, and explicitly shown as **ACTIVE** before Bash can run.
- Default project writable root only; narrow per-session scratch; denied `.git` and `.pi` paths as approved; no broad home write.
- Secrets explicitly unreadable at OS boundary wherever supported, including Pi auth and environment credentials. Strict-home mode should be assessed to prevent outside-project reads that evade Bash heuristics.
- Network filter remains active; host/port/domain exceptions have separate approval semantics and cannot become silent unrestricted network access.
- Privilege escalation, container/namespace escapes, signal abuse, local sockets, nested sandboxing and background process inheritance are modeled explicitly.
- No downgrade to unsandboxed execution when AST parse fails, runtime fails, prompt is approved, or owner changes modes.
- Verify whether existing command-line flags or mode definitions can override the protection; disable or clearly isolate escape hatches by approved design.
- Treat `PI_CODING_AGENT_DIR`, `.pi` files and extension package directories as **sensitive infrastructure**, not ordinary project files.
- Existing extensions and Pi host process are trusted code; explicitly state that hostile extensions/MCP bridges can undermine policy if allowed to run with host privileges.

---

## 6. Exact UI behavior and user-facing prompt text

Create wireframes or a local test harness **before** implementing a live permission hook. Present at least three alternatives (compact, detailed, high-risk) and obtain owner approval of the chosen visual layout. All text is subject to approval; use concise, consistent spelling and no misleading “full access” claim.

### 6.1 Suggested visual (not yet approved)

```text
┌─ PI PERMISSION REQUEST ─────────────────────────────────────────┐
│ bash · ~/Projects/example · sandbox: ACTIVE · network: FILTERED │
│ Risk: ordinary command                                          │
│                                                                 │
│ $ pnpm test                                                      │
│                                                                 │
│ [1] Yes — allow once                                            │
│ [2] Allow for this project — this session only                  │
│ [3] Always allow THIS EXACT command — this session only        │
│ [4] Full agent autonomy — this session only (sandbox stays ON)  │
│                                                                 │
│ [Esc/N] Deny   [Tab] Details   [↑↓] Select   [Enter] Confirm   │
└─────────────────────────────────────────────────────────────────┘
```

**Key rule:** `Y` must only approve the **currently explicitly selected** choice if that behavior is approved. It must never instantly enable option 4. Numeric keys 1–4 are distinct. If option 4 is high risk, show a second, explicit confirmation.

### 6.2 Popup strings to implement and test

The UI/test suite must cover the following exact **semantic states**; owner can edit final copy:

1. **Routine operation:** `Permission required` / `[tool] requests [operation]` / `Sandbox remains active`.
2. **Allow once:** `Approve this invocation only. This does not grant future permission.`
3. **Project grant:** `Allow eligible operations under [canonical project root] until this session ends. Hard denies and network limits stay active.`
4. **Exact-command grant:** `Allow this exact command in this execution context until this session ends. Different commands or projects still ask.`
5. **Full autonomy:** `Skip routine confirmations until this session ends. The OS sandbox and permanent restrictions remain active.` (Only if D01=A/C's sandboxed mode.)
6. **Unsandboxed emergency mode** (only if explicitly added): `DANGER: commands may access your account outside the sandbox. Type the required phrase to continue.` This cannot be the unqualified default for choice 4.
7. **Deny:** `Denied by user. Do not retry by rephrasing the same prohibited operation.` Optional reason only if entered.
8. **Permanent hard deny:** `Blocked by immutable security policy: [redacted reason]. Interactive approval cannot override this restriction.`
9. **Outside project:** `This operation targets [redacted/confirmed path] outside the approved project. Approval does not imply host-level execution.`
10. **Network exception:** `Connection to [host:port] was blocked. Allow this destination for the session?` Must distinguish host policy from command execution authorization.
11. **Unavailable sandbox:** `Execution blocked: sandbox could not be established. No unsandboxed fallback was used.`
12. **Headless:** `Execution denied because an interactive approval was required and no trusted approval UI is available.`
13. **Timeout:** `Permission request expired. No action was authorized.`
14. **Cancellation:** `Permission request cancelled. No action was authorized.`
15. **Session revoked:** `Session permission rules cleared. New restricted operations will require approval.`
16. **Mode downgrade:** `Full autonomy ended. Normal confirmation rules restored.`
17. **Concurrent request:** `Permission request queued [n]; no approval will be reused across requests.`
18. **Mismatch during prompt:** `Operation changed while waiting; previous approval is invalid. Please review the new request.`
19. **Background-shell continuation:** `A running background process may continue under its existing sandbox; review/stop it before changing access.` (Adapt to implemented policy.)
20. **Persistent-choice removal:** The interactive UI must not offer `Allow forever`, `all projects forever`, `Save to project config`, or equivalent durable grants unless the owner separately authorizes these (which would violate the core four-session-only design).

### 6.3 Usability and integrity

- Scroll long commands and paths, reveal entire string on demand, highlight differing arguments and escaped control characters, show effective cwd, current sandbox/profile and project root.
- Do not truncate security-significant content to 80 characters in the final review UI, even if the compact preview truncates.
- Keyboard focus must remain correct when editor is being typed into or another overlay is open; restore the user's draft, cursor, and selection after prompt closure.
- Support standard Kitty terminal escape handling without letting raw command output inject interactive key sequences into the approval UI.
- Theme-compatible in both dark and light configurations; fallback for reduced color/unicode; no animation that interferes with typing.
- Human approvals require explicit operator input; tool output or model-generated text must never be parsed as a UI approval event.
- Never issue a second prompt for the same decision because of two competing extension handlers.
- UI and approval engine must have separate tests so a visual refactor cannot change permission semantics.

---

## 7. Config and compatibility contract

Design and propose a **minimal, versioned fork configuration schema**, with owner approval before writing it. The source of truth should remain one global authority plus a tighten-only project overlay. Do not assume the current upstream JSON schema already includes fork keys.

### Recommended config behavior

- Global config in Pi's active agent directory, normally `~/.pi/agent/permission-mode/permission-mode.json`, or a **separate clearly named fork namespace** if needed to avoid conflicts. Owner chooses path, namespace, and migration style.
- Project config may only **tighten**, never add allow roots, enable sandbox bypass, weaken hard denies, enable network-open, alter prompts/system instructions, or auto-approve dangerous tools.
- `sessionOnly: true` (or similar approved name) as a hard feature invariant; static policy configuration is persistent *policy*, not a persistent record of interactive approvals. Explain that distinction.
- Invalid or unrecognized keys result in a clear safe error; never silently strip a security-setting typo and continue with a weaker mode.
- The four options should be fixed to approved semantics. Expose only safe customization—labels/keybindings/visible details—without enabling project config to relax policy.
- Preserve upstream behavior for unrelated features only after a risk review: Plan mode, `show_plan`, background shells, tool/skill surfaces, network proxy, system prompt awareness and status indicators.
- Remove `Allow forever` paths from interactive approvals and ensure no durable approvals are created by request tools, network prompts, mode switches or hidden flags.
- Handle existing upstream config files without silently promoting their old persistent session/global grants. Provide a validation warning and conversion report. Keep original backups private and unchanged until migration approval.
- Respect `PI_CODING_AGENT_DIR` as supported by the installed Pi version; do not hard-code home paths in the implementation if the SDK exposes the canonical agent directory.
- Preserve the owner's default `~/.pi/agent` installation and their decision not to manage the config with Home Manager/flake.

For every proposed new key, deliver: name, type, default, trust boundary, possible unsafe value, project-overlay behavior, schema validation, unit tests, migration, documentation and whether it changes prompt tokens.

---

## 8. Test plan — must pass before proposing replacement

Tests need positive and negative cases. They must execute in a **synthetic fixture with synthetic secrets**, not the user's home secrets. For each test, record expected/observed, platform, sandbox backend, tool entry point, grant selection and whether the restriction was OS-enforced or only policy-enforced.

### 8.1 Unit tests

- Exact call fingerprint matching: identical command+context allowed; changes in args, quoting, redirects, shell, cwd, project, env class, background flag or tool identity do not inherit grant.
- Session store: grant/lookup/revoke, one-time consumption, process epoch separation, nested prompts, concurrency, terminal quit, reload, resume, fork, changed project, subagent separation.
- Rule ordering: immutable denies > tighten-only project policy > static policy > session grant; deny wins deterministically.
- Path handling: `realpath`, traversal, symlink, dangling symlink, relative `..`, Git worktrees, alternative path syntax, spaces, Unicode, hardlink limitations, parent directory access.
- Parser adversaries: `sh -c`, `bash -c`, `eval`, `env`, `xargs`, function calls, command substitution, process substitution, brace/glob expansion, variable-built paths, pipelines, redirects, heredocs, arrays, multi-line commands, aliases and wrapper binaries. **The parser may miss some; OS sandbox must still enforce resources.**
- Profile composition, deny-list/allow-list priority, domain wildcard/port validation, malicious project config, mode switch and no sandbox fallback.
- UI: keyboard selection, `Y` semantics, `Esc/N` deny, typed confirmation, focus ownership, draft preservation, timeouts, cancellation, screen-resize, queued prompts and no accidental grants.
- “Allow once” cannot be replayed; “allow project” never crosses project; “exact command” never generalizes; “full autonomy” cannot disable sandbox.
- No permission grant is serialized in config, Pi session JSON or extension state stores; sanitized logs contain no secret values.

### 8.2 Real isolation and boundary fixtures

Create or reuse a **copied, synthetic equivalent** of the existing Pi boundary fixture. Tests must verify:

1. Allowed in-project `read`, `write`, `edit` and Bash read/write work.
2. Outside-project **read** denied according to owner-approved strictness, including data accessed through a generated script, indirect commands, symlinks and variables where possible.
3. Outside-project **write** denied, including redirection, append, symlink traversal, subprocess and background command.
4. Synthetic `~/.ssh`, auth, credential files and designated sensitive paths remain unreadable (test only synthetic copies inside test HOME).
5. `.git`/`.pi` metadata writes blocked according to approved policy; ordinary project files still writable.
6. Symlink and canonical-path differences do not let direct file tools or Bash exceed allowed roots; document any hardlink/mount alias caveats honestly.
7. Network to explicitly allowed host works in a test network environment; denied host/port fails; live host prompt adds **session-only** access only.
8. `sudo`, namespace, signals, local socket access, metadata endpoints, DNS rebinding and container/remote execution restrictions are tested where applicable.
9. `pnpm test`, `npm install`, Git status/log, language compiler, Nix-related toolchain paths (if applicable) work within deliberate constraints; request narrow exceptions rather than broadening home or network by default.
10. Session option 1–4 matrix under all applicable modes; test command and file tools separately.
11. A changed/canceled request cannot execute with a prior pending approval; timeouts always deny.
12. An unavailable or crashed sandbox blocks instead of running unsandboxed.
13. No prompt duplication or tooling conflict with the temporary production guards **because testing runs in isolation**, not by piling wrappers into the same Pi runtime.
14. A running/background process receives correct wrapper enforcement and is handled correctly on grant revocation/session shutdown.
15. A subagent without transferred authority cannot inherit parent grants or silently run unsandboxed.
16. Toggling upstream `/net open`, YOLO, `--no-sandbox` or modes cannot bypass the owner's agreed protection, or is explicitly listed as an approved break-glass exception.
17. Behavior under Kitty keyboard handling, terminal resize and panel focus stays correct.
18. Direct Pi file tools are not wrongly described as kernel-confined; test their policy checks and revalidation.

### 8.3 Mandatory regression workflow

- Run upstream `npm test` and `npm run typecheck` unmodified before changes; save baseline.
- Add focused tests for every new invariant and every bug fixed.
- Run full unit/integration suites after each approved phase.
- Run dependency audit, typecheck, lint/format, package/build smoke tests and appropriate CI jobs.
- Compare results against **a separately run original `pi-sandbox` fixture** and **an upstream `pi-permission-modes` baseline**. Report any security regression, even if normal workflows become faster.
- Require a real terminal demonstration reviewed by the owner; mock UI snapshots are insufficient.
- Do not proceed to production migration while critical failures, unknown sandbox behavior, or unresolved severe bypasses remain.

### 8.4 Performance and token efficiency

Measure and report with reproducible methodology:

- Extra LLM calls made by the fork for approval: target **zero**.
- Extra startup/prompt/context tokens vs current Pi and upstream; report actual figures on a sample session and identify injected prompt sections.
- Latency overhead for allowed Bash/file tools and prompted approvals.
- Memory and CPU for idle session, repeated requests, concurrent prompts and background shells.
- Changed tool output size; avoid gratuitous logs or injecting large policy descriptions into every model turn.
- Do not sacrifice enforcement for token savings.

---

## 9. Implementation plan, stage gates, and deliverables

### Gate 0 — discovery and decisions (NO code changes)

1. Read actual upstream code/docs, local Pi API and current guards.
2. Produce source audit, threat-model delta, environment inventory and proposed module map in chat.
3. Ask Approval Batches A–D in small interactions.
4. Write a **decision summary** and request explicit approval of the proposed fork repo location and implementation start.

**STOP. Required owner response:** `APPROVE GATE 0 — proceed with isolated fork development`.

### Gate 1 — isolated fork and baseline

Only after Gate 0 approval:

1. Establish an owner-approved new fork directory and Git repository, preserving license/attribution and the upstream remote. Record the **audit baseline commit SHA**, without pinning installed extensions.
2. Inspect package scripts/dependencies; seek network/package-install permission before running them.
3. Reproduce existing upstream tests and typecheck; capture baseline.
4. Create a clean test runner that loads only the fork using verified Pi CLI discovery semantics. **Do not assume `--no-extensions -e` combines in a particular way; check `pi --help` and the current docs.** Do not load overlapping wrappers in the same process.
5. Write `docs/DECISIONS.md`, `docs/THREAT_MODEL.md`, `docs/ARCHITECTURE.md` and the baseline test report.

**STOP. Required owner response:** `APPROVE GATE 1 — implement permission engine`.

### Gate 2 — permission and sandbox security core

- Implement process-lifetime authority store and exact command fingerprints.
- Refactor decision pipeline and prevent implicit unsandboxed execution for approved escapes; deny if safe scoped access cannot be enforced.
- Implement immutable denies, strict boundary behavior selected by owner, project tighten-only configuration and network session-only grants.
- Enforce fallback failure modes and subagent/background semantics.
- Add unit and OS-level boundary tests.

**STOP with test report and decisions requiring revision.**  
**Required response:** `APPROVE GATE 2 — implement terminal UI`.

### Gate 3 — modern Kitty TUI

- Present visual wireframes and exact wording for final owner selection.
- Implement one four-choice approval UI, high-risk confirmations, queueing, focus safety, status/footer and accessibility.
- Run keyboard, no-UI, cancellation, concurrency and snapshot tests; demonstrate in actual Kitty where available.
- Preserve consistency with current mode and sandbox state.

**STOP. Required response:** `APPROVE GATE 3 — run full independent acceptance tests`.

### Gate 4 — acceptance and source maintenance review

- Run the complete test matrix, upstream regression tests, OS sandbox probes, safety fixture and performance/token benchmarks.
- Document all limitations and accepted residual risks.
- Provide upstream diff size, modules changed, dependency changes, test coverage, attribution and release plan.
- Fix critical gaps before asking to migrate.

**STOP. Required response:** `APPROVE GATE 4 — prepare migration proposal only`.

### Gate 5 — migration plan (no live cutover yet)

- Inventory exact live extension install entries and settings changes that would be needed.
- Prepare an atomic, minimally invasive change plan; do **not** delete any old package/config or secrets.
- Produce backup/rollback procedure with exact file list, expected hashes, and instructions for restoring original guards.
- Validate launch in a separate shell and synthetic workspace.
- Explain precisely which installed extension/package entries will be disabled after cutover and which stay available for rollback.

**STOP. Required response:** `APPROVE GATE 5 — perform controlled live cutover`.

### Gate 6 — user-authorized cutover and rollback drill

Only after explicit approval:

1. Make narrowly approved changes to `~/.pi/agent` settings or approved extension loader entry. Do not touch auth files.
2. Deactivate old `pi-permission-system` and `pi-sandbox` only for the final production configuration, not by deleting their backups.
3. Ensure **exactly one active permission gate and one OS sandbox controller** for Bash in the final Pi process.
4. Verify normal read/build flows, hard-deny attempts, all four choices, restart/reload revocation, network filtering, subagent isolation and Kitty popup.
5. Offer a tested rollback restoring old extension entries and original settings without leaving partial installs.
6. Only after final owner acceptance, discuss whether to uninstall old packages; do not automatically uninstall them.

**Final required response:** `ACCEPT FINAL CUTOVER` or `ROLL BACK`.

### Required repository outputs

- `README.md`: install, exact semantics of 1–4, caveats, commands, troubleshooting.
- `docs/DECISIONS.md`: every approved/pending decision with rationale and dependencies.
- `docs/THREAT_MODEL.md`: trust boundaries, OS vs policy enforcement, explicit residual risks.
- `docs/ARCHITECTURE.md`: diagrams, policy resolution, sandbox lifecycle, prompt flow.
- `docs/PERMISSIONS.md`: one-time/project/command/autonomy behavior and denial precedence.
- `docs/UI_SPEC.md`: screen states, keys, wording, focus and accessibility.
- `docs/CONFIGURATION.md`: schema keys, tighten-only behavior and safe migration.
- `docs/TEST_PLAN.md`: all matrix cases, real OS backend expectations and limitations.
- `docs/SECURITY_TEST_RESULTS.md`: actual observed results and environment.
- `docs/TOKEN_BUDGET.md`: local/no-LLM permission decisions and measured prompt overhead.
- `docs/UPSTREAM_MAINTENANCE.md`: syncing, release, security fixes and divergence budget.
- `docs/MIGRATION_AND_ROLLBACK.md`: exact controlled cutover and rollback commands, **filled in only after environment verification**.
- `CHANGELOG.md`, attribution/license, schema, automated tests, CI configuration and optional development fixtures.

---

## 10. Security review questions to force before final acceptance

After implementation, explicitly ask the owner to approve or reject each of these statements, with evidence and test references:

```text
S01. I approve the meaning of “full access for session” implemented by choice 4.
S02. I understand the difference between a policy prompt and OS-level isolation.
S03. I approve the canonical project-root semantics and project-grant breadth.
S04. I approve the exact-command fingerprint and contextual matching rules.
S05. I approve the default hard-deny filesystem and credential list.
S06. I approve the design for .git and .pi metadata write protection.
S07. I approve outside-project read/write behavior and any deliberate exceptions.
S08. I approve network allowlists, live prompts, localhost and local binding policy.
S09. I approve the treatment of sudo, process signals, containers, and remote tools.
S10. I approve subagent and background shell access and revocation semantics.
S11. I approve process-session expiry across reload, resume, fork, and new sessions.
S12. I approve fallback behavior when sandbox or interactive UI is unavailable.
S13. I approve which tools and extensions are covered, and accept documented limits.
S14. I approve the exact four-option TUI text, keymap, keyboard focus, and visuals.
S15. I approve the no-persistent-grant rule and absence of allow-forever paths.
S16. I approve the no-extra-LLM-calls requirement and measured token overhead.
S17. I approve package dependencies, licenses, update workflow, and platform support.
S18. I have reviewed actual independent OS-level security test results.
S19. I have reviewed known residual risks, not merely successful test counts.
S20. I approve the migration/rollback plan; this alone does NOT authorize cutover.
```

Every `Sxx` must be `APPROVED`, `REJECTED`, or `NOT APPLICABLE (reason)` before Gate 5. For rejected items, redesign and rerun dependent tests; do not quietly waive a requirement. If the owner chooses a security-weakening behavior, document explicit informed consent and do not mislabel it as equally secure.

---

## 11. Maintenance, upstream sync, and long-term safety

The fork is not finished at “the popup works.” Deliver a realistic upkeep strategy:

- Choose a clear repo/package identity distinct from upstream; preserve upstream attribution and MIT license where applicable; review license implications of any UI code borrowed from `pi-harness`.
- Maintain `upstream` Git remote and small, reviewable commits grouped by: permission core, sandbox no-escape, session lifecycle, UI, tests, docs.
- Record baseline SHA for audit; **do not pin installed Pi extension installations**. Describe how to update on demand with explicit review rather than silently adopting upstream changes.
- Monitor upstream `SECURITY.md`, releases, changes to sandbox runtime, Pi extension SDK, TUI API, `tool_call` interception and `registerTool` overrides.
- Periodically merge/rebase upstream security fixes after checking impact on all four grant semantics; never overwrite custom hardening accidentally.
- Re-run security fixtures after each upstream merge, Pi upgrade, runtime upgrade or dependency update. Keep a documented minimum supported Pi version and backend matrix.
- Separate trusted global configuration from untrusted project overlay; defend against schema/config migrations that accidentally widen access.
- Include dependency audit, build supply-chain review, test/release CI, signed tag or provenance strategy if chosen, and rollback of a bad release.
- If shipping package install scripts, review their necessity and permissions. No telemetry or remote policy service unless separately approved.
- Write a runbook for a maintainer: common failures, exact local debug commands, parser limitations, sandbox unavailable, network prompt deadlock, background process leaks and rollback.
- Track token budget and performance over releases; avoid prompt bloat and unnecessary tool schemas or agent-visible internals.
- Publish a concise **upstream divergence register**: reason for fork, key patches, associated tests, likelihood of merge conflict, owner-maintenance effort, and candidates for upstream contribution.
- State the honest limits: hostile Pi extensions with host privileges are outside the OS sandbox; native file tools depend on policy enforcement; Linux/macOS backends may differ; hardlinks and OS/macOS case sensitivity can matter; no sandbox makes untrusted arbitrary code perfectly safe.

---

## 12. Acceptance criteria — strict pass/fail

Do **not** claim the fork is ready unless ALL of the following are true:

- [ ] The owner explicitly approved D01–D54 or marked items N/A with rationale.
- [ ] The four approval choices have exactly the approved semantics and a Deny action.
- [ ] Every approval is current-session-only, with no hidden “forever” pathways.
- [ ] Option 3 matches the agreed exact command/context, not only executable name.
- [ ] Option 2 is strictly project-root scoped and cannot authorize outside-project execution merely because cwd is inside it.
- [ ] Option 4 matches the owner's approved full-autonomy/full-host definition and warning design.
- [ ] No normal approval path silently executes Bash outside the OS sandbox.
- [ ] No sandbox unavailable/crash/parse failure silently reduces to host execution.
- [ ] Critical filesystem, credential, network and metadata fixture restrictions pass on the target platform.
- [ ] Native file tool protections, scope and limitations are actually verified.
- [ ] Concurrent prompts, session expiry, reload, subagents and background shells behave as approved.
- [ ] Keyboard UI works in actual Kitty, with full details and safe focus handling.
- [ ] No extra model calls for permission adjudication; measured prompt/token cost reported.
- [ ] Full upstream regression/typecheck and new security tests pass.
- [ ] Migration and rollback documented, reviewed and rehearsed in isolation.
- [ ] No live config changed before Gate 5 explicit cutover approval.
- [ ] The owner approves the final independent security review.

If an item cannot pass because of upstream or platform architecture, report **NOT ACHIEVED**, the remaining risk and safest fallback; do not relabel it as a pass. The correct outcome can be “retain `pi-sandbox` and do not migrate.”

---

## 13. Final interaction requirements and kickoff request

**Start now with discovery, not coding.** Inspect available sources/environment within authorized read-only scope. Respond in this exact structure:

```text
A. VERIFIED BASELINE
- Pi and Kitty environment; unknowns clearly marked
- Existing guard extensions, sandbox backend and any collisions
- Actual upstream modules / behavior with file-and-line evidence

B. SECURITY DISCREPANCIES
- Every path where upstream can run unsandboxed
- Every persistence pathway for approvals
- Every native-tool / Bash / network / subagent coverage gap

C. PROPOSED IMPLEMENTATION
- Minimal source changes and architecture
- Test harness / fixture / migration isolation
- Token budget and upstream maintenance plan

D. APPROVAL BATCH A (ONLY UNRESOLVED ITEMS)
- Honor already-approved D01–D10; first ask D11–D15, with recommendation and consequence
- Accept partial answers; do not fill in blanks silently

E. STOP STATUS
- No live Pi configuration has changed
- No existing guard has been removed or disabled
- Next action requires: APPROVE BATCH A
```

After approval of Batch A, ask Batch B, then C, then D. If the owner wants fewer questions per turn, break the current batch into 4–7-item sub-batches. Do not ask the owner to approve 54 items in one huge UI form. Always present a concise decision summary before each approval gate and explicitly state what will happen **after** approval.

**Do not proceed from “I received the prompt” to installing the fork. Do not self-approve. Do not trade away the sandbox for convenience.**

# END EXECUTOR PROMPT

---

## Appendix: source verification notes for the human owner

These are starting references as of **15 November 2026**; the executor must still inspect current checked-out source code:

- `pi-permission-modes` architecture documents the `tool_call` decision path, per-call sandbox wrapper and an approved escape that runs unsandboxed: https://github.com/wynainfo/pi-permission-modes/blob/main/docs/architecture.md
- Permission docs describe Bash AST-based policy gating, command-name session grants and the sandbox/escape table: https://github.com/wynainfo/pi-permission-modes/blob/main/docs/permissions.md
- Security model describes OS-boundary limitations, broad out-of-project Bash reads except denied secrets, unsandboxed approved escapes, file tools and subagent considerations: https://github.com/wynainfo/pi-permission-modes/blob/main/SECURITY.md
- Configuration docs describe stock/global/tighten-only project layers: https://github.com/wynainfo/pi-permission-modes/blob/main/docs/configuration.md
- Network docs describe session/forever host approvals and network-open controls: https://github.com/wynainfo/pi-permission-modes/blob/main/docs/network.md
- Upstream tests and local dev commands: https://github.com/wynainfo/pi-permission-modes/blob/main/CONTRIBUTING.md
- `pi-sandbox` source describes the separate runtime, default prompts and project/global persistent options: https://github.com/carderne/pi-sandbox
- Pi extension API warns that extensions run inside the Pi host process with the same OS privileges: https://pi.dev/docs/latest/extensions
- `pi-ask-permission` provides UI design inspiration, not a drop-in shared sandbox policy engine: https://github.com/felipeadeildo/pi-harness/tree/main/packages/ask-permission

**Next pending decisions:** D11–D15 (outside-project reads/writes, project-tightening precedence, network approval, high-risk prompts). Afterward ask D16–D18 (`.git`/`.pi` and project root), D31–D34 (popup design and keys), and D48–D49 (fork location and installation approach). D01–D10 are already approved; **do not re-ask them unless the owner explicitly reopens them or verified upstream behavior creates a conflict.**
