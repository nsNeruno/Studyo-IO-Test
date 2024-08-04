//
//  FrameExtractionScreen.swift
//  Studyo IO Test
//
//  Created by Nanan Setiady on 04/08/24.
//

import Foundation
import SwiftUI

struct FrameExtractionScreen: View {
    
    @StateObject private var controller: FrameExtraction = FrameExtraction()
    
    var body: some View {
        
        let imageFrames = controller.imageFrames
        
        if imageFrames.isEmpty {
            Text("Frame Extraction")
        } else {
            let frame = controller.currentFrame
            if let frame = frame {
                Image(uiImage: frame)
                    .resizable() // IMPORTANT: To ensure any size modification to fit in the screen works
                    .aspectRatio(3 / 4, contentMode: /*@START_MENU_TOKEN@*/.fill/*@END_MENU_TOKEN@*/)
            } else {
                Text("...")
            }
        }
    }
}
