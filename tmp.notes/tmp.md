## The Core Reality: What You're Actually Building

You can replicate roughly 70–80% of a Claude web-app workflow by combining OpenCode Go's $10/month model access with an orchestration stack of LiteLLM, MCP servers, and Pydantic—but you'll be assembling infrastructure that Anthropic ships as a polished product. The gap closes fastest for coding and agentic tasks; it stays widest for multimodal features (native image generation, polished Artifacts UI, visual file uploads) and zero-config UX【turn0search10】【turn5fetch0】.

The key insight is that OpenCode is not just a coding tool—it's a general-purpose **agent runtime** with a plugin system, MCP support, custom tools, and web UI. You're using the coding subscription as cheap compute for a broader agent platform【turn8fetch0】【turn10fetch0】.

---

## Claude Feature → OpenCode Stack Mapping

| Claude Web App Feature        | OpenCode Go + Open-Source Equivalent                            | Setup Effort | Fidelity |
| ----------------------------- | --------------------------------------------------------------- | ------------ | -------- |
| **Chat (Sonnet/Opus)**        | OpenCode TUI/Web UI + Go models (GLM-5.3, Kimi K3, DeepSeek V4) | Low          | High     |
| **Projects (knowledge base)** | `AGENTS.md` rules + `.opencode/skills/` + memory plugins        | Medium       | ~80%     |
| **Artifacts (apps/docs)**     | OpenCode Web UI + custom tools + share links                    | Medium       | ~60%     |
| **Web search**                | MCP servers (Brave Search API, Tavily, Exa)                     | Low          | High     |
| **File analysis (PDF/docs)**  | MCP document servers + custom Python tools                      | Medium       | ~75%     |
| **Code generation**           | OpenCode core (native strength)                                 | None         | High     |
| **Extended thinking**         | Kimi K3 / GLM-5.3 with reasoning                                | None         | Medium   |
| **Memory across sessions**    | `opencode-mem` / `supermemory` plugins                          | Low-Medium   | ~70%     |
| **Model routing**             | LiteLLM proxy + OpenCode Go API key                             | Medium       | High     |
| **Structured outputs**        | Pydantic AI + custom tools                                      | Medium       | High     |
| **Visual/image input**        | DeepSeek V4 Flash Vision Exp (limited)                          | Low          | Low      |

---

## Phase 1: Base Setup

### Installing OpenCode and Connecting Go

```bash
# Install OpenCode
curl -fsSL https://opencode.ai/install | bash

# Start the TUI in your workspace
cd ~/my-workspace
opencode
```

Inside the TUI, connect your Go subscription:

1. Sign up at **OpenCode Zen** (zen.opencode.ai) and subscribe to Go ($10/month)【turn3fetch0】
2. Copy your API key
3. In OpenCode TUI, run `/connect`, select `OpenCode Go`, paste your key
4. Run `/models` to see the 18+ available models【turn3fetch0】

The current Go model lineup includes GLM-5.3, Kimi K3, GPT 5.6 Luna, DeepSeek V4 Pro, Qwen3.8 Max, and others, with monthly limits ranging from $15–$60 in token-equivalent usage per model【turn3fetch0】.

