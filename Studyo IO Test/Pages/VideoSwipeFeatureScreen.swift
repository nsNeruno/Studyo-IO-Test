//
//  VideoSwipeFeatureScreen.swift
//  Studyo IO Test
//
//  Created by Nanan Setiady on 04/08/24.
//

import Foundation
import SwiftUI
import AVKit

struct VideoSwipeFeatureScreen: View {
    
    @StateObject private var controller = TikTokCopy()
    @State private var index: Int = 0
    
    var body: some View {
        
        if let error = controller.error {
            Text("\(error)")
        } else {
            GeometryReader { proxy in
                
                let size = proxy.size
                let width = size.width
                let height = size.height
                
                let videoHolders = controller.videoHolders
                
                TabView(selection: $index) {
                    ForEach(videoHolders.indices, id: \.self) { i in
                        let videoHolder = videoHolders[i]
                        let videoData = videoHolder.videoData
                        if let player = videoHolder.player {
                            VideoPlayer(player: player)
                                .ignoresSafeArea()
                                .frame(width: width, height: height)
                                .rotationEffect(.degrees(-90))
                                .tag(i)
                        } else {
                            VStack {
                                Text("ID: \(videoData.id)")
                                Text("Title: \(videoData.title)")
                                Text("Author: \(videoData.author)")
                                Text("Path: \(videoData.path)")
                            }
                            .frame(width: height, height: width)
                            .rotationEffect(.degrees(-90))
                            .background(.cyan)
                            .tag(i)
                        }
                    }
                }
                .frame(width: height, height: width)
                .rotationEffect(.degrees(90), anchor: .topLeading)
                .offset(x: width)
                .onChange(of: index) { newValue in
                    controller.loadVideoAt(newValue)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        }
}
