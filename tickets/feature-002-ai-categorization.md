# Feature 002: AI Categorization System

## Status: Not Started
**Priority:** High  
**Estimated Duration:** 3-4 days  
**Assigned To:** AI Development  
**Created:** June 9, 2024  

## Description

Implement the AI-powered categorization and tagging system that automatically processes text blobs and assigns appropriate categories, tags, and classifications.

## Requirements

### Core AI Functionality
- **Automatic Categorization:** Assign blobs to categories (Journal, Therapy, Task, Finance, Knowledge)
- **Tag Generation:** Extract and assign relevant tags from content
- **Work/Personal Classification:** Determine if content is work-related, personal, or both
- **Task Extraction:** Identify and extract actionable tasks from text
- **Priority Assignment:** Suggest priority levels for extracted tasks
- **Content Summarization:** Generate concise summaries for long content

### LLM Processing Pipeline
- Process blobs from inbox state
- Use Claude/OpenAI for content analysis
- Generate confidence scores for categorization
- Extract structured data from unstructured text
- Handle various content types and formats

### Technical Specifications
- **Categories:** Fixed set (Journal, Therapy, Task, Finance, Knowledge)
- **Tags:** Dynamic generation with deduplication
- **Priority Levels:** urgent, high, medium, low
- **Work/Personal:** Enum classification
- **Confidence Scoring:** 0.0 to 1.0 for categorization accuracy

### Database Integration
- Update `blob_categories` with AI classifications
- Create/link tags in `blob_tags` table
- Extract tasks to `tasks` table
- Store processing results with confidence scores
- Update blob processing status

## Acceptance Criteria

- [ ] AI accurately categorizes different content types
- [ ] Tag extraction covers key themes and topics
- [ ] Work/personal classification is reliable
- [ ] Task extraction identifies actionable items
- [ ] Priority assignment is contextually appropriate
- [ ] Summarization captures key points effectively
- [ ] Confidence scores reflect actual accuracy
- [ ] Processing handles edge cases gracefully
- [ ] Performance is acceptable for typical content volumes

## AI Prompts & Logic

### Categorization Prompt Template
```
Analyze the following text and categorize it into one or more of these categories:
- Journal: Personal thoughts, daily logs, reflections
- Therapy: Mental health notes, therapeutic insights
- Task: Action items, to-dos, project work
- Finance: Money-related content, transactions, budgets
- Knowledge: Learning notes, research, factual information

Text: [BLOB_CONTENT]

Response format: JSON with categories, confidence scores, reasoning
```

### Task Extraction Logic
- Identify action verbs and imperative statements
- Look for deadline indicators
- Estimate effort based on content complexity
- Assign contextual priority based on urgency cues

## Dependencies
- Feature 001: Input Processing Engine (prerequisite)
- Database schema with proper tables
- LLM API integration (Claude/OpenAI)
- Confidence scoring framework

## Notes
This is the core AI intelligence of the system. Quality of categorization directly impacts user experience and system effectiveness.

## Related Tickets
- Feature 001: Input Processing Engine (prerequisite)
- Feature 004: Search and Retrieval (depends on categorization)
- Feature 005: Task Management (depends on task extraction) 