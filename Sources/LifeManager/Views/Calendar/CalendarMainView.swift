import SwiftUI
import Foundation

/// Main calendar view that switches between different view modes
/// 
/// This component serves as the central container for all calendar view modes:
/// - Day view: Detailed hourly timeline
/// - Week view: Google Calendar-style weekly grid
/// - Month view: Traditional monthly calendar grid
/// 
/// Handles loading states and view mode transitions with smooth animations.
struct CalendarMainView: View {
    // MARK: - Dependencies
    @EnvironmentObject var calendarViewModel: CalendarViewModel
    
    // MARK: - Body
    var body: some View {
        Group {
            if calendarViewModel.isLoading {
                loadingView
            } else {
                calendarContent
            }
        }
        .animation(.easeInOut(duration: 0.3), value: calendarViewModel.viewMode)
        .animation(.easeInOut(duration: 0.2), value: calendarViewModel.isLoading)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.blue)
            
            Text("Loading calendar...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }
    
    // MARK: - Calendar Content
    
    private var calendarContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Group {
                switch calendarViewModel.viewMode {
                case .day:
                    CalendarDayView()
                        .environmentObject(calendarViewModel)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    
                case .week:
                    CalendarWeekView()
                        .environmentObject(calendarViewModel)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                    
                case .month:
                    CalendarMonthView()
                        .environmentObject(calendarViewModel)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                }
            }
            
            Spacer() // Push all content to the top
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Preview

/* #Preview // DISABLED FOR STABILIZATION
    CalendarMainView()
        .environmentObject(CalendarViewModel())
        .frame(width: 800, height: 600)
} */
