---
applyTo: "**"
name: GPT Codex Tool Calling
description: Best practices for tool usage with GPT-5.1 Codex models
---
# GPT Codex Tool Calling Best Practices

## Tool Definition Format

GPT Codex uses OpenAI's function calling format:

```json
{
  "type": "function",
  "function": {
    "name": "tool_name",
    "description": "Clear description of the function",
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

### 1. Agentic Workflows
GPT Codex excels at multi-step coding:
- Plan before implementation
- Break down complex tasks
- Execute incrementally
- Verify results

### 2. Tool Selection
- Limit active tools to 10-20 for best results
- Use tool sets for related functions
- Enable only relevant tools per task

### 3. Parallel Function Calling
- Use for independent operations
- Batch file reads
- Parallelize searches

### 4. Structured Outputs
- Request specific JSON schemas
- Use consistent response formats
- Validate return types

## Codex-Specific Features

### Code Generation Excellence
GPT Codex is optimized for:
- Production-ready code
- Test generation
- Refactoring
- Documentation

### Multi-File Operations
Can handle:
- Cross-file refactors
- Module reorganization
- Dependency updates

### Error Recovery
- Handles tool failures gracefully
- Suggests alternatives
- Retries with corrections

## Git-Core Protocol Integration

### Atomic Commits

```bash
# Wrong: Giant commit
git add .
git commit -m "big update"

# Right: Atomic commits
git add src/auth/
git commit -m "feat(auth): add login endpoint #42"

git add tests/auth/
git commit -m "test(auth): add login tests #42"
```

### Issue-Driven Development

1. **Read issue first**
   ```bash
   gh issue view 42
   ```

2. **Create feature branch**
   ```bash
   git checkout -b feat/issue-42
   ```

3. **Implement with references**
   ```bash
   git commit -m "feat(scope): description #42"
   ```

4. **Create PR**
   ```bash
   gh pr create --fill
   ```

## Example: Multi-Step Implementation

```python
# Step 1: Plan
tools = ["search", "read_file"]
# Understand codebase structure

# Step 2: Implement
tools = ["edit_file", "create_file"]
# Make changes atomically

# Step 3: Verify
tools = ["run_command", "test_failure"]
# Run tests and verify

# Step 4: Commit
tools = ["run_command"]
# git add, commit, push
```

## Temperature Settings

For coding tasks:
- **0.0-0.3**: Deterministic code generation
- **0.5**: Balanced creativity/accuracy
- **0.7+**: Avoid for production code
