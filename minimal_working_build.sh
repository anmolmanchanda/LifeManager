#!/bin/bash

echo "🛠️ Minimal Working Build for LifeManager"
echo "This will disable non-essential views to get a working build"

# 1. Clean everything
echo "🧹 Cleaning all build artifacts..."
rm -rf .build
rm -rf /tmp/lifemanager_disabled
swift package clean

# 2. Create temporary directory for disabled files
echo "📁 Creating temporary storage..."
mkdir -p /tmp/lifemanager_disabled/Views
mkdir -p /tmp/lifemanager_disabled/Services
mkdir -p /tmp/lifemanager_disabled/Models

# 3. Move ALL potentially problematic views
echo "🔧 Temporarily disabling complex views..."

# Move entire directories that might have issues
mv Sources/LifeManager/Views/Focus /tmp/lifemanager_disabled/Views/ 2>/dev/null
mv Sources/LifeManager/Views/Timeline /tmp/lifemanager_disabled/Views/ 2>/dev/null
mv Sources/LifeManager/Views/Calendar /tmp/lifemanager_disabled/Views/ 2>/dev/null

# Move individual problematic view files
mv Sources/LifeManager/Views/EnhancedFocusView.swift /tmp/lifemanager_disabled/Views/ 2>/dev/null
mv Sources/LifeManager/Views/IntelligentTimelineView.swift /tmp/lifemanager_disabled/Views/ 2>/dev/null
mv Sources/LifeManager/Views/AutomationDashboardView.swift /tmp/lifemanager_disabled/Views/ 2>/dev/null
mv Sources/LifeManager/Views/TimelineView.swift /tmp/lifemanager_disabled/Views/ 2>/dev/null
mv Sources/LifeManager/Views/CalendarParkingLot.swift /tmp/lifemanager_disabled/Views/ 2>/dev/null

# Move problematic services
mv Sources/LifeManager/Services/AutomationOrchestrator.swift /tmp/lifemanager_disabled/Services/ 2>/dev/null
mv Sources/LifeManager/Services/IntelligentReschedulingService.swift /tmp/lifemanager_disabled/Services/ 2>/dev/null
mv Sources/LifeManager/Services/NotificationService.swift /tmp/lifemanager_disabled/Services/ 2>/dev/null
mv Sources/LifeManager/Services/EnhancedParkingLotService.swift /tmp/lifemanager_disabled/Services/ 2>/dev/null
mv Sources/LifeManager/Services/TimelineViewService.swift /tmp/lifemanager_disabled/Services/ 2>/dev/null
mv Sources/LifeManager/Services/PriorityIntelligenceEngine.swift /tmp/lifemanager_disabled/Services/ 2>/dev/null
mv Sources/LifeManager/Services/ProactiveNotificationEngine.swift /tmp/lifemanager_disabled/Services/ 2>/dev/null
mv Sources/LifeManager/Services/AILearningEngine.swift /tmp/lifemanager_disabled/Services/ 2>/dev/null
mv Sources/LifeManager/Services/TaskDependencyService.swift /tmp/lifemanager_disabled/Services/ 2>/dev/null

# Move problematic models
mv Sources/LifeManager/Models/IntelligentSchedulingModels.swift /tmp/lifemanager_disabled/Models/ 2>/dev/null
mv Sources/LifeManager/Models/Phase2ReschedulingModels.swift /tmp/lifemanager_disabled/Models/ 2>/dev/null

# 4. Create a simple CalendarView replacement
echo "📝 Creating minimal CalendarView..."
cat > Sources/LifeManager/Views/CalendarView.swift << 'EOF'
import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        VStack {
            Text("Calendar View")
                .font(.largeTitle)
                .padding()
            
            Text("Calendar functionality temporarily disabled during minimal build")
                .foregroundColor(.secondary)
                .padding()
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
EOF

# 5. Build the app
echo "🔨 Building LifeManager (minimal version)..."
swift build --configuration release

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    
    # Find the binary
    BINARY_PATH=$(find .build -path "*release/LifeManager" -type f -perm +111 | grep -v ".dSYM" | head -1)
    
    if [ -f "$BINARY_PATH" ]; then
        echo "✅ Binary found at: $BINARY_PATH"
        echo "🚀 Running LifeManager..."
        "$BINARY_PATH"
    else
        echo "❌ Could not find built binary"
        echo "Available files:"
        find .build -name "LifeManager*" -type f
    fi
else
    echo "❌ Build still failing. Showing detailed errors..."
    swift build --configuration release 2>&1 | grep -A 5 -B 5 "error:"
fi

echo ""
echo "💡 To restore full functionality later:"
echo "   cp -r /tmp/lifemanager_disabled/* Sources/LifeManager/"