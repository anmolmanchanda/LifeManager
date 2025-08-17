# LifeManager Architecture Reference

## Core Design Pattern
- **MVVM Architecture**: Strict separation between Views, ViewModels, and Models
- **Service-Oriented**: Business logic encapsulated in dedicated service classes
- **Real-time Sync**: Supabase real-time subscriptions for live data updates
- **AI-Powered**: LLM integration for natural language processing and PARA categorization
- **Intelligent Automation**: Comprehensive AI learning and cross-service orchestration
- **Production Monitoring**: Real-time performance monitoring and automatic optimization

## Key Components

### Services Layer (`Sources/LifeManager/Services/`)

#### Core AI & LLM Services
- **LLMServiceCoordinator**: Unified coordinator for all LLM operations (289 lines)
  - **LLMConfigurationService**: API key management and provider configuration
  - **LLMPromptService**: Template management and prompt generation  
  - **LLMCommunicationService**: Direct API communication with providers
  - **LLMProcessingService**: High-level AI processing workflows
- **EmbeddingsService**: OpenAI embeddings with memory management and caching (929 lines)
- **ContextMemoryService**: Active context memory with sliding window management
- **ContextualPARAEngine**: AI-powered PARA categorization engine
- **PersonalRulesService**: User preference and rule management

#### Intelligent Automation Services
- **AutomationOrchestrator** (1,000+ lines): Central coordination hub for all automation services
- **AILearningEngine** (1,200+ lines): Advanced AI pattern recognition and continuous learning
- **IntelligentReschedulingService**: AI-powered task rescheduling with confidence scoring
- **AdvancedNotificationService** (871 lines): Multi-channel escalation system (SMS, email, webhook)
- **TaskDependencyService** (900+ lines): Comprehensive dependency validation and cascade analysis
- **ExternalCalendarIntegrationService** (562 lines): EventKit calendar integration with conflict detection
- **PerformanceMonitoringService** (1,000+ lines): System monitoring and automatic optimization

#### Core Infrastructure Services
- **SupabaseService**: Database operations and authentication (492 lines)
- **CalendarOrchestrationService**: Intelligent scheduling with buffer management
- **TogglService**: Time tracking integration (614 lines)
- **NotificationService**: Smart notifications and decision modals

### User Interface Layer (`Sources/LifeManager/Views/`)

#### Intelligent Automation UI
- **AutomationDashboardView** (1,100+ lines): Comprehensive monitoring and control interface
- **EnhancedFocusView** (1,200+ lines): AI-powered focus view with intelligent prioritization
- **Real-time Status Monitoring**: Live system health and performance indicators
- **AI Confidence Displays**: Visual representation of AI decision confidence
- **Interactive Controls**: Service management, optimization triggers, and user feedback
- **Learning Insights Interface**: Real-time display of AI insights and patterns

#### Core Application Views
- **MainView**: Primary application interface with navigation
- **TaskView**: Task management with PARA methodology integration
- **CalendarView**: Calendar interface with intelligent scheduling
- **SettingsView**: Configuration and automation control settings
  - User working hours and focus block integration
  - Task dependency validation and conflict prevention
  - 24-hour undo/override functionality with full audit trail
  - Multi-factor scoring: time preferences, priority alignment, calendar conflicts
- **PriorityIntelligenceEngine**: ML-based priority assessment with context awareness (642 lines)
  - Real-time priority scoring using multiple factors
  - Pattern recognition for task importance
  - Integration with rescheduling decisions
- **ProactiveNotificationEngine**: Comprehensive notification system (901 lines)
  - 10 notification types: reminders, summaries, contextual alerts, achievements
  - Customizable thresholds and user preference integration
  - Proactive nudges for stagnant tasks (3-day default)
  - Daily/weekly/monthly summary notifications

### ViewModels (`Sources/LifeManager/ViewModels/`)
- **MainViewModel**: Central app state and navigation coordinator (3,125 lines)
- **CalendarViewModel**: Calendar-specific state management
- **ContextualPARAViewModel**: PARA methodology implementation

### Models (`Sources/LifeManager/Models/`)
- **CoreModels**: User, Task, Project, Area, Resource, Archive entities
- **PARAModels**: PARA framework-specific data structures
- **ContentModels**: Blob and content type definitions
- **ContextualPARAModels**: AI-enhanced PARA categorization models
- **CalendarModels**: Event, scheduling, and calendar-related models
- **IntelligentSchedulingModels**: Task dependencies, scheduling patterns, priority intelligence (591 lines)

## Database Architecture
- **PostgreSQL + Supabase**: 18+ core tables with real-time subscriptions
- **Migration System**: Structured schema evolution in `supabase/migrations/`
- **PARA Framework**: Projects, Areas, Resources, Archives with full audit trail
- **Embeddings Support**: Vector storage for semantic search capabilities

## Configuration System
- **API Keys**: Template-based setup with `config.txt.template`
- **Environment Variables**: OPENAI_API_KEY, SUPABASE_URL, CLAUDE_API_KEY
- **Development Mode**: Built-in dev account (`dev@lifemanager.local`)

## MCP Integration
- **35 MCP Servers Configured**: Comprehensive tool coverage
- **Core Services**: Sequential thinking, Postgres, Filesystem, Task Master AI
- **Development Tools**: Git, GitHub, Browser automation
- **Configuration**: `~/.config/claude/mcp.json`
- **Setup Scripts**: Automated installation and configuration