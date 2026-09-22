Here's the full drop-in package — four files, designed to work together. Comments explain the rationale for every non-obvious choice, per your usual preference.

## 1. `settings.json`

```jsonc
{
  // ============================================================
  // CORE: keyboard-only navigation and focus behavior
  // ============================================================

  // Explorer: keyboard-driven selection needs single-click-equivalent
  // behavior on Enter, not VS Code's preview-on-single-click default,
  // which requires a second action to actually open+pin a file.
  "workbench.list.openMode": "singleClick",

  // Keep the cursor away from the viewport edges. Without this, moving
  // down a long file scrolls the cursor to the very bottom line before
  // the viewport catches up — you lose visual tracking of where you are.
  "editor.cursorSurroundingLines": 8,
  "editor.cursorSurroundingLinesStyle": "all",

  // The title-bar "Command Center" (branch picker, search box) is a
  // mouse-first affordance layered over functionality the Command
  // Palette already exposes. Hiding it removes a dead-click target
  // and simplifies Tab-traversal of the title bar.
  "window.commandCenter": false,

  // Minimap is a mouse-click-to-scroll widget with no keyboard
  // equivalent use case for you — pure visual/mouse clutter.
  "editor.minimap.enabled": false,

  // ============================================================
  // EXPLORER / SIDEBAR: reduce mouse-oriented friction
  // ============================================================

  // Auto-reveal keeps the active file highlighted in the tree without
  // you needing to manually scroll-and-click to find it.
  "explorer.autoReveal": true,

  // Compact folder nesting (a/b/c collapsed to one row) means fewer
  // Down-arrow presses to traverse deeply nested folders.
  "explorer.compactFolders": true,

  // Confirm-on-delete via keyboard (Enter in a dialog) is fine, but
  // drag-and-drop confirmation is a mouse-only interaction path you'll
  // never trigger — turning it off removes a dialog you'd otherwise
  // have to Tab through by accident if a keybinding ever misfires.
  "explorer.confirmDragAndDrop": false,

  // ============================================================
  // EDITOR BEHAVIOR
  // ============================================================

  // Sticky scroll keeps enclosing function/class context pinned at
  // the top — useful since you're not mouse-hovering to peek context.
  "editor.stickyScroll.enabled": true,

  // Bracket pair guides help visually track scope without needing to
  // select-and-check via mouse.
  "editor.guides.bracketPairs": "active",

  // ============================================================
  // ACCESSIBILITY SIGNALS (audio/visual cues instead of glancing
  // at a mouse-hover tooltip)
  // ============================================================
  "accessibility.signals.lineHasError": { "sound": "auto" },
  "accessibility.signals.terminalCommandFailed": { "sound": "auto" },

  // ============================================================
  // VIM EMULATION LAYER (vscode-neovim)
  // ============================================================
  // Path to your real Neovim binary — vscode-neovim embeds this
  // instance rather than emulating Vim, so LSP/completion/snippets
  // stay native to VS Code while motions/modes come from real Neovim.
  "vscode-neovim.neovimExecutablePaths.linux": "/usr/bin/nvim",

  // Run VS Code's extension host for this extension on its own
  // thread — recommended in the extension docs to avoid input lag
  // between keypress and mode-switch.
  "extensions.experimental.affinity": {
    "asvetliakov.vscode-neovim": 1,
  },

  // jj to escape insert mode — matches common Vim muscle memory,
  // avoids reaching for a physical Escape key at all.
  "vscode-neovim.compositeKeys": {
    "jj": {
      "command": "vscode-neovim.escape",
    },
  },

  // ============================================================
  // VSPACECODE (leader-key / which-key layer)
  // ============================================================
  "vim.leader": "<space>",
  "vim.easymotion": true,
  "vim.useSystemClipboard": true,
  "vim.hlsearch": true,

  // Route the space leader key into VSpaceCode's menu instead of
  // treating it as a literal space character in normal/visual mode.
  "vim.normalModeKeyBindingsNonRecursive": [
    { "before": ["<space>"], "commands": ["vspacecode.space"] },
    {
      "before": [","],
      "commands": ["vspacecode.space"],
      "when": "editorTextFocus",
    },
  ],
  "vim.visualModeKeyBindingsNonRecursive": [
    { "before": ["<space>"], "commands": ["vspacecode.space"] },
  ],
}
```

## 2. `keybindings.json`

