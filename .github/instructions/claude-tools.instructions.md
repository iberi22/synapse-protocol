---
applyTo: "**"
name: Claude Tool Calling
description: Best practices for tool usage with Claude models
---
# Claude Tool Calling Best Practices

## Tool Definition Format

Claude uses `input_schema` format for tool definitions:

```json
{
  "name": "tool_name",
  "description": "Clear description of what the tool does",
  "input_schema": {
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
```

## Best Practices

### 1. Tool Naming
- Use `snake_case` for tool names
- Be descriptive: `create_github_issue` not `make_issue`
- Avoid abbreviations

### 2. Descriptions
- Write clear, concise descriptions
- Include example inputs when helpful
- Mention edge cases

### 3. Parameters
- Use descriptive parameter names
- Provide detailed descriptions
- Use `enum` for constrained values
- Mark truly required parameters only

### 4. Response Handling
- Expect structured JSON responses
- Handle errors gracefully
- Chain tools when needed

## Claude-Specific Features

### Extended Thinking
For complex tasks, Claude can "think" before responding:
- Use for multi-step reasoning
- Leverage for planning tool sequences
- Enable deeper analysis

### Parallel Tool Use
Claude can invoke multiple tools simultaneously:
- Use when operations are independent
- Improves efficiency for batch operations

### Context Awareness
- Claude maintains conversation context
- Reference previous tool results
- Build on prior interactions

## Git-Core Protocol Integration

When using tools in Git-Core Protocol:

1. **Issue Creation**
   - Use `gh issue create` or create files in `.github/issues/`
   - Never create .md tracking files

2. **Progress Updates**
   - Use `gh issue comment`
   - Reference issues by number

3. **Code Changes**
   - Use atomic commits
   - Reference issues in commit messages