**For the web experience** (closest to Claude's UI):

```bash
# Start OpenCode's web interface
opencode web

# With network access and password protection
OPENCODE_SERVER_PASSWORD=yourpassword opencode web --hostname 0.0.0.0 --port 4096
```

This gives you a browser-based session manager where you can create, view, and manage multiple conversations—functionally similar to Claude's chat interface【turn8fetch2】.

---

## Phase 2: Mimicking Claude Projects

Claude Projects let you pin documents and instructions that persist across chats. OpenCode replicates this via three mechanisms:

### AGENTS.md (Global Instructions)

Create `~/.config/opencode/AGENTS.md` for personal rules that apply everywhere:

```markdown
# My Assistant Rules

## Communication Style

- Be concise but thorough
- Cite sources when making factual claims
- Ask clarifying questions for ambiguous requests

## My Preferences

- I prefer detailed explanations for complex topics
- Always show your reasoning step by step
- When analyzing documents, extract key entities and relationships first

## My Work Context

- I work in [your field]
- Common document types: reports, research papers, emails
- My typical use cases: analysis, writing, planning, coding
```

Run `/init` inside a project directory and OpenCode scans your repo to auto-generate relevant context【turn8fetch1】.

### Skills (Reusable Behaviors)

Create `.opencode/skills/<name>/SKILL.md` files for domain-specific capabilities:

```markdown
---
name: document-analysis
description: Analyze PDFs and documents, extract key insights
---

## What I do

- Read document content using available tools
- Extract entities, relationships, and key claims
- Summarize with structured sections
- Identify action items and follow-ups

## When to use me

Use this skill when the user asks to analyze a document, PDF, report,
or any file requiring comprehension beyond code.
```

OpenCode discovers skills from multiple locations including `.claude/skills/` (Claude Code compatibility)【turn8fetch0】.

### Memory Plugins

Install persistent memory via community plugins:

```bash
# Option 1: opencode-mem (local vector database)
git clone https://github.com/tickernelz/opencode-mem
cd opencode-mem && bun install

# Option 2: supermemory (external service)
bunx opencode-supermemory@latest install
bunx opencode-supermemory@latest login
```

The `opencode-mem` plugin uses embedded Turso/libSQL with vector search, persistent project memories, automatic user profile learning, and 12+ local embedding models【turn4search9】. Supermemory adds a `/supermemory-index` command for cross-session context retrieval【turn4search12】.

---

## Phase 3: Web Search (Claude's Search Feature)

Claude's built-in web search maps to MCP servers. The top options for 2026:

### Tavily MCP Server (Recommended)

```bash
# Add to your OpenCode project
opencode mcp add tavily --url https://mcp.tavily.com/mcp

# Or configure manually in opencode.jsonc
```

The Tavily MCP server provides `tavily-search`, `tavily-extract`, `tavily-map`, and `tavily-crawl` tools with real-time web search capabilities【turn6search0】.

### Brave Search API Alternative

Brave Search API remains a strong foundation option for AI search in 2026, offering good coverage and a generous free tier【turn6search2】.

### Configuration

Add to your `opencode.jsonc`:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "servers": {
      "tavily": {
        "type": "remote",
        "url": "https://mcp.tavily.com/mcp",
      },
      "context7": {
        "type": "remote",
        "url": "https://mcp.context7.com/mcp",
      },
    },
  },
}
```

Remote servers use OAuth by default; run `/mcps` in OpenCode to authenticate【turn5fetch0】.

---

## Phase 4: Structured Outputs with Pydantic

Claude's structured output feature maps to Pydantic AI when you need guaranteed, validated data formats.

### Setting Up Pydantic AI with Go Models

```bash
pip install pydantic-ai
```

Create a custom tool that uses Pydantic for validated outputs:

```python
# .opencode/tools/analyze_data.py
from pydantic import BaseModel, Field
from typing import List, Optional

class Insight(BaseModel):
    category: str = Field(description="Category of insight")
    finding: str = Field(description="The specific finding")
    confidence: float = Field(ge=0, le=1, description="Confidence level 0-1")
    evidence: Optional[str] = Field(None, description="Supporting evidence")

class AnalysisResult(BaseModel):
    summary: str
    key_insights: List[Insight]
    recommendations: List[str]
    sentiment: str = Field(description="overall sentiment: positive/neutral/negative")

# This schema can be used with any LLM via LiteLLM or direct API calls
```

Pydantic AI implements three methods for structured outputs: Tool Output (using tool calls), and other approaches that guarantee the LLM returns exactly what you specify【turn4search3】【turn6search4】.

---

## Phase 5: LiteLLM as Unified Model Router

When you need to combine OpenCode Go models with direct Claude API access or other providers, LiteLLM acts as the translation layer.

### Installation and Setup

```bash
# Install with proxy support (pin to specific version for security)
pip install litellm[proxy]==1.97.0

# Or via Docker (recommended for production)
docker pull litellm/litellm:1.97.0
```

**Critical security note**: Versions v1.82.7 and v1.82.8 (published March 24, 2026) were affected by a supply-chain compromise with credential-stealing install hooks. Always pin to verified versions【turn10fetch1】.

### Configuration

Create `litellm-config.yaml`:

```yaml
model_list:
  # OpenCode Go models via proxy
  - model_name: glm-5.3
    litellm_params:
      model: openai/glm-5.3
      api_base: https://go.opencode.ai/v1
      api_key: os.environ/OPENCODE_GO_KEY

  # Direct Claude API (when you need Claude specifically)
  - model_name: claude-sonnet
    litellm_params:
      model: anthropic/claude-sonnet-4-6
      api_key: os.environ/ANTHROPIC_API_KEY

  # Fallback chain
  - model_name: smart-model
    litellm_params:
      model: anthropic/claude-sonnet-5
      api_key: os.environ/ANTHROPIC_API_KEY
    fallbacks: ["glm-5.3", "kimi-k3"]

