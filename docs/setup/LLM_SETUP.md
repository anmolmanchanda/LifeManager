# LLM Setup Guide for LifeManager

This guide explains how to configure LLM (Large Language Model) services for AI-powered content processing in LifeManager.

## Overview

LifeManager uses AI/LLM services to:
- Automatically categorize content into PARA methodology (Projects, Areas, Resources, Archives)
- Extract actionable tasks from natural language input
- Suggest priorities and due dates
- Generate tags and cross-references
- Provide content summaries

## Supported Providers

### OpenAI (Recommended)
- **Model**: GPT-4 or GPT-3.5-turbo
- **Use Case**: Primary AI processing, categorization, task extraction
- **Setup**: Requires OpenAI API key

### Anthropic Claude (Future)
- **Model**: Claude-3 family
- **Use Case**: Alternative/backup AI processing
- **Setup**: Requires Anthropic API key

## Setup Instructions

### Environment Variables (Recommended)

Set your API keys as environment variables:

```bash
export OPENAI_API_KEY="your-actual-openai-api-key-here"
export CLAUDE_API_KEY="your-actual-claude-api-key-here"
```

### Configuration File (Alternative)

Create a configuration file in your home directory:

```bash
# Create config file
echo "your-actual-openai-api-key-here" > ~/.lifemanager_config
```

### Hardcoded Config (Development Only)

For development only, you can set the key directly in the code:

```swift
// In Config.swift (not Config.example.swift)
static let openAIKey = "your-actual-openai-api-key-here"
```

## Getting API Keys

### OpenAI API Key

## Current Status
- ✅ **Notes save successfully** to database
- ⚠️ **LLM processing temporarily disabled** (no API keys configured)
- ✅ **No more error dialogs** when adding notes

## LLM Service Implementation Status

### ✅ Fully Implemented Features:
- OpenAI GPT-3.5-turbo integration
- Claude 3 Sonnet integration  
- PARA categorization prompts
- Task extraction from content
- Priority suggestion algorithms
- Structured JSON response parsing
- Prompt logging and optimization tracking

### 🔧 Setup Required:

#### Option 1: OpenAI API (Recommended)
1. **Get API Key**: Visit https://platform.openai.com/api-keys
2. **Set Environment Variable**:
   ```bash
   export OPENAI_API_KEY="sk-your-api-key-here"
   ```
3. **Re-enable LLM processing** in `MainViewModel.swift`

#### Option 2: Anthropic Claude API  
1. **Get API Key**: Visit https://console.anthropic.com/
2. **Set Environment Variable**:
   ```bash
   export CLAUDE_API_KEY="sk-ant-your-api-key-here"
   ```
3. **Change provider** in `LLMService.swift`: `preferredProvider = .claude`
4. **Re-enable LLM processing** in `MainViewModel.swift`

## Re-enabling LLM Processing

### Step 1: Set API Key
Choose one:
```bash
# For OpenAI
export OPENAI_API_KEY="your-actual-openai-api-key-here"

# For Claude  
export CLAUDE_API_KEY="your-key-here"
```

### Step 2: Uncomment LLM Code
In `Sources/LifeManager/ViewModels/MainViewModel.swift`, replace the `processBlob` method:

```swift
private func processBlob(_ blob: Blob) async throws {
    print("🔧 PROCESS BLOB: Starting processing for blob ID: \(blob.id)")
    
    do {
        // Use LLM to categorize and extract tasks
        print("🔧 PROCESS BLOB: Calling LLM categorization...")
        let categorization = try await llmService.categorizePARA(content: blob.content)
        print("🔧 PROCESS BLOB: ✅ LLM categorization completed")
        
        print("🔧 PROCESS BLOB: Calling LLM task extraction...")
        let tasks = try await llmService.extractTasks(content: blob.content)
        print("🔧 PROCESS BLOB: ✅ LLM task extraction completed - found \(tasks.count) tasks")
        
        // Update blob with processing results
        print("🔧 PROCESS BLOB: Marking blob as processed...")
        let _ = try await blobRepository().markBlobAsProcessed(id: blob.id)
        print("🔧 PROCESS BLOB: ✅ Blob marked as processed")
        
        // Create extracted tasks
        for (index, taskData) in tasks.enumerated() {
            let task = LifeTask(
                blobId: blob.id,
                title: taskData["title"] as? String ?? "Untitled Task",
                description: taskData["description"] as? String,
                priority: TaskPriority(rawValue: taskData["priority"] as? String ?? "medium") ?? .medium,
                workPersonal: blob.workPersonal
            )
            
            print("🔧 PROCESS BLOB: Creating task \(index + 1): \(task.title)")
            let _ = try await taskRepository().createTask(task)
        }
        
        print("🔧 PROCESS BLOB: ✅ All processing completed successfully")
    } catch {
        print("🔧 PROCESS BLOB: ❌ LLM ERROR - \(error)")
        // Still mark as processed to avoid blocking note saving
        let _ = try await blobRepository().markBlobAsProcessed(id: blob.id)
        throw error
    }
}
```

### Step 3: Rebuild and Test
```bash
./build_app.sh
open LifeManager.app
```

## LLM Features Available

### 1. **PARA Categorization**
- Automatically categorizes notes as Projects, Areas, Resources, or Archives
- Suggests relevant areas and projects
- Extracts actionable tasks from content

### 2. **Task Extraction**  
- Identifies action items in natural language
- Sets appropriate priority levels
- Estimates duration and suggests due dates
- Tags tasks with relevant context

### 3. **Smart Processing**
- Work vs Personal classification
- Confidence scoring for AI decisions
- Structured prompt templates
- Performance logging and optimization

## Cost Estimates

### OpenAI GPT-3.5-turbo:
- **~$0.002 per note** (average 1000 tokens)
- **100 notes/month** = ~$0.20/month
- **1000 notes/month** = ~$2.00/month

### Anthropic Claude 3 Sonnet:
- **~$0.015 per note** (average 1000 tokens)  
- **100 notes/month** = ~$1.50/month
- **1000 notes/month** = ~$15.00/month

## Troubleshooting

### No API Key Error:
```
🔧 PROCESS BLOB: ❌ ERROR - Missing API key for LLM service
```
**Solution**: Set the `OPENAI_API_KEY` or `CLAUDE_API_KEY` environment variable

### Invalid Response Error:
```
🔧 PROCESS BLOB: ❌ ERROR - Invalid response from LLM service  
```
**Solution**: Check API key is valid and account has credits

### Network Error:
```
🔧 PROCESS BLOB: ❌ ERROR - Network error when calling LLM service
```
**Solution**: Check internet connection and API endpoint availability 