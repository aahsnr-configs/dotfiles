> **Audit note (August 2026):** This guide was reviewed and corrected before republishing. The one substantive fix: the grammar/spell-check extension `valentjn.vscode-ltex` ("LTeX") is no longer maintained — its author archived the repository in April 2026. The actively maintained continuation is **LTeX+** (`ltex-plus.vscode-ltex-plus`), a drop-in successor that keeps the same `ltex.*` settings. All instructions below have been updated to install LTeX+ instead. Separately, `tecosaur.latex-utilities` ("LaTeX Utilities") has been unmaintained for some time and isn't officially supported by the LaTeX Workshop team — it's flagged as optional with that caveat rather than removed, since its paste-image and formatted-paste features still work for most people. Everything else in the original guide — extension IDs, settings keys, package names, and installer commands — checked out against current sources and is left as-is.

Yes. The most reliable way to make VS Code a fully-fledged LaTeX editor is:

> **TeX Live/MiKTeX + `latexmk` + LaTeX Workshop + LaTeX Utilities (optional, unmaintained) + LTeX+ + Image Preview + Error Lens**

This gives you:

- Build-on-save
- Internal PDF preview inside VS Code
- SyncTeX forward/inverse search
- Citation/reference/label autocomplete
- LaTeX formatting via `latexindent`
- Linting via `chktex`
- Grammar/spell checking via LTeX+
- Image thumbnails for `\includegraphics`
- Math previews for `$...$`, `\[...\]`, equations, etc.
- Clean auxiliary files
- Multi-file root/sub-file support
- Error/warning inline display

The one caveat: VS Code will not become a true WYSIWYG editor like TeXstudio or LyX, but with LaTeX Workshop’s math preview/hover and the internal PDF viewer, you can get a very strong “inline preview” workflow.

---

## 1. Install a real LaTeX distribution first

VS Code is only the editor. You still need LaTeX itself.

### Ubuntu/Debian

Recommended full setup:

```bash
sudo apt update
sudo apt install -y \
  texlive-full \
  latexmk \
  latexindent \
  chktex \
  texcount \
  biber \
  perl
```

If `texlive-full` is too large:

```bash
sudo apt install -y \
  texlive-latex-extra \
  texlive-fonts-recommended \
  texlive-fonts-extra \
  texlive-lang-all \
  texlive-bibtex-extra \
  texlive-science \
  texlive-latex-recommended \
  latexmk \
  latexindent \
  chktex \
  texcount \
  biber \
  perl
```

### macOS

Use MacTeX:

```bash
brew install --cask mactex-no-gui
```

Then install/update useful tools:

```bash
sudo tlmgr update --self --all
sudo tlmgr install latexmk latexindent chktex texcount biber
```

You may need to ensure `/Library/TeX/texbin` is in your `PATH`.

### Windows

Either install TeX Live or MiKTeX. MiKTeX is often easiest:

```powershell
winget install MiKTeX.MiKTeX
```

Then open **MiKTeX Console** and install:

- `latexmk`
- `latexindent`
- `chktex`
- `texcount`
- `biber`
- `cm-super`
- `lm`
- `ec`
- `epstopdf`
- `collection-fontsrecommended`

After installing, restart VS Code completely.

---

## 2. Verify LaTeX is visible to VS Code

Open a terminal inside VS Code and run:

```bash
latexmk --version
pdflatex --version
xelatex --version
lualatex --version
biber --version
latexindent --version
chktex --version
texcount --version
```

If any of these fail, fix your `PATH` before continuing.

Typical paths:

### Linux

Usually `/usr/bin` or `/usr/local/bin`.

For TeX Live manual installs, it may be something like:

```bash
/usr/local/texlive/2025/bin/x86_64-linux
```

### macOS

```bash
/Library/TeX/texbin
```

### Windows/MiKTeX

Often:

```text
%LOCALAPPDATA%\Programs\MiKTeX\miktex\bin\x64
```

---

## 3. Install the VS Code extensions

From a terminal:

```bash
code --install-extension James-Yu.latex-workshop
code --install-extension tecosaur.latex-utilities
code --install-extension ltex-plus.vscode-ltex-plus
code --install-extension streetsidesoftware.code-spell-checker
code --install-extension kisstkondoros.vscode-gutter-preview
code --install-extension usernamehw.errorlens
```

What each one does:

