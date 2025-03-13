import SwiftUI

struct ObjectSizeView: View {
    @State private var measuredSize: String = "Tap two points to measure"

    var body: some View {
        VStack {
            Text("📏 Object Size Measurement")
                .font(.title)
                .padding()

            Text(measuredSize)
                .font(.headline)
                .padding()

            ZStack {
                ARObjectSizeView(measuredSize: $measuredSize) // ARKit view
                    .edgesIgnoringSafeArea(.all)
            }

            Button(action: restartMeasurement) {
                Text("Restart Measurement")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
    }

    func restartMeasurement() {
        measuredSize = "Tap two points to measure"
    }
}

struct ObjectSizeView_Previews: PreviewProvider {
    static var previews: some View {
        ObjectSizeView()
    }
}
