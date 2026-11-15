- `nono pi config directory`

  "$HOME/.local/share/ultimate-pi/chatgpt-pilot-agent" is the nono pi config.

- `nono with pi command`

```sh
nono run \
  --profile pi-chatgpt-pilot \
  --allow-cwd \
  -- env PI_CODING_AGENT_DIR="$HOME/.local/share/ultimate-pi/chatgpt-pilot-agent" \
         JITI_FS_CACHE=0 \
         PI_LENS_CONFIG_PATH="$HOME/.local/share/ultimate-pi/chatgpt-pilot-agent/extensions/pi-lens.json" \
         PI_LENS_HOME="$HOME/.local/share/ultimate-pi/chatgpt-pilot-agent/pi-lens" \
         PILENS_DATA_DIR="$HOME/.local/share/ultimate-pi/chatgpt-pilot-agent/pi-lens/projects" \
         PI_LENS_DISABLE_LSP_INSTALL=1 \
         PI_LENS_DISABLE_TOOL_INSTALL=1 \
         PI_LENS_STARTUP_MODE=minimal \
  pi --offline --no-autoformat --no-autofix --no-tests --no-lens-context \
     --no-tool=ast_grep_replace --no-tool=lsp_navigation
```

- Step 07: `JITI_FS_CACHE=0` avoids shared `/tmp/jiti` compilation-cache permission errors under Nono. This changes caching only; it grants no access.

- Step 08: launch from the authorized project directory with all Lens path, install-disable and mutation-disable settings above. The TypeScript server/compiler are pinned to 5.3.0/5.9.3. Test-only warning-server configuration is excluded from this normal launcher.

- Step 09: MCP stays off until explicitly requested. From an authorized project, run `pi-research` (or `pi-research --fetch` for the separate docs-only Fetch profile). It preserves the Step 07/08 flags above and uses the active agent directory.

```text
@mcp:exa,context7
Find the official API documentation needed for this task.
```

  The directive must be the exact first line, with comma-separated server names and no spaces. Servers disconnect when that request settles; repeat the directive for a new request. Plain prompts leave MCP off. `@mcp:off` explicitly disconnects. Inspect `/mcp` without enabling or changing exposure there. GitHub, Sentry and Playwright remain blocked pending their separate setup. See Step 09 for the current tested/blocked status and Zotero's metadata-only restrictions.