router_settings:
  routing_strategy: least-busy
  num_retries: 2
  timeout: 30

general_settings:
  master_key: os.environ/LITELLM_MASTER_KEY
```

Start the proxy:

```bash
litellm --config litellm-config.yaml --port 4000
```

Now OpenCode can use LiteLLM as a provider, routing between Go models and direct Claude API calls based on availability and cost【turn0search14】【turn10fetch1】.

### Connecting OpenCode to LiteLLM

In OpenCode's `opencode.jsonc`:

```jsonc
{
  "provider": {
    "litellm": {
      "npm": "@ai-sdk/openai-compatible",
      "options": {
        "baseURL": "http://localhost:4000/v1",
        "apiKey": "your-litellm-key",
      },
      "models": {
        "smart-model": {},
        "glm-5.3": {},
        "claude-sonnet": {},
      },
    },
  },
}
```

---

## Phase 6: Custom Tools for Non-Coding Work

OpenCode's custom tools system lets you create functions the LLM can call, written in any language (the definition is TypeScript/JavaScript but can invoke Python, shell, etc.)【turn10fetch0】.

### Document Analysis Tool

```typescript
// .opencode/tools/doc_analysis.ts
import { tool } from "@opencode-ai/plugin";
import { execSync } from "child_process";

export default tool({
  description: "Analyze document content and extract structured insights",
  args: {
    file_path: tool.schema.string().describe("Path to document"),
    analysis_type: tool.schema
      .enum(["summary", "entities", "sentiment", "full"])
      .describe("Type of analysis"),
  },
  async execute(args) {
    // Invoke Python script for heavy lifting
    const result = execSync(
      `python3 ~/.config/opencode/scripts/analyze_doc.py ${args.file_path} ${args.analysis_type}`,
      { encoding: "utf-8" },
    );
    return result;
  },
});
```

### Data Visualization Tool

```typescript
// .opencode/tools/visualize.ts
import { tool } from "@opencode-ai/plugin";

