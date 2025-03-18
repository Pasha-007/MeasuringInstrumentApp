//
//  MainMenuView.swift
//  MeasuringInstrumentApp
//
//  Created by Muntahaa Khan on 5/3/25.
//

import SwiftUI

struct MainMenuView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Measuring Instrument App")
                    .font(.largeTitle)
                    .bold()
                    .padding()
                
                NavigationLink(destination: FloorCeilingView()) {
                    Text("📏 Floor & Ceiling Measurement")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                NavigationLink(destination: MagnificationView()) {
                    Text("🔍 Magnification")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                NavigationLink(destination: ObjectSizeView()) {
                    Text("📐 Object Size Measurement")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                NavigationLink(destination: HeightMeasurementView()){
                    Text("📏 Height Measurement")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView()
    }
}
