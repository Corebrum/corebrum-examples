# General Task Examples

This directory contains general-purpose task examples that demonstrate various Corebrum features and don't fit into specific technology categories.

## Examples

### 1. Git Repository Task (`git_repo_task.json`)

Demonstrates how to execute code from a Git repository.

**Features:**
- Loads code from a Git repository
- Shows external code source management
- Demonstrates JSON task definition format

**Usage:**
```bash
corebrum submit --file task_definitions/general/git_repo_task.json
```

### 2. Mixed Sources Demo (`mixed_sources_demo.yaml`)

Shows how to use multiple external code sources in a single task.

**Features:**
- Demonstrates multiple code source types
- Shows conditional code execution
- Combines different source formats

**Usage:**
```bash
corebrum submit --file task_definitions/general/mixed_sources_demo.yaml
```

### 3. Multi-Dependency Task (`multi_dependency_task.yaml`)

Example of a task with multiple dependencies and complex input/output handling.

**Features:**
- Multiple input dependencies
- Complex data flow
- Demonstrates advanced task configuration

**Usage:**
```bash
corebrum submit --file task_definitions/general/multi_dependency_task.yaml
```

### 4. Simple Test (`simple_test.yaml`)

A basic test task for verifying Corebrum functionality.

**Features:**
- Minimal configuration
- Quick execution
- Good for testing system setup

**Usage:**
```bash
corebrum submit --file task_definitions/general/simple_test.yaml
```

### 5. Very Simple Test (`very_simple_test.yaml`)

The most basic possible task definition.

**Features:**
- Absolute minimal configuration
- Fastest execution
- Perfect for initial testing

**Usage:**
```bash
corebrum submit --file task_definitions/general/very_simple_test.yaml
```

## Key Features Demonstrated

### External Code Sources
- **Git repositories**: Load code from version control
- **URLs**: Fetch code from remote sources
- **Mixed sources**: Combine different source types

### Task Definition Formats
- **YAML format**: Human-readable, easy to edit
- **JSON format**: Machine-readable, programmatically generated

### Advanced Configuration
- **Multiple dependencies**: Complex input/output relationships
- **Conditional execution**: Different code paths based on inputs
- **Error handling**: Graceful failure management

## Use Cases

### Testing and Validation
- **System testing**: Verify Corebrum installation and configuration
- **Development**: Test new features and configurations
- **Debugging**: Isolate and troubleshoot issues

### Learning and Examples
- **Getting started**: Learn Corebrum concepts with simple examples
- **Best practices**: See recommended patterns and configurations
- **Reference**: Use as templates for your own tasks

### Integration Examples
- **External systems**: Connect to Git repositories and remote services
- **Complex workflows**: Handle multiple dependencies and data sources
- **Flexible execution**: Adapt to different runtime environments

## Best Practices

### Task Design
- **Start simple**: Begin with basic examples before complex configurations
- **Test incrementally**: Add complexity gradually
- **Document thoroughly**: Include clear descriptions and usage instructions

### Code Sources
- **Version control**: Use Git for code that changes over time
- **URLs**: Use for stable, external code sources
- **Embedded code**: Use for simple, self-contained examples

### Error Handling
- **Validate inputs**: Check all inputs before processing
- **Handle failures**: Provide meaningful error messages
- **Test edge cases**: Verify behavior with unusual inputs

## Troubleshooting

### Common Issues
- **Git access**: Ensure Git repositories are accessible
- **URL availability**: Verify remote URLs are reachable
- **Input validation**: Check that all required inputs are provided

### Testing
- **Start with simple tests**: Use `very_simple_test.yaml` first
- **Verify connectivity**: Test network access to external sources
- **Check permissions**: Ensure proper access to Git repositories

## Related Examples

- **Python tasks**: See `../python/` for Python-specific examples
- **Docker tasks**: See `../docker/` for containerized applications
- **Sequential pipelines**: See `../sequential/` for complex workflows
- **WASM tasks**: See `../wasm/` for high-performance computations