| Extension                               | Purpose                                                                                     |
| --------------------------------------- | ------------------------------------------------------------------------------------------- |
| `James-Yu.latex-workshop`               | Main LaTeX IDE: build, PDF view, SyncTeX, completion, math preview                          |
| `tecosaur.latex-utilities`              | Extra LaTeX QoL: paste image, word count, formatting helpers — unmaintained, see note below |
| `ltex-plus.vscode-ltex-plus`            | Grammar/spelling with LanguageTool ("LTeX+")                                                |
| `streetsidesoftware.code-spell-checker` | Lightweight spell checker                                                                   |
| `kisstkondoros.vscode-gutter-preview`   | Inline/gutter image previews for `\includegraphics`                                         |
| `usernamehw.errorlens`                  | Shows errors/warnings inline in the editor                                                  |

> **Note on LTeX+:** the extension used to be published as `valentjn.vscode-ltex` ("LTeX"). That original was archived by its author in April 2026 and is no longer updated. `ltex-plus.vscode-ltex-plus` ("LTeX+") is the actively maintained continuation, published by a new team, and it keeps the same `ltex.*` configuration keys — so every setting later in this guide works unchanged. Search the Marketplace for "LTeX+" and make sure the publisher is `ltex-plus`, not the old one.

> **Note on LaTeX Utilities:** its own changelog announces it as "no longer maintained," and LaTeX Workshop's FAQ lists it as unsupported. Its paste-image and formatted-paste commands still work for most people, so it's left in as optional — just don't expect fixes if something breaks. The word-count and math-preview features described later come from LaTeX Workshop itself, not this extension.

Optional but nice:

```bash
code --install-extension eamodio.gitlens
code --install-extension Gruntfuggly.todo-tree
code --install-extension aaron-bond.better-comments
```

If you use both LTeX+ and Code Spell Checker, you may get duplicate spelling diagnostics. You can either:

- use LTeX+ only, or
- keep Code Spell Checker only for fast spelling and disable LTeX+ spelling, or
- tune LTeX+ severity.

For most people, **LTeX+ alone is enough**.

---

## 4. Create a workspace settings file

Inside your LaTeX project, create:

```text
.vscode/settings.json
```

Use the following as a strong default.

This is written as VS Code JSONC, so comments are allowed in VS Code.

