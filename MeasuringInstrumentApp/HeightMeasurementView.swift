//
//  HeightMeasurementView.swift
//  MeasuringInstrumentApp
//
//  Created by Muntahaa Khan on 19/3/25.
//

import SwiftUI

struct HeightMeasurementView: View {
    @State private var measuredHeight: String = "Detecting height..."
    
    var body: some View {
        VStack {
            Text("📏 Height Measurement")
                .font(.title)
                .padding()

            Text(measuredHeight)
                .font(.headline)
                .padding()

            ZStack {
                ARHeightMeasurementView(measuredHeight: $measuredHeight) // ARKit View
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
        measuredHeight = "Detecting height..."
    }
}

struct HeightMeasurementView_Previews: PreviewProvider {
    static var previews: some View {
        HeightMeasurementView()
    }
}
