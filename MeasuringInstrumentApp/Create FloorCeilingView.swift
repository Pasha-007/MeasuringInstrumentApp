import SwiftUI
import ARKit

struct FloorCeilingView: View {
    @State private var measuredHeight: String = "Measuring..."
    @State private var floorArea: String = "Tap to mark floor corners"
    @State private var ceilingArea: String = "No ceiling area measured"
    @State private var measurementStatus: String = "Start by detecting the floor"
    @State private var currentMode: MeasurementMode = .detectFloor
    @State private var measurementAccuracy: Double = 0.0
    @State private var isLoading: Bool = true
    
    enum MeasurementMode {
        case detectFloor
        case markFloorCorners
        case measureHeight
        case markCeilingCorners
        case complete
    }
    
    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 4) {
                    Text("Room Measurement")
                        .font(.title)
                        .padding(.top, 12)
                    
                    // Status indicator
                    Text(measurementStatus)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 8)
                }
                
                // Measurement cards
                VStack(spacing: 12) {
                    MeasurementCard(
                        title: "Floor Area",
                        value: floorArea,
                        icon: "square.fill",
                        color: .green
                    )
                    
                    MeasurementCard(
                        title: "Ceiling Area",
                        value: ceilingArea,
                        icon: "square.dashed",
                        color: .blue
                    )
                    
                    MeasurementCard(
                        title: "Room Height",
                        value: measuredHeight,
                        icon: "arrow.up.and.down",
                        color: .orange
                    )
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // AR View with overlay - takes all remaining space
                GeometryReader { geometry in
                    ZStack {
                        RoomMeasurementARView(
                            measuredHeight: $measuredHeight,
                            floorArea: $floorArea,
                            ceilingArea: $ceilingArea,
                            measurementStatus: $measurementStatus,
                            measurementAccuracy: $measurementAccuracy,
                            currentMode: $currentMode,
                            isLoading: $isLoading
                        )
                        .edgesIgnoringSafeArea(.horizontal)
                        
                        // Guide overlay at bottom
                        VStack {
                            Spacer()
                            guidanceText
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .padding(.horizontal)
                                .padding(.bottom, 20)
                        }
                    }
                    .frame(height: geometry.size.height)
                }
                .frame(maxHeight: .infinity)
                
                Spacer(minLength: 0)
            }
            
            // Fixed bottom button bar
            VStack {
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: restartMeasurement) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Restart")
                                .fontWeight(.medium)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    
                    Button(action: nextStage) {
                        HStack {
                            Text(nextButtonLabel)
                                .fontWeight(.medium)
                            Image(systemName: nextButtonIcon)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                }
                .padding()
                .background(
                    Rectangle()
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -2)
                )
            }
            
            // Loading overlay
            if isLoading {
                Color.black.opacity(0.7)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    
                    Text("Initializing AR Session...")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    // Dynamic guidance text based on current mode
    var guidanceText: some View {
        VStack(spacing: 6) {
            Text(getGuidanceMessage())
                .font(.headline)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                
            if let subtext = getGuidanceSubtext() {
                Text(subtext)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    
    // Main guidance message
    func getGuidanceMessage() -> String {
        switch currentMode {
        case .detectFloor:
            return "Move camera slowly to detect floor plane"
        case .markFloorCorners:
            return "Tap to mark each corner of the room at floor level"
        case .measureHeight:
            return "Point camera up and tap to mark ceiling height"
        case .markCeilingCorners:
            return "Mark ceiling corners (same order as floor)"
        case .complete:
            return "Measurement complete! Save or restart"
        }
    }
    
    // Optional guidance subtext
    func getGuidanceSubtext() -> String? {
        switch currentMode {
        case .markFloorCorners:
            return "Mark corners in clockwise or counter-clockwise order"
        case .markCeilingCorners:
            return "Follow the same order as floor corners"
        default:
            return nil
        }
    }
    
    // Dynamic next button label
    var nextButtonLabel: String {
        switch currentMode {
        case .detectFloor:
            return "Mark Corners"
        case .markFloorCorners:
            return "Measure Height"
        case .measureHeight:
            return "Mark Ceiling"
        case .markCeilingCorners:
            return "Complete"
        case .complete:
            return "Save Results"
        }
    }
    
    // Dynamic next button icon
    var nextButtonIcon: String {
        switch currentMode {
        case .detectFloor:
            return "plus.app"
        case .markFloorCorners:
            return "ruler"
        case .measureHeight:
            return "square.dashed"
        case .markCeilingCorners:
            return "checkmark.circle"
        case .complete:
            return "square.and.arrow.down"
        }
    }
    
    // Function to restart AR session
    func restartMeasurement() {
        measuredHeight = "Measuring..."
        floorArea = "Tap to mark floor corners"
        ceilingArea = "No ceiling area measured"
        measurementStatus = "Start by detecting the floor"
        currentMode = .detectFloor
        measurementAccuracy = 0.0
        isLoading = true
    }
    
    // Function to proceed to next measurement stage
    func nextStage() {
        switch currentMode {
        case .detectFloor:
            currentMode = .markFloorCorners
            measurementStatus = "Mark floor corners by tapping"
        case .markFloorCorners:
            currentMode = .measureHeight
            measurementStatus = "Measuring room height"
        case .measureHeight:
            currentMode = .markCeilingCorners
            measurementStatus = "Mark ceiling corners"
        case .markCeilingCorners:
            currentMode = .complete
            measurementStatus = "Measurement complete"
        case .complete:
            saveMeasurement()
        }
    }
    
    // Function to save current measurement
    func saveMeasurement() {
        // Add code to save measurements to user defaults or database
        print("Measurements saved: \nFloor Area: \(floorArea)\nCeiling Area: \(ceilingArea)\nHeight: \(measuredHeight)")
    }
}

// Custom card view for measurements
struct MeasurementCard: View {
    var title: String
    var value: String
    var icon: String
    var color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.headline)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(color.opacity(0.1))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}