```jsonc
{
  // --------------------------------------------------
  // General editor quality of life
  // --------------------------------------------------
  "files.associations": {
    "*.tex": "latex",
    "*.sty": "latex",
    "*.cls": "latex",
    "*.bib": "bibtex",
    "*.bst": "bibtex",
  },

  "files.encoding": "utf8",
  "files.insertFinalNewline": true,
  "files.trimTrailingWhitespace": true,
  "files.trimFinalNewlines": true,

  // Avoid watching/build noise from LaTeX auxiliary files
  "files.watcherExclude": {
    "**/*.aux": true,
    "**/*.log": true,
    "**/*.out": true,
    "**/*.toc": true,
    "**/*.lof": true,
    "**/*.lot": true,
    "**/*.fls": true,
    "**/*.fdb_latexmk": true,
    "**/*.synctex.gz": true,
    "**/*.bbl": true,
    "**/*.blg": true,
    "**/*.bcf": true,
    "**/*.run.xml": true,
  },

  "search.exclude": {
    "**/*.aux": true,
    "**/*.log": true,
    "**/*.out": true,
    "**/*.toc": true,
    "**/*.lof": true,
    "**/*.lot": true,
    "**/*.fls": true,
    "**/*.fdb_latexmk": true,
    "**/*.synctex.gz": true,
    "**/*.bbl": true,
    "**/*.blg": true,
    "**/*.bcf": true,
    "**/*.run.xml": true,
  },

  "editor.wordWrap": "on",
  "editor.formatOnSave": true,
  "editor.snippetSuggestions": "top",
  "editor.suggest.snippetsPreventQuickSuggestions": false,

  "[latex]": {
    "editor.tabSize": 2,
    "editor.defaultFormatter": "James-Yu.latex-workshop",
    "editor.quickSuggestions": {
      "other": true,
      "comments": false,
      "strings": true,
    },
  },

  "[bibtex]": {
    "editor.tabSize": 2,
    "editor.wordWrap": "on",
  },

  // --------------------------------------------------
  // LaTeX Workshop core behavior
  // --------------------------------------------------
  "latex-workshop.latex.autoBuild.run": "onSave",
  "latex-workshop.latex.recipe.default": "lastUsed",
  "latex-workshop.latex.build.forceRecipeTermination": true,

  // Keep output next to source by default.
  // If you prefer build/ directory, change this carefully.
  "latex-workshop.latex.outDir": "%DIR%",

  "latex-workshop.latex.autoClean.run": "onFailed",
  "latex-workshop.latex.clean.fileTypes": [
    "*.aux",
    "*.bbl",
    "*.blg",
    "*.idx",
    "*.ind",
    "*.lof",
    "*.lot",
    "*.out",
    "*.toc",
    "*.acn",
    "*.acr",
    "*.alg",
    "*.glg",
    "*.glo",
    "*.gls",
    "*.fls",
    "*.log",
    "*.fdb_latexmk",
    "*.snm",
    "*.nav",
    "*.dvi",
    "*.run.xml",
    "*.bcf",
    "*.synctex.gz",
  ],

  "latex-workshop.latex.magic.enabled": true,

  // --------------------------------------------------
  // Inline/internal PDF preview
  // --------------------------------------------------
  "latex-workshop.view.pdf.viewer": "tab",
  "latex-workshop.view.pdf.internal.synctex.keybinding": "double-click",
  "latex-workshop.synctex.afterBuild.enabled": true,

  // --------------------------------------------------
  // Hover and math preview
  // --------------------------------------------------
  "latex-workshop.hover.preview.enabled": true,
  "latex-workshop.hover.preview.mathjax.enabled": true,
  "latex-workshop.hover.command.enabled": true,

  // --------------------------------------------------
  // IntelliSense / autocomplete
  // --------------------------------------------------
  "latex-workshop.intellisense.package.enabled": true,
  "latex-workshop.intellisense.citation.enabled": true,
  "latex-workshop.intellisense.label.enabled": true,

  // --------------------------------------------------
  // Messages
  // --------------------------------------------------
  "latex-workshop.message.error.show": true,
  "latex-workshop.message.warning.show": false,

  // --------------------------------------------------
  // Formatting with latexindent
  // --------------------------------------------------
  "latex-workshop.latexindent.enabled": true,
  "latex-workshop.latexindent.path": "latexindent",

  // --------------------------------------------------
  // Linting with chktex
  // --------------------------------------------------
  "latex-workshop.linting.chktex.enabled": true,

  // --------------------------------------------------
  // Build tools
  // --------------------------------------------------
  "latex-workshop.latex.tools": [
    {
      "name": "latexmk-pdf",
      "command": "latexmk",
      "args": [
        "-synctex=1",
        "-interaction=nonstopmode",
        "-file-line-error",
        "-pdf",
        "-outdir=%OUTDIR%",
        "%DOC%",
      ],
      "env": {},
    },
    {
      "name": "latexmk-xelatex",
      "command": "latexmk",
      "args": [
        "-synctex=1",
        "-interaction=nonstopmode",
        "-file-line-error",
        "-xelatex",
        "-outdir=%OUTDIR%",
        "%DOC%",
      ],
      "env": {},
    },
    {
      "name": "latexmk-lualatex",
      "command": "latexmk",
      "args": [
        "-synctex=1",
        "-interaction=nonstopmode",
        "-file-line-error",
        "-lualatex",
        "-outdir=%OUTDIR%",
        "%DOC%",
      ],
      "env": {},
    },
    {
      "name": "pdflatex",
      "command": "pdflatex",
      "args": [
        "-synctex=1",
        "-interaction=nonstopmode",
        "-file-line-error",
        "%DOC%",
      ],
      "env": {},
    },
    {
      "name": "xelatex",
      "command": "xelatex",
      "args": [
        "-synctex=1",
        "-interaction=nonstopmode",
        "-file-line-error",
        "%DOC%",
      ],
      "env": {},
    },
    {
      "name": "lualatex",
      "command": "lualatex",
      "args": [
        "-synctex=1",
        "-interaction=nonstopmode",
        "-file-line-error",
        "%DOC%",
      ],
      "env": {},
    },
    {
      "name": "biber",
      "command": "biber",
      "args": ["%DOCFILE%"],
      "env": {},
    },
    {
      "name": "bibtex",
      "command": "bibtex",
      "args": ["%DOCFILE%"],
      "env": {},
    },
  ],

  // --------------------------------------------------
  // Recipes
  // --------------------------------------------------
  "latex-workshop.latex.recipes": [
    {
      "name": "latexmk pdflatex",
      "tools": ["latexmk-pdf"],
    },
    {
      "name": "latexmk xelatex",
      "tools": ["latexmk-xelatex"],
    },
    {
      "name": "latexmk lualatex",
      "tools": ["latexmk-lualatex"],
    },
    {
      "name": "pdflatex -> bibtex -> pdflatex x2",
      "tools": ["pdflatex", "bibtex", "pdflatex", "pdflatex"],
    },
    {
      "name": "xelatex -> biber -> xelatex x2",
      "tools": ["xelatex", "biber", "xelatex", "xelatex"],
    },
  ],

  // --------------------------------------------------
  // LTeX+ grammar/spelling (settings keys are still "ltex.*")
  // --------------------------------------------------
  "ltex.language": "en-US",
  "ltex.checkFrequency": "save",
  "ltex.diagnosticSeverity": "information",
}
```

