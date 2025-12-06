---
applyTo: "**"
name: Grok Tool Calling
description: Best practices for tool usage with Grok models
---
# Grok Tool Calling Best Practices

## Tool Definition Format

Grok uses OpenAI-compatible function calling:

```json
{
  "type": "function",
  "function": {
    "name": "tool_name",
    "description": "What the tool does",
    "parameters": {
      "type": "object",
      "properties": {
        "parameter_name": {
          "type": "string",
          "description": "What this parameter does"
        }
      },
      "required": ["parameter_name"]
    }
  }
}
```

## Best Practices

### 1. Leverage 2M Context Window
Grok has the largest context window available:
- Load entire repositories
- Full documentation sets
- Complete git histories
- All configuration files

### 2. Fast Tool Execution
Grok is optimized for speed:
- Batch multiple tool calls
- Use parallel execution
- Minimize round trips

### 3. Real-Time Knowledge
Grok has access to current information:
- Latest library versions
- Recent best practices
- Current documentation

### 4. Agentic Workflows
Built for multi-step operations:
- Complex automation
- Chain tool calls
- Long-running tasks

## Grok-Specific Features

### Massive Context
With 2M tokens you can:
- Analyze entire monorepos
- Process complete documentation
- Understand full dependency trees
- Load historical context

### Speed Optimization
- Optimized inference
- Fast tool response
- Efficient token processing

### Function Calling
- OpenAI-compatible format
- Parallel execution support
- Streaming responses

## Git-Core Protocol Integration

### Full Context Loading

```bash
# Load everything at once (you have room!)
cat .✨/ARCHITECTURE.md
cat AGENTS.md
cat README.md
find . -name "*.md" -exec cat {} \;
```

### Large Codebase Analysis

```bash
# Step 1: Map structure
tree -L 4 --dirsfirst

# Step 2: Load key files
cat package.json  # or Cargo.toml, requirements.txt

# Step 3: Load source
find src -name "*.ts" | xargs cat

# Step 4: Understand tests
find tests -name "*.ts" | xargs cat
```

### Issue Creation

With full context, create comprehensive issues:

```bash
gh issue create \
  --title "Refactor: Complete authentication module" \
  --body "## Context
Based on full codebase analysis...

## Current State
[from loaded context]

## Proposed Changes
[informed by full understanding]

## Affected Files
[complete list from analysis]"
```

## Example: Repository Analysis

```python
# Step 1: Load everything
tools = ["search", "read_file", "list_dir"]
# With 2M context, load entire repo

# Step 2: Analyze
# Process all files in context
# Understand relationships
# Identify patterns

# Step 3: Report
# Create comprehensive analysis
# Document in GitHub Issue
# NOT in .md files!

# Step 4: Plan
# Break down into tasks
# Create multiple issues
# Assign priorities
```

## Performance Tips

1. **Batch reads**: Load multiple files at once
2. **Use search**: Full-text search over context
3. **Parallel tools**: Execute independent operations simultaneously
4. **Stream results**: Process as data arrives
