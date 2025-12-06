---
applyTo: "**"
name: Agent Fallback System
description: Generic fallback behaviors when specific tools or models aren't available
---
# Agent Fallback System

## 🎯 Purpose

Ensure agents NEVER block user progress due to missing tools or model capabilities.

## 🔧 Tool Fallback Matrix

When a specific tool isn't available, use these fallbacks:

| Missing Tool | Fallback Strategy |
|--------------|-------------------|
| `runCommand` | Provide exact commands for user to execute |
| `editFiles` | Show code changes in markdown blocks |
| `githubRepo` / MCP | Use `gh` CLI commands via terminal |
| `search` | Use `grep_search` or ask user for context |
| `fetch` | Provide URLs for user to check manually |
| `problems` | Ask user to run linter/compiler |
| `usages` | Use `grep_search` for symbol references |

## 📋 Model Capability Fallbacks

### When Using Claude Haiku (limited reasoning)
- Break complex tasks into smaller steps
- Ask for confirmation at each step
- Handoff to Sonnet/Opus for complex analysis

### When Using Claude Sonnet (balanced)
- Can handle most tasks
- Handoff to Opus for architecture decisions
- Handoff to Haiku for simple, fast tasks

### When Using Claude Opus (deep reasoning)
- Optimized for complex analysis
- May be slower - use for important decisions
- Handoff to Sonnet for implementation

### When Using Non-Claude Models
- Adapt tool calling format automatically
- Use generic instruction patterns
- Focus on universal capabilities

## 🔄 Cross-Model Compatibility

### Tool Definition Formats

**Claude (input_schema):**
```json
{
  "name": "tool_name",
  "input_schema": { "type": "object", "properties": {} }
}
```

**OpenAI/Grok (function):**
```json
{
  "type": "function",
  "function": { "name": "tool_name", "parameters": {} }
}
```

**Gemini (parameters):**
```json
{
  "name": "tool_name",
  "parameters": { "type": "object", "properties": {} }
}
```

### Generic Adaptation

When model format unknown, provide instructions in natural language that any model can follow.

## 🛡️ Never Block Principle

If you cannot perform an action:

1. **Explain** why the action can't be automated
2. **Provide** exact manual steps
3. **Offer** alternative approaches
4. **Handoff** to appropriate agent if needed

### Example Fallback Response

```markdown
⚠️ **Tool Not Available**

I can't execute `git status` directly, but here's what to do:

1. Open your terminal
2. Run: `git status --porcelain`
3. Share the output with me

**Alternative:** I can analyze files if you paste the output here.
```

## 📊 Capability Detection

Before attempting tool use, agents should:

1. Check if tool is in available tools list
2. If not, use fallback immediately
3. Never attempt unavailable tools

## 🔗 Integration with Recipe System

Recipes may require specific tools. Handle gracefully:

```markdown
Recipe requires: `postgres-server` MCP

**If available:** Use MCP tools
**If not available:** Provide SQL commands for manual execution
```

## 🎭 Model-Agnostic Instructions

Write instructions that work across models:

**❌ Model-specific:**
```
Use extended thinking to analyze...
```

**✅ Model-agnostic:**
```
Carefully analyze step by step:
1. First, consider...
2. Then, evaluate...
3. Finally, decide...
```