---

## 5. Enable inline previews

There are three kinds of “inline preview” people usually mean.

---

### A. Inline/internal PDF preview inside VS Code

This is the most important one.

LaTeX Workshop can open the compiled PDF inside a VS Code tab.

The settings above already enable this:

```json
"latex-workshop.view.pdf.viewer": "tab"
```

To use it:

1. Open your `.tex` file.
2. Save the file.
3. Run:

```text
Ctrl/Cmd + Shift + P
LaTeX Workshop: View LaTeX PDF file
```

Default shortcut is often:

```text
Ctrl + Alt + V
```

or on macOS:

```text
Cmd + Option + V
```

You can split the editor:

```text
Ctrl/Cmd + \
```

Then place the `.tex` file on the left and PDF preview on the right.

Now you get near-live inline document preview without leaving VS Code.

---

### B. Forward and inverse SyncTeX

With SyncTeX, you can jump between source and PDF.

#### Forward search: source to PDF

Put your cursor in LaTeX source and run:

```text
Ctrl/Cmd + Shift + P
LaTeX Workshop: SyncTeX from cursor
```

Default shortcut is often:

```text
Ctrl + Alt + J
```

#### Inverse search: PDF to source

With the internal PDF viewer:

- Double-click the PDF, or
- Use the configured keybinding from:

```json
"latex-workshop.view.pdf.internal.synctex.keybinding": "double-click"
```

You can also change it to `ctrl-click` if preferred.

Make sure your build includes:

```bash
-synctex=1
```

The recipes above already include it.

---

### C. Inline math previews

LaTeX Workshop provides math preview/hover support.

The important settings from above are:

```json
"latex-workshop.hover.preview.enabled": true,
"latex-workshop.hover.preview.mathjax.enabled": true
```

In recent LaTeX Workshop versions, you can also use the command palette:

```text
Ctrl/Cmd + Shift + P
LaTeX Workshop: Open math preview
```

or search for:

```text
LaTeX Workshop math preview
```

Depending on your version, you may see commands named:

- `Open math preview`
- `Toggle math preview`
- `Preview math formula`
- `Show math preview`

To test it, create a file with:

```latex
\documentclass{article}
\usepackage{amsmath}

\begin{document}

Inline math: $E = mc^2$.

Display math:
\[
  \int_0^1 x^2 \, dx = \frac{1}{3}
\]

Equation environment:
\begin{equation}
  \nabla \cdot \mathbf{E} = \frac{\rho}{\varepsilon_0}
\end{equation}

\end{document}
```

Build it. Then hover over the math or place your cursor inside the math environment and invoke the math preview command.

You should see a rendered version of the formula.

This is not identical to true inline WYSIWYG rendering, but it is the best maintained VS Code workflow.

If math preview does not appear:

1. Update LaTeX Workshop.
2. Reload VS Code.
3. Build the document once.
4. Ensure your network/proxy is not blocking MathJax assets if applicable.
5. Search VS Code settings for `math preview` and enable every relevant LaTeX Workshop option.

---

### D. Image previews for `\includegraphics`

Install:

```bash
code --install-extension kisstkondoros.vscode-gutter-preview
```

Then write:

```latex
\includegraphics[width=0.8\linewidth]{figures/example.png}
```

You should get:

- an image thumbnail in the gutter,
- a larger preview on hover.

This works best when the image path is resolvable relative to the root `.tex` file.

If it does not preview:

- check that the file exists,
- use a relative path from the root file,
- rebuild the project once,
- make sure the image is not generated into an ignored build directory that VS Code cannot resolve.

---

## 6. Recommended keybindings

Open:

```text
Ctrl/Cmd + Shift + P
Preferences: Open Keyboard Shortcuts (JSON)
```

Add:

