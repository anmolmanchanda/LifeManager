# LifeManager User Guide

## Getting Started

### First Launch
When you first launch LifeManager, you'll be greeted with the authentication screen. For development and testing:

1. **Development Bypass**: Click "Enable Development Bypass" for immediate access
2. **Test Account**: Use `dev@lifemanager.local` with any password
3. **Force Create Account**: Use "Force Create Dev Account" if authentication fails

### Main Interface Overview

LifeManager's interface is organized around the PARA methodology with these main sections:

- **Inbox**: Process unstructured text input and new content
- **Calendar**: Advanced scheduling with AI-powered features
- **Projects**: Time-bound goals with specific outcomes
- **Areas**: Ongoing responsibilities and life domains
- **Resources**: Reference materials and knowledge assets
- **Archives**: Inactive content from other categories

## Core Features

### 1. Natural Language Input

#### Text Processing
The heart of LifeManager is its natural language processing capability:

1. **Input Area**: Large text area at the top of the main window
2. **Natural Language**: Type or paste any unstructured text
3. **AI Processing**: Click "Process with AI" to analyze and categorize content
4. **Automatic Organization**: Content is automatically sorted into PARA categories

#### Example Inputs
```
"Meeting with Sarah tomorrow at 2pm about the website redesign project. Need to prepare mockups and gather feedback on the current design. Also remember to book dentist appointment for next week."
```

This would automatically:
- Create a calendar event for the meeting
- Extract tasks for mockup preparation
- Create a reminder for the dentist appointment
- Categorize items appropriately (work vs personal)

### 2. Advanced Calendar System

#### Calendar Views
- **Day View**: Detailed hourly schedule (24-hour format starting at midnight)
- **Week View**: 7-day overview with cross-day task management
- **Month View**: High-level planning with project duration visualization

#### Smart Scheduling Features

##### Buffer Management
- **5-Minute Rule**: Automatic 5-minute buffer per hour of scheduled work
- **Overflow Protection**: Tasks automatically move to parking lot when buffers are violated
- **Visual Indicators**: Buffer time shown with distinct styling

##### Parking Lot System
- **AI Prioritization**: Tasks ranked by importance using LLM analysis
- **Drag & Drop Scheduling**: Drag tasks from parking lot to calendar slots
- **Smart Recommendations**: AI suggests optimal scheduling times

##### Toggl Integration
- **Real-Time Sync**: Live synchronization with Toggl time tracking
- **Auto-Bumping**: Automatic rescheduling when actual time exceeds planned time
- **Conflict Resolution**: Intelligent handling of schedule conflicts

#### Using the Calendar

##### Scheduling Tasks
1. **From Parking Lot**: Drag tasks from the right sidebar to calendar slots
2. **Direct Creation**: Right-click on calendar slots to create new events
3. **AI Suggestions**: Use "Quick Schedule" for AI-recommended time slots

##### Managing Events
- **Edit**: Double-click events to modify details
- **Reschedule**: Drag events to new time slots
- **Context Menu**: Right-click for additional options
- **Buffer Adjustment**: Manually add buffer time around events

### 3. PARA Organization System

#### Projects
**Definition**: Time-bound efforts with specific outcomes

##### Creating Projects
1. Navigate to Projects section
2. Click "New Project"
3. Define clear outcome and deadline
4. Assign to relevant Area
5. Add tasks and resources

##### Project Lifecycle
- **Planning**: Initial setup and task definition
- **Active**: Currently being worked on
- **On Hold**: Temporarily paused
- **Completed**: Successfully finished
- **Archived**: Moved to archives after completion

#### Areas
**Definition**: Ongoing responsibilities with standards to maintain

##### Default Areas
LifeManager includes 10 pre-configured areas:
1. Health & Fitness
2. Career & Professional
3. Finances
4. Learning & Education
5. Relationships & Social
6. Home & Living
7. Hobbies & Interests
8. Travel & Adventure
9. Creativity & Projects
10. Spirituality & Reflection

##### Managing Areas
- **Standards**: Define what "good" looks like for each area
- **Projects**: Link time-bound projects to ongoing areas
- **Resources**: Collect reference materials for each area
- **Review**: Regular review of area standards and progress

#### Resources
**Definition**: Reference materials and knowledge assets

##### Resource Types
- Research Papers
- Articles
- Videos
- Books
- Guides
- Recipes
- Templates
- Tools

##### Organizing Resources
- **By Type**: Group similar resource types together
- **By Area**: Organize resources within life areas
- **By Project**: Link resources to specific projects
- **Tags**: Use tags for cross-cutting themes

#### Archives
**Definition**: Inactive items preserved for reference

##### What Gets Archived
- Completed projects (after 30 days)
- Outdated resources
- Inactive areas
- Cancelled tasks

##### Archive Management
- **Automatic Archiving**: System automatically archives completed items
- **Manual Archiving**: Archive items manually when no longer needed
- **Search Archives**: Full-text search across archived content
- **Restore**: Bring archived items back to active status

### 4. Task Management

#### Task States
- **Inbox**: Newly created, unprocessed tasks
- **Todo**: Ready to be worked on
- **In Progress**: Currently being worked on
- **Completed**: Successfully finished
- **Cancelled**: No longer relevant

#### Task Features
- **Priority Scoring**: AI-powered priority assessment (1-10)
- **Duration Estimation**: Automatic estimation of task duration
- **Due Date Analysis**: Smart parsing of temporal language
- **Context Awareness**: Work/personal classification
- **Project Linking**: Automatic linking to relevant projects