```jsonc
[
  // ============================================================
  // PANE / TERMINAL NAVIGATION — tmux-style directional jumps.
  // This is the single biggest quality-of-life fix for mouseless
  // VS Code: switching editor↔terminal↔split-groups by default
  // has no consistent keyboard path.
  // ============================================================
  {
    "key": "alt+h",
    "command": "workbench.action.focusLeftGroup",
  },
  {
    "key": "alt+l",
    "command": "workbench.action.focusRightGroup",
  },
  {
    "key": "alt+k",
    "command": "workbench.action.focusPreviousGroup",
    "when": "!terminalFocus",
  },
  {
    "key": "alt+j",
    "command": "workbench.action.terminal.focus",
    "when": "editorTextFocus",
  },
  {
    "key": "alt+k",
    "command": "workbench.action.focusActiveEditorGroup",
    "when": "terminalFocus",
  },

  // ============================================================
  // ESCAPE HATCHES — every mouse-only widget interaction
  // (context menus, hover tooltips) needs a keyboard trigger.
  // ============================================================
  {
    "key": "shift+f10",
    "command": "editor.action.showContextMenu",
    "when": "editorTextFocus",
  },
  {
    "key": "ctrl+k ctrl+i",
    "command": "editor.action.showHover",
    "when": "editorTextFocus",
  },

  // ============================================================
  // QUICK FOCUS JUMPS — move between major UI regions without
  // Tab-cycling through everything in between.
  // ============================================================
  {
    "key": "ctrl+0",
    "command": "workbench.action.focusSideBar",
  },
  {
    "key": "ctrl+1",
    "command": "workbench.action.focusFirstEditorGroup",
  },
  {
    "key": "ctrl+`",
    "command": "workbench.action.terminal.toggleTerminal",
  },

  // ============================================================
  // FILE EXPLORER — open/reveal without ever needing a click.
  // ============================================================
  {
    "key": "ctrl+shift+e",
    "command": "workbench.view.explorer",
  },
  {
    "key": "alt+r",
    "command": "workbench.files.action.showActiveFileInExplorer",
    "when": "editorTextFocus",
  },
]
```

## 3. `vspacecode.bindings.js` (leader menu)

Loosely mirrors Doom's `SPC f`/`SPC b`/`SPC w` grouping so the muscle memory transfers:

```js
module.exports = {
  title: "VSpaceCode: root",
  bindings: [
    {
      key: "f",
      name: "+file",
      type: "bindings",
      bindings: [
        {
          key: "f",
          name: "find file",
          type: "command",
          command: "workbench.action.quickOpen",
        },
        {
          key: "s",
          name: "save",
          type: "command",
          command: "workbench.action.files.save",
        },
        {
          key: "r",
          name: "recent",
          type: "command",
          command: "workbench.action.openRecent",
        },
      ],
    },
    {
      key: "b",
      name: "+buffer",
      type: "bindings",
      bindings: [
        {
          key: "b",
          name: "switch buffer",
          type: "command",
          command: "workbench.action.showAllEditors",
        },
        {
          key: "d",
          name: "kill buffer",
          type: "command",
          command: "workbench.action.closeActiveEditor",
        },
        {
          key: "n",
          name: "next buffer",
          type: "command",
          command: "workbench.action.nextEditor",
        },
        {
          key: "p",
          name: "previous buffer",
          type: "command",
          command: "workbench.action.previousEditor",
        },
      ],
    },
    {
      key: "w",
      name: "+window",
      type: "bindings",
      bindings: [
        {
          key: "v",
          name: "split right",
          type: "command",
          command: "workbench.action.splitEditorRight",
        },
        {
          key: "s",
          name: "split down",
          type: "command",
          command: "workbench.action.splitEditorDown",
        },
        {
          key: "d",
          name: "close group",
          type: "command",
          command: "workbench.action.closeEditorsInGroup",
        },
      ],
    },
    {
      key: "g",
      name: "+git",
      type: "bindings",
      bindings: [
        {
          key: "s",
          name: "status",
          type: "command",
          command: "workbench.view.scm",
        },
        { key: "c", name: "commit", type: "command", command: "git.commit" },
      ],
    },
    {
      key: "p",
      name: "+project/search",
      type: "bindings",
      bindings: [
        {
          key: "f",
          name: "find in files",
          type: "command",
          command: "workbench.action.findInFiles",
        },
        {
          key: "s",
          name: "search",
          type: "command",
          command: "workbench.view.search",
        },
      ],
    },
  ],
};
```

Point `vspacecode.bindingOverridesFile` in `settings.json` at this file's path once you've placed it — I've kept every entry mapped to a **built-in** VS Code command, so nothing here depends on an extension beyond VSCodeVim + VSpaceCode themselves.

## 4. `init.lua` guard for vscode-neovim

Since you're bringing your real Neovim config in:

```lua
-- Detect vscode-neovim host and skip anything that assumes a
-- full terminal Neovim environment (LSP servers, fuzzy-finders,
-- statusline plugins) — VS Code already owns those layers.
if vim.g.vscode then
  -- Only load motion/textobject/editing plugins here — e.g.
  -- targets.vim, vim-surround equivalents, treesitter textobjects
  -- if you use them for `dab`/`cip`-style motions.
  require("config.vscode-minimal")
else
  -- Your existing full Neovim config loads unchanged.
  require("config.full")
end
```

## Install order

1. Extensions: `asvetliakov.vscode-neovim`, `VSpaceCode.vspacecode`, `VSpaceCode.whichkey`
2. Drop in `settings.json` and `keybindings.json` above (merge with what you already have, don't overwrite)
3. Add the `vspacecode.bindings.js` file and point `vim.normalModeKeyBindingsNonRecursive`'s `vspacecode.space` at it via `vspacecode.bindingOverridesFile` in settings
4. Restart VS Code, run **"Neovim: Show output"** once to confirm the embedded instance connected to your `nvim` binary correctly before trusting it in daily use

Want me to also work out the `which-key`-style popup styling (font, delay before it appears, column count) to match how Doom's `which-key` looks, or is functional parity enough for now?
