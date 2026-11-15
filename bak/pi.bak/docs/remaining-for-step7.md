Still needed:

- In a Pi session using the custom config directory, confirm /help shows the permission controls and that a harmless Bash request produces a visible approval prompt. My test turn stalled before the prompt appeared; I stopped the Pi process.
- The guide’s model-issued git status denial check remains undone. The workspace instructions prohibit Git commands through agent tools, so I couldn’t run that test. It requires an explicit decision to override that restriction or an acceptable alternative verification.
- Step 07’s overall PASS depends on those acceptance checks. For a normal launch, Pi needs PI_CODING_AGENT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/pi" set; it does not automatically use the XDG target.

The Step 07 policy file itself doesn’t need another edit
