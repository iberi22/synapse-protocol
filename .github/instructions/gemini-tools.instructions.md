---
applyTo: "**"
name: Gemini Tool Calling
description: Best practices for tool usage with Gemini models
---
# Gemini Tool Calling Best Practices

## Tool Definition Format

Gemini uses `parameters` schema format:

```json
{
  "name": "tool_name",
  "description": "What the tool does and when to use it",
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
```

## Best Practices

### 1. Leverage Large Context (1M+ tokens)
- Load entire files when relevant
- Don't truncate unnecessarily
- Use full codebase context

### 2. Multi-Modal Capabilities
When appropriate, request:
- Screenshots for UI issues
- Diagrams for architecture
- Charts for data visualization

### 3. Function Declarations
- Use clear, action-oriented names
- Provide comprehensive descriptions
- Include usage examples in descriptions

### 4. Response Handling
- Parse structured responses
- Handle multiple function calls
- Verify return types

## Gemini-Specific Features

### Grounding
Use Google Search grounding for:
- Current documentation
- Latest best practices
- Real-time information

### Code Execution
Gemini can execute code:
- Python for calculations
- Data transformations
- Quick validations

### Safety Settings
Be aware of:
- Content filtering
- Harm categories
- Response blocking

## Git-Core Protocol Integration

When using tools with Gemini:

1. **Use Full Context**
   - Load ARCHITECTURE.md completely
   - Read entire instruction files
   - Understand full scope before acting

2. **Visual Inputs**
   - Accept screenshots when user shares
   - Analyze diagrams for understanding
   - Process error screenshots

3. **Structured Outputs**
   - Return well-formatted Markdown
   - Use tables for comparisons
   - Create clear hierarchies

## Example: Issue Creation with Gemini

```python
# Gemini tool call for issue creation
function_call = {
    "name": "create_issue",
    "args": {
        "title": "Feature: User authentication",
        "body": "## Description\n...",
        "labels": ["enhancement", "auth"]
    }
}
```

## Large Codebase Analysis

With 1M+ context, you can:
1. Load entire module directories
2. Understand cross-file dependencies
3. Analyze full git history
4. Process complete documentation
