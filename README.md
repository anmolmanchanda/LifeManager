# LifeManager 🚀

**AI-Powered Personal Knowledge Management & Productivity System for macOS**

LifeManager is a native macOS application that revolutionizes personal productivity through intelligent text processing, PARA methodology implementation, and AI-driven task management. Built specifically for software engineers and knowledge workers who need a powerful, local-first solution for organizing their digital life.

---

## 🚀 **Comprehensive Feature Overview**

> **LifeManager combines AI-powered productivity with intuitive design to create the ultimate personal knowledge management system for macOS users.**

### **🧠 AI & Intelligence**
| Feature | Description | Status |
|---------|-------------|--------|
| **Natural Language Understanding** | Advanced LLM processing for intelligent text categorization | ✅ **Production Ready** |
| **Smart Task Extraction** | Automatic detection of actionable items from free-form text | ✅ **Production Ready** |
| **Priority Assessment** | AI-driven task prioritization based on content analysis | ✅ **Production Ready** |
| **Content Summarization** | Automated summaries for large text blocks | ✅ **Production Ready** |
| **Date/Time Parsing** | Smart temporal information extraction and deadline detection | ✅ **Production Ready** |
| **Importance Scoring** | LLM-powered task importance analysis with threshold filtering | ✅ **Production Ready** |

### **📋 PARA Methodology & Organization**
| Feature | Description | Status |
|---------|-------------|--------|
| **Projects Management** | Time-bound objectives with specific outcomes | ✅ **Production Ready** |
| **Areas Tracking** | Ongoing responsibilities requiring maintenance | ✅ **Production Ready** |
| **Resources Storage** | Future reference materials and knowledge organization | ✅ **Production Ready** |
| **Archive System** | Completed/inactive items with complete history | ✅ **Production Ready** |
| **Auto-Tagging** | AI-generated tags based on content analysis | ✅ **Production Ready** |
| **Smart Search** | Natural language queries across all content | ✅ **Production Ready** |

### **📅 Advanced Calendar System**
| Feature | Description | Status |
|---------|-------------|--------|
| **Multi-View Interface** | Day, Week, Month views with intelligent event display | ✅ **Production Ready** |
| **Toggl Integration** | Real-time time tracking with automatic project color coding | ✅ **Production Ready** |
| **Buffer Management** | Smart 5-minute/hour buffer rules for realistic scheduling | ✅ **Production Ready** |
| **Auto-Bumping** | Cascade rescheduling with intelligent conflict resolution | ✅ **Production Ready** |
| **Parking Lot System** | LLM-powered unscheduled task analysis and recommendations | ✅ **Production Ready** |
| **Visual Enhancements** | Color-coded entries, today highlighting, full-width events | ✅ **Production Ready** |
| **Quick Navigation** | Instant date jumping with centered "Today" button | ✅ **Production Ready** |

### **🔄 Data & Synchronization**
| Feature | Description | Status |
|---------|-------------|--------|
| **PostgreSQL Backend** | Robust database with comprehensive audit trails | ✅ **Production Ready** |
| **Supabase Integration** | Real-time synchronization across devices | ✅ **Production Ready** |
| **Version History** | Complete change tracking for all content modifications | ✅ **Production Ready** |
| **Offline Support** | Local-first architecture with sync when available | ✅ **Production Ready** |
| **Email Notifications** | Backup notification system (30-minute delay) | ✅ **Production Ready** |
| **Instance Prevention** | Multi-layer protection against duplicate app instances | ✅ **Production Ready** |

### **🎯 Task & Productivity Management**
| Feature | Description | Status |
|---------|-------------|--------|
| **Smart Scheduling** | AI-powered automatic task scheduling and time slot suggestions | ✅ **Production Ready** |
| **Drag & Drop** | Intuitive task scheduling from parking lot to calendar views | ✅ **Production Ready** |
| **Duration Estimation** | Intelligent time requirements prediction | ✅ **Production Ready** |
| **Context Preservation** | Links between tasks and original content source | ✅ **Production Ready** |
| **Work/Personal Modes** | Dedicated filtering and organization by context | ✅ **Production Ready** |
| **Timeline Views** | Multiple perspectives: list, calendar, timeline organization | ✅ **Production Ready** |

### **🔧 Technical Excellence**
| Feature | Description | Status |
|---------|-------------|--------|
| **Native macOS** | SwiftUI-based with native performance and design | ✅ **Production Ready** |
| **Full Screen Support** | Automatically opens in full screen for immersive experience | ✅ **Production Ready** |
| **MVVM Architecture** | Clean separation of concerns with modular service architecture | ✅ **Production Ready** |
| **Rate Limiting** | Smart API throttling to prevent 429 errors (2-second intervals) | ✅ **Production Ready** |
| **Error Handling** | Comprehensive error recovery and logging system | ✅ **Production Ready** |
| **Development Bypass** | Streamlined testing workflow with automatic account creation | ✅ **Production Ready** |

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

## 🛣️ **Development Roadmap**

### **Version 1.5** (Q2 2024) - *Enhanced Intelligence*
- **🧠 Enhanced Mind Mapping**: Visual relationship exploration with interactive diagrams
- **🔍 Advanced Search**: Semantic search with AI-powered query understanding  
- **📤 Export System**: Comprehensive data export to multiple formats (PDF, Markdown, JSON)
- **🔌 Plugin Architecture**: Extensible system for third-party integrations
- **👥 Collaboration Features**: Shared projects and real-time editing capabilities
- **📱 Mobile Companion**: iOS app with full sync capabilities

### **Version 2.0** (Q3 2024) - *Enterprise & Analytics*
- **🏢 Multi-User Support**: Teams and organization-level features
- **📊 Advanced Analytics**: Detailed productivity insights and reporting dashboards
- **⚡ Workflow Automation**: Custom rules and automated actions
- **🔗 API Access**: RESTful API for external integrations
- **🤖 Advanced AI**: Custom model fine-tuning for personal productivity patterns
- **💻 Cross-Platform**: Windows and Linux desktop applications

### **Version 3.0** (Q4 2024) - *Next-Generation Productivity*
- **🏛️ Enterprise Features**: SSO, compliance, and enterprise security
- **🔄 Advanced Integrations**: Deep integration with popular productivity tools
- **📈 Custom Dashboards**: Personalized productivity overview interfaces
- **🧠 Machine Learning**: Predictive task scheduling and habit analysis
- **🎤 Voice Interface**: Speech-to-text input and voice commands
- **🥽 AR/VR Support**: Immersive productivity environments

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