```json
[
  {
    "key": "ctrl+alt+b",
    "command": "latex-workshop.build",
    "when": "editorLangId == latex"
  },
  {
    "key": "ctrl+alt+v",
    "command": "latex-workshop.view",
    "when": "editorLangId == latex"
  },
  {
    "key": "ctrl+alt+j",
    "command": "latex-workshop.synctex",
    "when": "editorLangId == latex"
  },
  {
    "key": "ctrl+alt+c",
    "command": "latex-workshop.clean",
    "when": "editorLangId == latex"
  },
  {
    "key": "ctrl+alt+k",
    "command": "latex-workshop.kill",
    "when": "editorLangId == latex"
  }
]
```

On macOS, you may prefer `cmd+alt+...` instead.

---

## 7. Use `latexmk` as your main compiler

`latexmk` is the best default because it automatically reruns LaTeX/BibTeX/Biber enough times to resolve references, citations, glossaries, etc.

The settings above include these recipes:

- `latexmk pdflatex`
- `latexmk xelatex`
- `latexmk lualatex`

For most documents:

```text
latexmk pdflatex
```

is enough.

For Unicode/system fonts:

```text
latexmk xelatex
```

For LuaTeX-based packages:

```text
latexmk lualatex
```

To choose a recipe:

```text
Ctrl/Cmd + Shift + P
LaTeX Workshop: Build with recipe
```

Then select the recipe.

---

## 8. Magic comments for multi-file projects

LaTeX Workshop understands magic comments.

In subfiles, use:

```latex
% !TeX root = ../main.tex
```

To force a compiler:

```latex
% !TeX program = xelatex
```

For Biber:

```latex
% !BIB program = biber
```

For BibTeX:

```latex
% !BIB program = bibtex
```

For spell checking:

```latex
% !TeX spellcheck = en_US
```

For shell escape, only if needed by packages like `minted`:

```latex
% !TeX options = -shell-escape
```

Example:

```latex
% !TeX root = main.tex
% !TeX program = xelatex
% !BIB program = biber
```

---

## 9. Multi-file project structure

A good structure:

```text
my-paper/
  .vscode/
    settings.json
  chapters/
    intro.tex
    methods.tex
    results.tex
  figures/
    figure1.pdf
    figure2.png
  refs/
    bibliography.bib
  main.tex
  .gitignore
```

In `chapters/intro.tex`:

```latex
% !TeX root = ../main.tex

\section{Introduction}

This is an example citation \cite{smith2020}.

See Figure~\ref{fig:example}.
```

In `main.tex`:

```latex
\documentclass{article}

\usepackage{graphicx}
\usepackage{amsmath}
\usepackage{biblatex}

\addbibresource{refs/bibliography.bib}

\begin{document}

\include{chapters/intro}

\printbibliography

\end{document}
```

If a subfile does not detect the root file, add:

```latex
% !TeX root = ../main.tex
```

Or run:

```text
Ctrl/Cmd + Shift + P
LaTeX Workshop: Set LaTeX root file
```

---

## 10. Formatting with `latexindent`

The settings above use:

```json
"latex-workshop.latexindent.enabled": true,
"latex-workshop.latexindent.path": "latexindent"
```

Make sure it works:

```bash
latexindent --version
```

If `latexindent` fails on Windows, you may need Perl installed. TeX Live usually handles this well. MiKTeX may require additional Perl support depending on setup.

You can customize `latexindent` with a `.latexindent.yaml` file in your project root.

Example:

```yaml
defaultIndent: "  "

modifyLineBreaks:
  preserveBlankLines: 1
  textWrapOptions:
    columns: 0
```

If automatic formatting is too aggressive, disable format-on-save for LaTeX only:

```json
"[latex]": {
  "editor.formatOnSave": false
}
```

---

## 11. Linting with `chktex`

The settings above enable:

```json
"latex-workshop.linting.chktex.enabled": true
```

Install it:

```bash
chktex --version
```

`chktex` can be noisy. You can tune it with a `.chktexrc` file.

Example `.chktexrc`:

```text
-Wall
-n22
-n30
-n40
-n41
-n46
```

Common disabled warnings:

- `n22`: suppresses some dollar sign warnings
- `n30`: suppresses some spacing warnings
- `n40`: suppresses some blank line warnings
- `n41`: suppresses some duplicate whitespace warnings
- `n46`: suppresses some `\\` spacing warnings

Adjust to taste.

---

## 12. Grammar and spell checking with LTeX+