#### Working with Tasks
1. **Creation**: Tasks created automatically from natural language input
2. **Scheduling**: Drag tasks to calendar or use AI scheduling suggestions
3. **Progress Tracking**: Update task status as work progresses
4. **Completion**: Mark tasks complete when finished

### 5. Search and Filtering

#### Search Capabilities
- **Full-Text Search**: Search across all content types
- **PARA Filtering**: Filter by Projects, Areas, Resources, Archives
- **Work/Personal**: Separate work and personal content
- **Date Ranges**: Filter by creation date, due date, completion date
- **Tags**: Filter by tags and categories

#### Advanced Search
```
Search Examples:
- "meeting notes" - Find all meeting-related content
- "project:website" - Find content related to website project
- "area:health" - Find all health-related items
- "tag:urgent" - Find all urgent items
- "work personal:false" - Find only personal items
```

## Productivity Workflows

### 1. Daily Workflow

#### Morning Planning (5 minutes)
1. **Review Calendar**: Check today's scheduled events
2. **Process Inbox**: Handle any new items from yesterday
3. **Parking Lot Review**: Prioritize unscheduled tasks
4. **Buffer Check**: Ensure realistic scheduling with adequate buffers

#### During the Day
1. **Time Tracking**: Use Toggl integration for actual time tracking
2. **Task Updates**: Update task status as work progresses
3. **Quick Capture**: Add new items to inbox as they arise
4. **Schedule Adjustments**: Let auto-bumping handle schedule changes

#### Evening Review (10 minutes)
1. **Completion Review**: Mark completed tasks and events
2. **Tomorrow's Planning**: Review and adjust tomorrow's schedule
3. **Inbox Processing**: Process any items added during the day
4. **Reflection**: Note any insights or lessons learned

### 2. Weekly Workflow

#### Weekly Review (30 minutes)
1. **Project Progress**: Review progress on active projects
2. **Area Standards**: Check if area standards are being maintained
3. **Resource Curation**: Review and organize new resources
4. **Archive Cleanup**: Archive completed projects and outdated resources
5. **Next Week Planning**: Plan major tasks and events for the coming week

### 3. Monthly Workflow

#### Monthly Planning (60 minutes)
1. **PARA Audit**: Comprehensive review of PARA organization
2. **Project Pipeline**: Review project completion rates and plan new projects
3. **Area Evolution**: Update area standards and priorities
4. **Resource Review**: Prune unused resources and identify gaps
5. **System Optimization**: Review and optimize workflows and processes

## Tips and Best Practices

### 1. Effective Input Processing
- **Brain Dump**: Regularly dump thoughts and ideas into the inbox
- **Context Switching**: Process different types of content in batches
- **Natural Language**: Write naturally - the AI will parse and organize
- **Regular Processing**: Process inbox items daily to prevent buildup

### 2. Calendar Management
- **Realistic Scheduling**: Trust the buffer system to prevent overbooking
- **Flexible Planning**: Leave room for unexpected tasks and interruptions
- **Time Blocking**: Use calendar blocking for focused work periods
- **Review and Adjust**: Regularly review actual vs planned time

### 3. PARA Organization
- **Clear Boundaries**: Maintain clear distinctions between PARA categories
- **Regular Reviews**: Weekly and monthly reviews keep the system current
- **Consistent Naming**: Use consistent naming conventions for projects and areas
- **Archive Regularly**: Don't let inactive items clutter active categories

### 4. Task Management
- **Specific Outcomes**: Define clear, specific outcomes for tasks
- **Appropriate Sizing**: Break large tasks into smaller, manageable pieces
- **Context Grouping**: Group similar tasks for efficient batch processing
- **Priority Focus**: Focus on high-priority tasks first

## Troubleshooting

### Common Issues

#### Authentication Problems
- **Invalid Credentials**: Use "Force Create Dev Account" button
- **Magic Links Not Working**: Try manual callback processing
- **Development Bypass**: Use development bypass for immediate access

#### Calendar Issues
- **Events Not Appearing**: Check real-time sync and refresh calendar
- **Drag & Drop Not Working**: Ensure proper gesture coordination
- **Context Menus Missing**: Verify right-click functionality

#### Performance Issues
- **Slow Loading**: Check internet connection and Supabase status
- **High Memory Usage**: Restart application if memory usage is high
- **API Rate Limits**: Wait for rate limit reset (Toggl API has 3-second delays)

#### Data Issues
- **Missing Content**: Check archive section for moved items
- **Duplicate Items**: Use search to identify and merge duplicates
- **Sync Problems**: Force refresh or restart application

### Getting Help
- **Debug Logs**: Check console output for error messages
- **System Status**: Verify Supabase and external service status
- **Documentation**: Refer to feature-specific documentation
- **Community**: Join the LifeManager community for support

## Advanced Features

### 1. Prompt Engineering
- **Custom Prompts**: Modify AI prompts for better categorization
- **Template Management**: Create and manage prompt templates
- **A/B Testing**: Test different prompts for optimal results

### 2. API Integration
- **Toggl Setup**: Configure Toggl API for time tracking
- **OpenAI Configuration**: Set up OpenAI API for LLM processing
- **Webhook Integration**: Set up webhooks for external integrations

### 3. Data Export
- **Backup Creation**: Regular backups of all data
- **Export Formats**: Export data in various formats (JSON, CSV, Markdown)
- **Migration Tools**: Tools for migrating data between systems

This user guide provides a comprehensive overview of LifeManager's features and workflows. For specific technical details, refer to the feature-specific documentation in the docs/ folder. 