export const chart = tool({
  description: "Create a chart from data",
  args: {
    data: tool.schema.string().describe("JSON data to visualize"),
    chart_type: tool.schema.enum(["bar", "line", "pie", "scatter"]),
    title: tool.schema.string().optional(),
  },
  async execute(args) {
    // Generate HTML with embedded chart (like Claude Artifacts)
    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
      </head>
      <body>
        <canvas id="chart"></canvas>
        <script>
          new Chart(document.getElementById('chart'), {
            type: '${args.chart_type}',
            data: ${args.data},
            options: { title: { display: true, text: '${args.title || "Chart"}' } }
          });
        </script>
      </body>
      </html>
    `;
    // Save to a file that can be opened in browser
    return `Chart saved. Open in browser to view.`;
  },
});
```

---

## Phase 7: Mimicking Artifacts

Claude Artifacts create interactive, shareable apps. The closest approximation combines OpenCode's Web UI with custom tools and OpenCode's share feature:

1. **Generation**: Use custom tools to generate HTML/React/Markdown content
2. **Preview**: OpenCode's Web UI displays content; use `opencode share` to create shareable links【turn8fetch2】
3. **Persistence**: Save generated artifacts to a project directory with skills that reference them

The fidelity gap is real—Claude's Artifacts have a polished preview environment with live editing. Your version will require more manual file management but achieves the core goal of creating reusable, interactive outputs.

---

## Phase 8: Research and Analysis Workflows

Here's a concrete non-coding workflow that demonstrates the full stack:

### Market Research Agent Setup

```bash
# Create workspace
mkdir ~/market-research && cd ~/market-research

# Initialize OpenCode
opencode /init
```

Create `.opencode/skills/market-analysis/SKILL.md`:

```markdown
---
name: market-analysis
description: Conduct comprehensive market research using web search and analysis
---

## What I do

- Search for recent market data using Tavily/Brave
- Extract key metrics and trends
- Analyze competitive landscape
- Generate structured reports with citations

## When to use me

Use when asked to research a market, industry, company,
or competitive landscape.
```

Create `.opencode/tools/fetch_data.py` (invoked by TypeScript wrapper):

```python
#!/usr/bin/env python3
import requests
import json
from pydantic import BaseModel
from typing import List

class MarketData(BaseModel):
    market_size: str
    growth_rate: str
    key_players: List[str]
    trends: List[str]

def fetch_market_data(query: str) -> MarketData:
    # Use Tavily API or similar
    response = requests.post(
        "https://api.tavily.com/search",
        json={"query": query, "search_depth": "advanced"}
    )
    # Process and return structured data
    ...
```

**Usage flow**: Start OpenCode → `/skills` shows market-analysis → prompt: "Analyze the AI coding tools market in 2026" → agent uses search tools, analyzes results, generates structured report with citations.

---

## Known Limitations and Gaps

**Where the stack falls short of Claude**:

1. **Multimodal input**: Claude handles image uploads natively. OpenCode Go's vision support is limited to DeepSeek V4 Flash Vision Exp, which is experimental【turn3fetch0】. You'll need separate vision APIs for robust image understanding.

2. **Artifacts UX**: Claude's preview environment with live editing and one-click sharing has no direct equivalent. Your HTML/React outputs will require manual preview and file management.

3. **Context window**: Claude Sonnet offers 200K context; the best Go models offer comparable or larger windows, but the experience of uploading multiple large documents to a chat is smoother in Claude.

4. **Fine-tuned personality**: Claude's specific response style and safety tuning cannot be replicated exactly. Open models have different characteristics—you may prefer some (GLM-5.3's analytical depth) and miss others (Claude's nuanced tone).

5. **Zero-config reliability**: Anthropic's service "just works." Your stack has multiple components that can fail independently—LiteLLM proxy down, MCP server timeout, plugin compatibility issues.

6. **Cost predictability**: Go's $10/month covers the models, but you'll pay separately for search APIs (Tavily ~$30/month for heavy use), vision APIs if needed, and hosting if you run LiteLLM on a VPS.

---

## Recommended Workflow Example

For a **daily-driver setup** that covers 80% of Claude use cases:

```bash
# Morning setup (or add to shell profile)
cd ~/workspace

# Start OpenCode with web UI
opencode web --port 4096 &

# In another terminal, start LiteLLM if using multiple providers
litellm --config ~/litellm-config.yaml --port 4000 &

# Open browser to localhost:4096
```

**Daily usage patterns**:

| Task              | Workflow                                                                        |
| ----------------- | ------------------------------------------------------------------------------- |
| Quick questions   | Web UI → default Go model → direct answer                                       |
| Document analysis | Upload file → auto-triggers doc-analysis skill → structured output              |
| Research          | Prompt → Tavily MCP search → Pydantic-validated findings                        |
| Code help         | TUI (better terminal integration) → Go coding models                            |
| Complex analysis  | Route through LiteLLM → Claude API for hardest problems → fallback to Go models |
| Creative writing  | Web UI → GLM-5.3 (strong creative capabilities)                                 |
| Data analysis     | Custom Python tools → Pydantic structured outputs → visualization tools         |

The stack costs ~$10–40/month total depending on search API usage, versus $20–200 for Claude subscriptions—**but requires 2–4 hours of initial setup and ongoing maintenance** that Claude's product eliminates.

---

## Quick-Start Checklist

- [ ] Install OpenCode (`curl -fsSL https://opencode.ai/install | bash`)
- [ ] Subscribe to OpenCode Go at zen.opencode.ai ($10/month)
- [ ] Connect Go API key via `/connect` in TUI
- [ ] Create `~/.config/opencode/AGENTS.md` with personal instructions
- [ ] Add 2–3 skills in `~/.config/opencode/skills/` for common workflows
- [ ] Install memory plugin (`opencode-mem` or `supermemory`)
- [ ] Add Tavily MCP server (`opencode mcp add tavily --url https://mcp.tavily.com/mcp`)
- [ ] Set up `opencode web` for browser interface
- [ ] (Optional) Install LiteLLM for multi-provider routing
- [ ] (Optional) Create custom tools for domain-specific workflows
- [ ] Test with a real task: "Research [topic] and give me a structured summary"

The result is a personalized AI workspace that handles most Claude workflows at 25–50% of the cost, with full control over your data and no vendor lock-in—traded against higher setup complexity and some feature gaps in multimodal and UX polish【turn0search10】【turn3fetch0】【turn5fetch0】【turn8fetch2】.

---

---

---

## Audit Summary: What I Got Wrong and What I Missed

After careful fact-checking against current sources, I've identified several errors and gaps in my previous response that need correction before presenting the revised guide.

**Key corrections made:**

1. **OpenCode Go vs. OpenCode Zen confusion**: I incorrectly referenced "zen.opencode.ai" for Go signup. OpenCode Go and OpenCode Zen are different services—Go is a $10/month flat subscription while Zen is pay-per-token【turn0search4】【turn0search3】. The correct Go signup URL is `opencode.ai/go` with base URL `https://opencode.ai/zen/go/v1`【turn0search2】.

2. **Outdated Claude feature set**: I described Claude's web app based on older information. As of September 2026, Claude has merged Chat and Cowork into a single unified app, added Docs and Slides tools, integrated Claude Design into conversations, and Cowork now runs on web, mobile, and desktop【turn0search6】【turn0search9】.

3. **Missing Open WebUI option**: I overlooked that Open WebUI can be self-hosted and integrates Claude models natively through Anthropic's OpenAI-compatible endpoint, providing an alternative frontend that's closer to Claude's UX than OpenCode's web UI【turn0search13】【turn0search10】.

4. **Incomplete skill ecosystem**: I mentioned only a few skills but missed important ones like `stop-slop` (strips AI writing tells), `Handoff` (session compression), `Grill Me` (plan interrogation), and `Obra Superpowers` (multi-agent framework)【turn0search6】.

---

## Revised Complete Guide: OpenCode Go + Open-Source Stack to Replicate Claude

### The Honest Assessment

You can replicate approximately 70–80% of Claude's web-app experience using OpenCode Go as your compute layer, with LiteLLM for routing, MCP servers for extended capabilities, and Pydantic AI for structured outputs. The remaining 20–30% gap exists primarily in: native multimodal input (image understanding), polished Artifacts preview environment, zero-config reliability, and Claude's specific personality tuning【turn0search4】【turn0search6】.

The fundamental insight is that OpenCode functions as a general-purpose agent runtime—not just a coding tool. Its skills system, MCP integration, custom tools, and web UI provide the infrastructure for building a Claude-like experience on open models【turn0search7】【turn0search14】.

---

### Feature Mapping Table (Corrected)

| Claude Feature (Sept 2026)       | OpenCode Stack Equivalent                | Setup Effort | Fidelity |
| -------------------------------- | ---------------------------------------- | ------------ | -------- |
| **Unified Chat/Cowork**          | OpenCode Web UI (`opencode web`)         | Low          | ~75%     |
| **Projects (knowledge base)**    | `AGENTS.md` + skills + memory plugins    | Medium       | ~80%     |
| **Artifacts (interactive apps)** | Custom tools + share links + Open WebUI  | Medium-High  | ~60%     |
| **Docs & Slides tools**          | Custom tools + templates + Pydantic AI   | High         | ~65%     |
| **Claude Design (in-chat)**      | Custom visualization tools               | High         | ~50%     |
| **Web search**                   | Firecrawl skill / Tavily MCP / Brave API | Low          | High     |
| **File analysis (PDF/images)**   | MCP document servers + vision models     | Medium       | ~70%     |
| **Code generation**              | OpenCode native capability               | None         | High     |
| **Extended thinking**            | Kimi K3 / GLM-5.3 reasoning modes        | None         | Medium   |
| **Memory across sessions**       | Memory plugins + AGENTS.md               | Low-Medium   | ~75%     |
| **Skills & Plugins**             | OpenCode skills system (SKILL.md)        | Low          | ~85%     |
| **Model routing**                | LiteLLM proxy                            | Medium       | High     |
| **Structured outputs**           | Pydantic AI framework                    | Medium       | High     |
| **Mobile access**                | OpenCode web on mobile browser           | Low          | ~60%     |

---

### Phase 1: Corrected Base Setup

```bash
# Install OpenCode
curl -fsSL https://opencode.ai/install | bash

# Navigate to your workspace
cd ~/my-workspace

# Start OpenCode (TUI mode)
opencode

# OR start with web interface
opencode web
```

**Connecting OpenCode Go (corrected process):**

1. Visit **opencode.ai/go** (not zen.opencode.ai) and subscribe for $10/month【turn0search2】
2. Create/sign into your account with email
3. Copy your API key from the dashboard
4. In OpenCode TUI, run `/connect`, select `OpenCode Go`, paste your key

The base URL for OpenCode Go is `https://opencode.ai/zen/go/v1`, and it uses an OpenAI-compatible endpoint with the token variable `OPENCODE_API_KEY`【turn0search2】.

**Current Go model lineup includes**: GLM-5.3-Flash, GLM-5.3, GLM-5.2, Kimi K3, Kimi K2.7 Code, GPT 5.6 Luna, DeepSeek V4 Pro, DeepSeek V4 Flash, Qwen3.8 Max, LongCat-2.0, MiMo-V2.5, MiniMax M3, and others with monthly limits from $15–$60 in token-equivalent usage【turn0search4】.

---

### Phase 2: Claude Projects Equivalent (Knowledge Base)

Claude Projects pin documents and instructions that persist across conversations. OpenCode replicates this through three mechanisms:

#### AGENTS.md (Instructions)

Create `~/.config/opencode/AGENTS.md` for global rules:

```markdown
# My Assistant Configuration

## Communication Style

- Be direct and concise
- Show reasoning for complex analyses
- Ask clarifying questions for ambiguous requests

## Analysis Preferences

- When analyzing documents: extract entities, relationships, key claims first
- For research: always cite sources and distinguish facts from inference
- For creative tasks: offer multiple options with tradeoffs

## My Context

- Field: [your domain]
- Common tasks: analysis, writing, research, planning, coding
- Output preferences: structured formats when possible
```

Run `/init` in any project directory and OpenCode scans the codebase to generate relevant context automatically【turn0search7】.

#### Skills System (Reusable Behaviors)

Create `.opencode/skills/<name>/SKILL.md` for domain capabilities:

```markdown
---
name: research-analyst
description: Conduct thorough research with citations and structured analysis
---

## What I do

- Search the web for current information using available tools
- Extract key findings, distinguish facts from opinions
- Synthesize insights with proper citations
- Identify gaps and areas needing further investigation

## When to use me

Use when asked to research a topic, analyze trends,
compare options, or provide a comprehensive overview
of any subject requiring current information.
```

OpenCode discovers skills from multiple locations: `.opencode/skills/`, `.claude/skills/` (Claude compatibility), and `~/.config/opencode/skills/` (global)【turn0search7】.

#### Recommended Skills to Install

Based on the 2026 ecosystem, these skills provide the most value for Claude-like functionality【turn0search6】:

| Skill                | Purpose                                        | Claude Equivalent             |
| -------------------- | ---------------------------------------------- | ----------------------------- |
| **Firecrawl**        | Live web context: search, scrape, crawl        | Web search + file analysis    |
| **stop-slop**        | Strips AI writing patterns from output         | Claude's natural tone         |
| **Handoff**          | Compresses sessions to markdown for continuity | Project memory                |
| **Grill Me**         | Interviews you about plans before execution    | Claude's clarifying questions |
| **Obra Superpowers** | Multi-agent development framework              | Complex task decomposition    |

Install via the community repository:

```bash
git clone https://github.com/farmage/opencode-skills.git
cd opencode-skills
./install.sh  # global installation
# OR
make install-local  # project-local
```

---

### Phase 3: Web Search (Claude's Search Feature)

Claude's integrated web search maps to several options:

#### Option A: Firecrawl Skill (Recommended)

The Firecrawl skill provides live web context including search, scraping, crawling, and browser automation—closest to Claude's native search【turn0search6】.

#### Option B: Tavily MCP Server

```bash
opencode mcp add tavily --url https://mcp.tavily.com/mcp
```

#### Option C: Brave Search API

Configure via custom tool or MCP server.

#### MCP Configuration (Corrected Syntax)

Add to your `opencode.jsonc`:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "servers": {
      "tavily": {
        "type": "remote",
        "url": "https://mcp.tavily.com/mcp",
      },
      "context7": {
        "type": "remote",
        "url": "https://mcp.context7.com/mcp",
      },
    },
  },
}
```

Remote servers use OAuth by default; authenticate via `/mcps` command in OpenCode【turn0search17】.

---

### Phase 4: Pydantic AI for Structured Outputs

Pydantic AI is a full agent framework for building typed, production-ready agents in Python. It provides validated outputs, model routing, and evaluation capabilities【turn0search12】【turn0search14】.

```bash
pip install pydantic-ai
```

Create structured output schemas:

```python
from pydantic import BaseModel, Field
from typing import List, Optional

class ResearchFinding(BaseModel):
    claim: str = Field(description="The specific finding or claim")
    evidence: str = Field(description="Supporting evidence or source")
    confidence: float = Field(ge=0, le=1, description="Confidence level")
    source_url: Optional[str] = Field(None, description="Source URL if applicable")

class ResearchReport(BaseModel):
    topic: str
    summary: str
    key_findings: List[ResearchFinding]
    open_questions: List[str]
    methodology: str
```

Use with OpenCode Go models through LiteLLM or direct API integration.

---

### Phase 5: LiteLLM for Model Routing

LiteLLM acts as a unified proxy that translates between different API formats, enabling you to combine OpenCode Go models with direct Claude API access.

```bash
# Install (pin to specific version for security)
pip install litellm[proxy]==1.97.0
```

**Security note**: Versions v1.82.7 and v1.82.8 (March 24, 2026) were compromised with credential-stealing hooks. Always pin to verified versions【turn0search4】.

Create `litellm-config.yaml`:

```yaml
model_list:
  # OpenCode Go models
  - model_name: glm-5.3
    litellm_params:
      model: openai/glm-5.3
      api_base: https://opencode.ai/zen/go/v1
      api_key: os.environ/OPENCODE_API_KEY

  # Direct Claude API (when needed)
  - model_name: claude-sonnet
    litellm_params:
      model: anthropic/claude-sonnet-4-6
      api_key: os.environ/ANTHROPIC_API_KEY

  # Smart routing with fallbacks
  - model_name: smart
    litellm_params:
      model: anthropic/claude-sonnet-5
      api_key: os.environ/ANTHROPIC_API_KEY
    fallbacks: ["glm-5.3", "kimi-k3"]

router_settings:
  routing_strategy: least-busy
  num_retries: 2
  timeout: 30
```

---

### Phase 6: Alternative Approach — Open WebUI Integration

An option I previously missed: **Open WebUI** can be self-hosted and integrates Claude models natively, providing a chat experience closer to Claude's native interface than OpenCode's web UI【turn0search13】【turn0search10】.

```bash
# Deploy Open WebUI
docker run -d -p 3000:8080 \
  -v open-webui:/app/backend/data \
  -e ANTHROPIC_API_KEY=your_key_here \
  ghcr.io/open-webui/open-webui:main
```

Open WebUI supports Claude models through Anthropic's OpenAI-compatible endpoint with automatic model discovery. It provides persistent knowledge bases, team collaboration, and a polished chat interface【turn0search13】.

**Hybrid architecture possibility**:

- Use Open WebUI as the frontend (better chat UX)
- Route requests through LiteLLM (model flexibility)
- Use OpenCode Go models for most tasks
- Fall back to Claude API for specific needs

---

### Phase 7: Custom Tools for Non-Coding Work

OpenCode's custom tools system lets you create functions the LLM can call. Tool definitions are TypeScript/JavaScript but can invoke scripts in any language【turn0search16】.

#### Document Analysis Tool

```typescript
// .opencode/tools/analyze_document.ts
import { tool } from "@opencode-ai/plugin";
import { execSync } from "child_process";

export default tool({
  description: "Analyze document content and extract structured insights",
  args: {
    file_path: tool.schema.string().describe("Path to document"),
    analysis_type: tool.schema.enum([
      "summary",
      "entities",
      "sentiment",
      "full",
    ]),
  },
  async execute(args) {
    const result = execSync(
      `python3 ~/.config/opencode/scripts/analyze.py ${args.file_path} ${args.analysis_type}`,
      { encoding: "utf-8" },
    );
    return result;
  },
});
```

#### Visualization Tool (Artifacts-like)

```typescript
// .opencode/tools/create_artifact.ts
import { tool } from "@opencode-ai/plugin";
import { writeFileSync } from "fs";
import { join } from "path";

export default tool({
  description: "Create an interactive HTML artifact (chart, dashboard, app)",
  args: {
    content: tool.schema.string().describe("HTML/React/Markdown content"),
    title: tool.schema.string().describe("Title for the artifact"),
    artifact_type: tool.schema.enum(["chart", "dashboard", "document", "app"]),
  },
  async execute(args, context) {
    const artifactsDir = join(context.cwd, ".artifacts");
    const filename = `${Date.now()}-${args.title.replace(/\s+/g, "-")}.html`;
    const filepath = join(artifactsDir, filename);

    writeFileSync(filepath, args.content);

    return `Artifact created: ${filepath}\nOpen in browser to view.`;
  },
});
```

---

### Phase 8: Research Workflow Example

Here's a concrete non-coding workflow demonstrating the full stack:

```bash
# Create workspace
mkdir ~/research && cd ~/research
opencode /init  # Generate project context
```

**Setup skills and tools:**

```
.opencode/
├── skills/
│   ├── research-analyst/
│   │   └── SKILL.md
│   ├── market-analysis/
│   │   └── SKILL.md
│   └── document-review/
│       └── SKILL.md
├── tools/
│   ├── analyze_document.ts
│   ├── create_chart.ts
│   └── fetch_data.ts
└── AGENTS.md
```

**Usage**: Start OpenCode → prompt "Research the AI coding tools market" → agent uses Firecrawl skill for search, analyze_document tool for PDFs, create_chart tool for visualizations, Pydantic AI for structured outputs.

---

### Known Limitations (Updated and Honest)

**Where the stack genuinely falls short**:

1. **Image understanding**: Claude handles image uploads natively with strong vision capabilities. OpenCode Go's vision support is limited to experimental models. You'll need separate vision APIs for robust image analysis【turn0search8】.

2. **Artifacts UX**: Claude's preview environment with live editing and instant sharing has no direct equivalent. Your HTML outputs require manual file management and browser preview.

3. **Docs & Slides tools**: Claude's new native document and presentation tools (September 2026) have no direct open-source equivalent. You'd need to build custom tools with significant effort【turn0search9】.

4. **Personality and tone**: Claude's specific response characteristics cannot be replicated. Open models have different strengths (GLM-5.3's analytical depth, Kimi K3's reasoning) and weaknesses.

5. **Reliability**: Anthropic's service is consistently available. Your multi-component stack has more failure points—LiteLLM proxy, MCP servers, plugins, custom tools.

6. **Mobile experience**: Claude has native mobile apps. Your stack requires using OpenCode's web interface on mobile browser, which is functional but less polished.

---

### Cost Comparison (Realistic)

| Component                 | Monthly Cost | Claude Equivalent      |
| ------------------------- | ------------ | ---------------------- |
| OpenCode Go               | $10          | $20 (Pro) – $200 (Max) |
| Search API (Tavily/Brave) | $0–30        | Included               |
| Vision API (if needed)    | $0–20        | Included               |
| Hosting (if using VPS)    | $0–20        | Included               |
| **Total**                 | **$10–80**   | **$20–200**            |

The cost advantage diminishes if you need vision capabilities or heavy search usage, but remains significant for text-focused workflows.

---

### Recommended Architecture

For the best experience balancing capability and simplicity:

```
┌─────────────────────────────────────┐
│   Open WebUI (Frontend)             │
│   OR OpenCode Web UI               │
├─────────────────────────────────────┤
│   LiteLLM (Model Router)           │
│   ├─ OpenCode Go ($10/mo)         │
│   ├─ Claude API (fallback)         │
│   └─ Local models (optional)       │
├─────────────────────────────────────┤
│   OpenCode (Agent Runtime)          │
│   ├─ Skills (behaviors)            │
│   ├─ Custom Tools (capabilities)   │
│   ├─ MCP Servers (extensions)      │
│   └─ AGENTS.md (instructions)      │
├─────────────────────────────────────┤
│   Pydantic AI (Structured Outputs) │
├─────────────────────────────────────┤
│   External Services                 │
│   ├─ Search APIs                   │
│   ├─ Vision APIs                   │
│   └─ Document processing           │
└─────────────────────────────────────┘
```

**Quick-start checklist**:

- [ ] Install OpenCode
- [ ] Subscribe to OpenCode Go at `opencode.ai/go`
- [ ] Configure `AGENTS.md` with personal instructions
- [ ] Install 3–5 skills for common workflows
- [ ] Add MCP server for web search (Tavily or Firecrawl)
- [ ] Set up `opencode web` for browser interface
- [ ] (Optional) Deploy Open WebUI for better chat UX
- [ ] (Optional) Install LiteLLM for multi-provider routing
- [ ] (Optional) Create custom tools for domain-specific needs
- [ ] Test with real tasks across coding and non-coding domains

This stack provides a genuinely capable alternative to Claude for most use cases, with full control over your data and no vendor lock-in, at the cost of setup complexity and some feature gaps in multimodal and polish【turn0search4】【turn0search6】【turn0search7】.