LTeX+ is excellent for LaTeX because it understands markup better than a normal spell checker. It's the actively maintained successor to the original LTeX extension (`valentjn.vscode-ltex`), which was archived in April 2026 — install `ltex-plus.vscode-ltex-plus` instead. The configuration keys are unchanged, still under the `ltex.*` namespace.

The settings above use:

```json
"ltex.language": "en-US",
"ltex.checkFrequency": "save",
"ltex.diagnosticSeverity": "information"
```

If you want more aggressive checking, enable picky rules (more style-level suggestions, at the cost of more false positives):

```json
"ltex.additionalRules.enablePickyRules": true
```

If LTeX+ feels slow, keep:

```json
"ltex.checkFrequency": "save"
```

For large documents, this is usually better than checking on every keystroke.

If you use another language, change:

```json
"ltex.language": "en-GB"
```

or:

```json
"ltex.language": "de-DE"
```

or:

```json
"ltex.language": "fr-FR"
```

---

## 13. Optional: Code Spell Checker

If you do not want full grammar checking, use Code Spell Checker instead of LTeX+.

Install:

```bash
code --install-extension streetsidesoftware.code-spell-checker
```

Useful settings:

```json
{
  "cSpell.language": "en",
  "cSpell.enableFiletypes": ["latex", "bibtex"],
  "cSpell.ignoreRegExpList": [
    "\\\\cite\\{[^}]*\\}",
    "\\\\ref\\{[^}]*\\}",
    "\\\\eqref\\{[^}]*\\}",
    "\\\\label\\{[^}]*\\}",
    "\\$[^$]*\\$"
  ]
}
```

If you use both LTeX+ and Code Spell Checker, you may want to disable one of them for LaTeX to avoid duplicate squiggles.

---

## 14. Image pasting with LaTeX Utilities (optional, unmaintained)

LaTeX Utilities can help paste images directly into your document.

Install:

```bash
code --install-extension tecosaur.latex-utilities
```

Copy an image to clipboard, then run:

```text
Ctrl/Cmd + Shift + P
LaTeX Utilities: Paste Image
```

It can save the image into your project and insert an `\includegraphics` block.

This is one of the best quality-of-life features for LaTeX in VS Code — when it works. Be aware the extension's own changelog says it's no longer maintained, so treat it as convenience-only: keep a manual fallback (drag the image into your figures folder and type the `\includegraphics` line yourself) in case a future VS Code update breaks it.

---

## 15. Word count

Install `texcount`:

```bash
texcount --version
```

Then run:

```text
Ctrl/Cmd + Shift + P
LaTeX Workshop: Count words
```

or search:

```text
LaTeX Workshop word count
```

For large projects, word count may require the correct root file to be detected.

---

## 16. Show errors inline with Error Lens

Install:

```bash
code --install-extension usernamehw.errorlens
```

This displays errors, warnings, and linter messages directly next to the line.

This is extremely useful for LaTeX compilation errors, `chktex` warnings, and LTeX+ grammar issues.

If Error Lens becomes too noisy, you can reduce severity or disable it for certain languages.

---

## 17. Add useful LaTeX snippets

Open:

```text
Ctrl/Cmd + Shift + P
Preferences: Configure User Snippets
```

Choose:

```text
latex.json
```

Add snippets like:

```json
{
  "Figure": {
    "prefix": "fig",
    "body": [
      "\\begin{figure}[htbp]",
      "  \\centering",
      "  \\includegraphics[width=0.8\\linewidth]{$1}",
      "  \\caption{$2}",
      "  \\label{fig:$3}",
      "\\end{figure}"
    ],
    "description": "Insert figure environment"
  },
  "Equation": {
    "prefix": "eq",
    "body": [
      "\\begin{equation}",
      "  $1",
      "  \\label{eq:$2}",
      "\\end{equation}"
    ],
    "description": "Insert equation environment"
  },
  "Align": {
    "prefix": "align",
    "body": ["\\begin{align}", "  $1", "\\end{align}"],
    "description": "Insert align environment"
  },
  "Inline cite": {
    "prefix": "citep",
    "body": ["\\citep{$1}"],
    "description": "Parenthetical citation"
  },
  "Text cite": {
    "prefix": "citet",
    "body": ["\\citet{$1}"],
    "description": "Textual citation"
  },
  "Itemize": {
    "prefix": "itemize",
    "body": ["\\begin{itemize}", "  \\item $1", "\\end{itemize}"],
    "description": "Insert itemize environment"
  },
  "Enumerate": {
    "prefix": "enumerate",
    "body": ["\\begin{enumerate}", "  \\item $1", "\\end{enumerate}"],
    "description": "Insert enumerate environment"
  }
}
```

