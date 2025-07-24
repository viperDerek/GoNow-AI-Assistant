import SwiftUI
import EventKit

struct ContentView: View {
    @State private var meetings: [String] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("GoNow")
                    .font(.headline)
                    .fontWeight(.bold)
                
                if meetings.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        Text("No meetings")
                            .font(.caption)
                        Text("Set up on iPhone")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List(meetings, id: \.self) { meeting in
                        Text(meeting)
                            .font(.caption)
                    }
                }
                
                Button("Refresh") {
                    loadMeetings()
                }
                .buttonStyle(.bordered)
                .font(.caption)
            }
            .padding()
            .onAppear {
                loadMeetings()
            }
        }
    }
    
    private func loadMeetings() {
        isLoading = true
        // Simulate loading meetings
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            meetings = ["Meeting 1", "Meeting 2", "Meeting 3"]
            isLoading = false
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
