import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var viewModel: MainViewModel
    
    var body: some View {
        VStack {
            Text("Calendar")
                .font(.largeTitle)
                .padding()
            Text("Calendar temporarily disabled")
                .foregroundColor(.secondary)
            Spacer()
        }
    }
}