Then type `fig`, `eq`, `align`, etc., and press Tab/Enter.

---

## 18. Recommended `.gitignore`

Add this to your project:

```gitignore
## LaTeX auxiliary files
*.aux
*.bbl
*.bcf
*.blg
*.fdb_latexmk
*.fls
*.glo
*.gls
*.glg
*.idx
*.ilg
*.ind
*.lof
*.log
*.lot
*.nav
*.out
*.snm
*.synctex.gz
*.toc
*.xdv
*.run.xml

## Build directories
build/
out/

## Editor junk
.DS_Store
Thumbs.db
```

If you need to commit generated figures, be more selective.

---

## 19. Test setup with a minimal file

Create `test.tex`:

```latex
\documentclass{article}

\usepackage{amsmath}
\usepackage{graphicx}
\usepackage{hyperref}

\title{VS Code LaTeX Test}
\author{Test Author}
\date{\today}

\begin{document}

\maketitle

\section{Math Preview Test}

Inline math: \(E = mc^2\).

Display math:
\[
  \int_{-\infty}^{\infty} e^{-x^2}\,dx = \sqrt{\pi}
\]

\begin{equation}
  \mathcal{L}\{f(t)\} = \int_0^\infty f(t)e^{-st}\,dt
  \label{eq:laplace}
\end{equation}

See Equation~\eqref{eq:laplace}.

\section{Figure Test}

% Uncomment and change path if you have an image:
% \begin{figure}[htbp]
%   \centering
%   \includegraphics[width=0.6\linewidth]{figures/example.png}
%   \caption{Example figure}
%   \label{fig:example}
% \end{figure}

\end{document}
```

Then:

1. Save.
2. Build.
3. Open PDF view.
4. Put cursor in math.
5. Hover or run math preview.
6. Ctrl/Cmd + click or double-click inside PDF to return to source.

If all of that works, your setup is essentially complete.

---

## 20. If you want an external PDF viewer instead

The internal PDF tab satisfies the “inline preview” requirement, but some people prefer external viewers for speed or annotations.

### Windows: SumatraPDF

```json
{
  "latex-workshop.view.pdf.viewer": "external",
  "latex-workshop.view.pdf.external.viewer.command": "C:/Program Files/SumatraPDF/SumatraPDF.exe",
  "latex-workshop.view.pdf.external.viewer.args": ["-reuse-instance", "%PDF%"],
  "latex-workshop.view.pdf.external.synctex.command": "C:/Program Files/SumatraPDF/SumatraPDF.exe",
  "latex-workshop.view.pdf.external.synctex.args": [
    "-forward-search",
    "%TEX%",
    "%LINE%",
    "-reuse-instance",
    "%PDF%"
  ]
}
```

### macOS: Skim

```json
{
  "latex-workshop.view.pdf.viewer": "external",
  "latex-workshop.view.pdf.external.viewer.command": "/Applications/Skim.app/Contents/SharedSupport/displayline",
  "latex-workshop.view.pdf.external.viewer.args": ["%LINE%", "%PDF%", "%TEX%"]
}
```

### Linux: Zathura

```json
{
  "latex-workshop.view.pdf.viewer": "external",
  "latex-workshop.view.pdf.external.viewer.command": "zathura",
  "latex-workshop.view.pdf.external.viewer.args": [
    "--synctex-forward",
    "%LINE%:0:%TEX%",
    "%PDF%"
  ]
}
```

But if your goal is inline preview inside VS Code, keep:

```json
"latex-workshop.view.pdf.viewer": "tab"
```

---

## 21. Troubleshooting

### “Command not found: latexmk”

Restart VS Code after installing TeX.

Check:

```bash
which latexmk
```

or on Windows PowerShell:

```powershell
Get-Command latexmk
```

If not found, add TeX to `PATH`.

---

### PDF does not preview

Check:

```json
"latex-workshop.view.pdf.viewer": "tab"
```

Then run:

```text
LaTeX Workshop: View LaTeX PDF file
```

Also check the LaTeX Workshop output panel:

```text
Ctrl/Cmd + Shift + P
LaTeX Workshop: Show compiler log
```

or:

```text
View: Output
```

Then select LaTeX Workshop.

---

### Build runs but citations do not resolve

Use `latexmk` first.

If using BibLaTeX, use Biber:

```latex
% !BIB program = biber
```

