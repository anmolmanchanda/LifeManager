# LifeManager 🚀

**AI-Powered Personal Knowledge Management & Productivity System for macOS**

LifeManager is a native macOS application that revolutionizes personal productivity through intelligent text processing, PARA methodology implementation, and AI-driven task management. Built specifically for software engineers and knowledge workers who need a powerful, local-first solution for organizing their digital life.

---

## 🌟 Core Features

### 🧠 AI-Powered Text Processing
- **Natural Language Understanding**: Intelligent categorization of text input using advanced LLM processing
- **Automatic Task Extraction**: Smart detection and extraction of actionable items from free-form text
- **Content Summarization**: AI-generated summaries for large text blocks
- **Smart Date/Time Analysis**: Automatic parsing of temporal information and deadlines
- **Priority Assessment**: Intelligent task prioritization based on content analysis

### 📋 PARA Methodology Implementation
- **Projects**: Time-bound objectives with specific outcomes
- **Areas**: Ongoing responsibilities requiring maintenance
- **Resources**: Future reference materials and knowledge storage
- **Archive**: Completed or inactive items with full history

### 📅 Advanced Calendar System
- **Multi-View Interface**: Day, Week, and Month views with intelligent event display
- **Toggl Integration**: Real-time time tracking with project color coding
- **Buffer Management**: Smart 5-minute/hour buffer rules for realistic scheduling
- **Auto-Bumping**: Cascade rescheduling when conflicts arise
- **LLM-Powered Parking Lot**: Intelligent task importance analysis and recommendations
- **Visual Cues**: Color-coded entries with today highlighting (green for current day)
- **Quick Navigation**: Centered "Today" button for instant date jumping

### 🔄 Real-Time Sync & Storage
- **PostgreSQL Backend**: Robust database with comprehensive audit trails
- **Supabase Integration**: Real-time synchronization across devices
- **Version History**: Complete change tracking for all content
- **Offline Support**: Local-first architecture with sync when available

### 🎯 Task Management
- **Smart Extraction**: AI-powered task identification from natural language
- **Duration Estimation**: Intelligent time requirements prediction
- **Context Preservation**: Links between tasks and original content
- **Multiple Views**: List, calendar, timeline, and kanban-style organization
- **Work/Personal Separation**: Dedicated modes with content filtering

### 🏷️ Dynamic Organization
- **Auto-Tagging**: AI-generated tags based on content analysis
- **Smart Search**: Natural language queries across all content
- **Mind Mapping**: Visual relationship exploration (planned)
- **Timeline View**: Chronological content organization

---

## 🆕 Recent Enhancements (v1.0)

### Calendar System Overhaul
- **Enhanced Day View**: Doubled vertical spacing between hours (8px gaps)
- **Centered Text**: All time entries now center-aligned in blocks
- **Today Highlighting**: Green color coding for current date entries
- **Quick Navigation**: Centered "Today" button for instant date access
- **Toggl Color Integration**: Week/Month view dots match project colors
- **Full-Width Events**: Single events use complete available width
- **Smart Overflow**: Dot indicators (+N) when multiple events exceed display limits

### Multiple Instance Prevention
- **Nuclear Cleanup Process**: 10-stage elimination system for duplicate instances
- **Instance Lock Management**: PID-based process validation and lock files
- **System Cache Clearing**: Comprehensive LaunchServices and Dock cache reset
- **Process Monitoring**: Advanced detection of running LifeManager instances

### Enhanced PARA Processing
- **Context Menu Integration**: Delete, complete, archive, and schedule options
- **Auto-Archive System**: Completed tasks automatically move to Archive tab
- **Improved Task Management**: Enhanced deletion and completion workflows
- **Sidebar Layout**: Perfect spacing and organization maintenance

### LLM Service Improvements
- **Intelligent Categorization**: Enhanced blob assignment to PARA categories
- **Task Enhancement**: Automated priority scoring and duration estimation
- **Date/Time Analysis**: Smart temporal information extraction
- **Sub-Category Handling**: Improved project and area assignment logic

