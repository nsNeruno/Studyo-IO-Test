//
//  VideoPlayerScreen.swift
//  Studyo IO Test
//
//  Created by Nanan Setiady on 04/08/24.
//

import Foundation
import SwiftUI
import AVKit

struct VideoPlayerScreen: View {
    
    @StateObject private var controller = VideoPlayerController()
    
    var body: some View {
        
        let error = controller.error
        let player = controller.player
        let isReady = controller.playerStatus == .readyToPlay
        
        if let error = error {
            Text("Error\n\(error)")
        } else if let player = player, isReady {
            ZStack {
                VideoPlayer(player: player)
                    .disabled(true)
                GeometryReader { proxy in
                    let width = proxy.size.width
                    VStack(alignment: .leading) {
                        VideoInfo(controller: controller)
                        Spacer()
                        if let currentTime = controller.currentTime, let duration = player.currentItem?.duration {
                            let durationInSeconds = CMTimeGetSeconds(duration)
                            let uiColor = #colorLiteral(red: 0, green: 1, blue: 1, alpha: 1)
                            Divider()
                                .frame(
                                    width: (currentTime / durationInSeconds) * width, height: 4
                                )
                                .background(Color(uiColor))
                        }
                        PlaybackControls(controller: controller)
                    }
                }
            }
        } else {
            Text("Video Player")
        }
    }
}

fileprivate struct VideoInfo: View {
    
    @ObservedObject var controller: VideoPlayerController
    
    var body: some View {
        
        let color = Color(UIColor(red: 239 / 255, green: 135 / 255, blue: 237 / 255, alpha: 1.0))
        
        let author = controller.author
        let title = controller.title
        
        HStack {
            Spacer()
            VStack {
                if let title = title {
                    Text(title)
                        .padding(.trailing, 24)
                        .alignmentGuide(.trailing, computeValue: { dimension in
                            0
                        })
                        .foregroundColor(color)
                        .multilineTextAlignment(.trailing)
                }
                Spacer().frame(height: 8)
                if let author = author {
                    Text("by \(author)")
                        .padding(.trailing, 24)
                        .alignmentGuide(.trailing, computeValue: { dimension in
                            0
                        })
                        .foregroundColor(color)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .background(.black.opacity(0.65))
    }
}

fileprivate struct PlaybackControls: View {
    
    @ObservedObject var controller: VideoPlayerController
    
    var body: some View {
        let color = Color(UIColor(red: 239 / 255, green: 135 / 255, blue: 237 / 255, alpha: 1.0))
        
        let isPlaying = controller.timeControlStatus == .playing
        
        HStack {
            Spacer()
            Image(systemName: "backward.fill")
                .foregroundColor(color)
                .onTapGesture {
                    controller.player?.rewind()
                }
            Spacer()
            Image(
                systemName: "\(isPlaying ? "pause" : "play").fill"
            )
                .foregroundColor(color)
                .onTapGesture {
                    if isPlaying {
                        controller.player?.pause()
                    } else {
                        controller.player?.play()
                    }
                }
            Spacer()
            Image(systemName: "forward.fill")
                .foregroundColor(color)
                .onTapGesture {
                    controller.player?.fastForward()
                }
            Spacer()
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 24)
        .background(.black.opacity(0.65))
    }
}