If using traditional BibTeX:

```latex
% !BIB program = bibtex
```

For BibLaTeX, your preamble should look like:

```latex
\usepackage[backend=biber]{biblatex}
\addbibresource{refs/bibliography.bib}
```

Then use:

```latex
\printbibliography
```

---

### SyncTeX does not work

Make sure your compile command includes:

```bash
-synctex=1
```

The recipes above include it.

Also make sure you are not using an output directory setup that breaks relative paths unless you know what you are doing.

---

### Formatting fails

Check:

```bash
latexindent --version
```

If it fails, install `latexindent` properly.

On Windows, `latexindent` sometimes needs Perl. TeX Live usually includes what is needed; MiKTeX setups vary.

If formatting is too aggressive, disable:

```json
"editor.formatOnSave": false
```

or use manual formatting:

```text
LaTeX Workshop: Format with latexindent
```

---

### Math preview does not show

Do this:

1. Update LaTeX Workshop.
2. Reload VS Code.
3. Build once.
4. Try hovering over math.
5. Try Command Palette:

```text
LaTeX Workshop: Open math preview
```

6. Search settings for:

```text
latex math preview
```

Enable all relevant options.

If you are behind a proxy, MathJax-related previews may be affected depending on extension version/configuration.

---

### LTeX+ is slow

Use:

```json
"ltex.checkFrequency": "save"
```

For very large documents, you can also reduce LTeX+ scope or disable it while drafting.

---

### Large projects feel slow

Use:

```json
"latex-workshop.latex.autoBuild.run": "onSave"
```

instead of building on every file change.

Also keep auxiliary files out of search/watch using the `search.exclude` and `files.watcherExclude` settings above.

For very large projects, consider:

- splitting chapters,
- using `includeonly`,
- disabling shell escape unless needed,
- using draft mode for images:

```latex
\usepackage[draft]{graphicx}
```

---

## 22. Best practical workflow

A good daily workflow:

1. Open project in VS Code.
2. Keep `main.tex` and chapter files open.
3. Use split view:
   - left: `.tex`
   - right: internal PDF
4. Save to build.
5. Use forward search:
   - `Ctrl/Cmd + Alt + J`
6. Use inverse search:
   - double-click PDF
7. Hover math for preview.
8. Use `\cite{...}`, `\ref{...}`, `\eqref{...}` autocomplete.
9. Use `LaTeX Workshop: Clean auxiliary files` when things get weird.
10. Use `LaTeX Workshop: Terminate compilation` if a build hangs.

---

## 23. Minimal “fully-fledged” checklist

You are done when:

- `latexmk` compiles from inside VS Code.
- PDF opens in a VS Code tab.
- Save triggers rebuild.
- Forward search works.
- Inverse search works.
- `\cite{}` autocomplete works.
- `\ref{}` autocomplete works.
- Hover/math preview shows equations.
- `\includegraphics` shows image previews.
- `latexindent` formats on save.
- `chktex` warnings appear inline.
- LTeX+ spelling/grammar appears inline.
- Error Lens displays diagnostics next to the relevant line.
- Auxiliary files are ignored by search and Git.

---

## 24. Final recommended extension set

If you want the cleanest setup, install these:

```bash
code --install-extension James-Yu.latex-workshop
code --install-extension tecosaur.latex-utilities
code --install-extension ltex-plus.vscode-ltex-plus
code --install-extension kisstkondoros.vscode-gutter-preview
code --install-extension usernamehw.errorlens
```

(Remember: `tecosaur.latex-utilities` is optional and unmaintained — drop it if you'd rather not depend on an abandoned extension. `ltex-plus.vscode-ltex-plus` is LTeX+, the maintained fork; don't install the old `valentjn.vscode-ltex`.)

Add this only if you want a separate lightweight spell checker:

```bash
code --install-extension streetsidesoftware.code-spell-checker
```

---

## Bottom line

Use:

- **LaTeX Workshop** as the core LaTeX IDE.
- **`latexmk`** as the compiler driver.
- **Internal PDF tab** for inline document preview.
- **SyncTeX** for forward/inverse navigation.
- **LaTeX Workshop math preview/hover** for inline equation previews.
- **Image Preview** for `\includegraphics` previews.
- **`latexindent`** for formatting.
- **`chktex`** for LaTeX linting.
- **LTeX+** for grammar/spelling.
- **Error Lens** for inline diagnostics.

That setup turns VS Code into a serious, fully-fledged LaTeX editor with strong inline preview capabilities.