---

## 🗂️ Project Structure

```
LifeManager/
├── Sources/LifeManager/
│   ├── App/                    # Application lifecycle and configuration
│   ├── Models/                 # Data models (Blob, Task, PARA categories)
│   ├── Services/               # Core services (LLM, Supabase, Toggl, Buffer)
│   ├── ViewModels/             # MVVM architecture view models
│   ├── Views/                  # SwiftUI views and components
│   ├── Repositories/           # Data access layer
│   ├── Utils/                  # Utility functions and extensions
│   ├── Extensions/             # Swift extensions
│   └── Resources/              # Assets and configuration files
├── Tests/                      # Unit and integration tests
├── supabase/migrations/        # Database schema and migrations
├── doc/                        # Project documentation
├── tickets/                    # Feature tickets and planning
└── prompts/templates/          # LLM prompt templates
```

---

## 🚀 Quick Start

### Prerequisites
- macOS 13.0+ (Ventura or later)
- Swift 5.9+
- PostgreSQL 15+ (local or remote)
- Supabase account (for sync functionality)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/LifeManager.git
   cd LifeManager
   ```

2. **Build and run:**
   ```bash
   ./run.sh
   ```

3. **First launch setup:**
   - The app will create a development account automatically
   - Sample PARA data will be generated for exploration
   - Supabase connection will be established (if configured)

### Configuration
- Update `SupabaseService.swift` with your Supabase credentials
- Configure Toggl API token in `TogglService.swift` for time tracking
- Customize LLM endpoints in `LLMService.swift` for AI processing

---

## 🔧 Advanced Features

### Buffer Management System
- **5-Minute Rule**: Automatic 5-minute buffers between short events
- **Hourly Rule**: Full hour buffers for events longer than 2 hours
- **Cascade Rescheduling**: Intelligent conflict resolution with automatic bumping
- **Real-Time Integration**: Live Toggl data integration for actual vs. planned time

### Parking Lot Intelligence
- **LLM Analysis**: AI-powered importance scoring for unscheduled tasks
- **Smart Recommendations**: Contextual suggestions for task scheduling
- **Decision Modals**: User-friendly interfaces for task management decisions
- **Importance Threshold**: Configurable sensitivity for task filtering

### Authentication & Security
- **Development Bypass**: Automatic account creation for development
- **Magic Link Support**: Email-based authentication with URL scheme handling
- **Session Management**: Secure token handling and refresh mechanisms
- **Instance Security**: Multi-layer protection against duplicate app instances

---

## 🛣️ Development Roadmap

### Version 1.5 (Q2 2024)
- **Enhanced Mind Mapping**: Visual relationship exploration with interactive diagrams
- **Advanced Search**: Semantic search with AI-powered query understanding
- **Export System**: Comprehensive data export to multiple formats
- **Plugin Architecture**: Extensible system for third-party integrations
- **Collaboration Features**: Shared projects and real-time editing
- **Mobile Companion**: iOS app with sync capabilities

### Version 2.0 (Q3 2024)
- **Multi-User Support**: Teams and organization-level features
- **Advanced Analytics**: Detailed productivity insights and reporting
- **Workflow Automation**: Custom rules and automated actions
- **API Access**: RESTful API for external integrations
- **Advanced AI**: Custom model fine-tuning for personal patterns
- **Cross-Platform**: Windows and Linux desktop applications

### Version 3.0 (Q4 2024)
- **Enterprise Features**: SSO, compliance, and enterprise security
- **Advanced Integrations**: Deep integration with popular productivity tools
- **Custom Dashboards**: Personalized productivity overview interfaces
- **Machine Learning**: Predictive task scheduling and habit analysis
- **Voice Interface**: Speech-to-text input and voice commands
- **AR/VR Support**: Immersive productivity environments

---

## 🧪 Testing & Development

### Running Tests
```bash
swift test
```

### Development Mode
```bash
# Enable development bypass authentication
export LIFEMANAGER_DEV_MODE=true
./run.sh
```

### Debug Features
- Comprehensive logging with prefixed messages
- Real-time Supabase sync monitoring
- URL scheme testing capabilities
- Development account auto-creation

---

## 📊 Project Statistics

| Metric | Value |
|--------|-------|
| **Swift Source Files** | 20 files |
| **Total Lines of Code** | ~15,924 lines |
| **Core Services** | 8 major services |
| **View Components** | 25+ SwiftUI views |
| **Database Tables** | 12 core tables |
| **Migration Files** | 15+ schema migrations |
| **Test Coverage** | Expanding (unit tests) |
| **Supported macOS** | 13.0+ (Ventura+) |
| **Development Time** | 6+ months active development |
| **Git Commits** | 100+ commits |

### Architecture Highlights
- **MVVM Pattern**: Clean separation of concerns
- **Repository Pattern**: Abstracted data access layer
- **Service-Oriented**: Modular service architecture
- **SwiftUI Native**: Modern declarative UI framework
- **PostgreSQL**: Robust relational database
- **Real-Time Sync**: Supabase-powered synchronization

---

## 🏷️ Features List

### Core Functionality
- ✅ **Natural Language Input** - Free-form text processing
- ✅ **AI Categorization** - Automatic PARA classification
- ✅ **Task Extraction** - Smart actionable item detection
- ✅ **Real-Time Sync** - Cross-device synchronization
- ✅ **Version History** - Complete audit trail
- ✅ **Smart Search** - Natural language queries
- ✅ **Work/Personal Modes** - Content filtering and organization

### Calendar & Time Management
- ✅ **Multi-View Calendar** - Day, Week, Month views
- ✅ **Toggl Integration** - Real-time time tracking
- ✅ **Buffer Management** - Intelligent scheduling buffers
- ✅ **Auto-Bumping** - Cascade conflict resolution
- ✅ **Color Coding** - Visual project identification
- ✅ **Today Highlighting** - Current date emphasis
- ✅ **Quick Navigation** - Instant date jumping

### Organization & Productivity
- ✅ **PARA Method** - Projects, Areas, Resources, Archive
- ✅ **Dynamic Tagging** - AI-generated content tags
- ✅ **Priority Scoring** - Intelligent task prioritization
- ✅ **Context Preservation** - Link tasks to source content
- ✅ **Archive System** - Completed item management
- ✅ **Inbox Processing** - Efficient content triage

### Technical Features
- ✅ **Instance Prevention** - Multi-layer duplicate protection
- ✅ **URL Scheme Support** - Magic link authentication
- ✅ **Development Bypass** - Streamlined testing workflow
- ✅ **Comprehensive Logging** - Detailed debugging information
- ✅ **Error Handling** - Robust error recovery
- ✅ **Performance Optimization** - Efficient data processing

---

## 🤝 Contributing

LifeManager is actively developed with a focus on user experience and performance. Key areas for contribution:

1. **AI Enhancement**: Improving LLM processing accuracy and speed
2. **UI/UX**: Refining the native macOS experience
3. **Performance**: Optimizing database queries and UI rendering
4. **Testing**: Expanding test coverage and automation
5. **Documentation**: Improving user guides and API documentation

---

## 📄 License

LifeManager is released under the MIT License. See `LICENSE` file for details.

---

## 🙏 Acknowledgments

- **PARA Method**: Created by Tiago Forte for knowledge organization
- **Supabase**: Real-time database and authentication platform
- **Toggl**: Time tracking integration and project management
- **OpenAI/Anthropic**: LLM processing capabilities
- **SwiftUI**: Modern declarative UI framework

---

**Built with ❤️ for productivity enthusiasts and knowledge workers**

*Last updated: June 2024 | Version 1.0 | Active Development* 