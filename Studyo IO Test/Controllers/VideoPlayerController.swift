//
//  VideoPlayerController.swift
//  Studyo IO Test
//
//  Created by Nanan Setiady on 05/08/24.
//

import Foundation
import SwiftUI
import AVKit
import FirebaseStorage
import FirebaseFirestore

class VideoPlayerController: ObservableObject {
    
    @Published private (set) var error: Error?
    @Published private (set) var player: CustomPlayer?
    @Published fileprivate (set) var playerStatus: AVPlayer.Status = .unknown
    @Published fileprivate (set) var timeControlStatus: AVPlayer.TimeControlStatus?
    @Published fileprivate (set) var currentTime: Float64?
    
    @Published private (set) var author: String?
    @Published private (set) var title: String?
    
    init() {
        Task { @MainActor in
            await self.fetchVideoInfo()
        }
    }
    
    private func loadVideo(_ path: String) {
        let storage = Storage.storage()
        storage.reference(withPath: path).downloadURL { url, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.error = error
                } else {
                    if let url = url {
                        let player = CustomPlayer(url: url)
                        player.controller = self
                        self.player = player
                    }
                }
            }
        }
    }
    
    private func processVideoInfo(_ data: [String : Any]) {
        DispatchQueue.main.async {
            if let author = data["author"] as? String {
                self.author = author
            }
            if let title = data["title"] as? String {
                self.title = title
            }
            if let path = data["path"] as? String {
                self.loadVideo(path)
            }
        }
    }
    
    private func fetchVideoInfo() async {
        
        do {
            let snapshot = try await Firestore.firestore().collection("videos").getDocuments()
            let documents = snapshot.documents
            if let document = documents.first {
                processVideoInfo(document.data())
            }
        } catch {
            self.error = error
        }
    }
}

class CustomPlayer: AVPlayer {
    
    private let jumpTime = CMTime(seconds: 5, preferredTimescale: 1)
    private let tolerance = CMTime(seconds: 0.01, preferredTimescale: 100)
    
    // To make things simple, enable controlling of the controller under custom player
    fileprivate var controller: VideoPlayerController?
    
    private var timeObserverRef: Any?
    
    override init() {
        super.init()
    }
    
    override init(playerItem item: AVPlayerItem?) {
        super.init(playerItem: item)
    }
    
    override init(url URL: URL) {
        super.init(url: URL)
        observeEvents()
    }
    
    public func rewind() {
        let rewindTime = currentTime() - jumpTime
        seek(to: rewindTime, toleranceBefore: tolerance, toleranceAfter: tolerance)
    }
    
    public func fastForward() {
        let forwardTime = currentTime() + jumpTime
        seek(to: forwardTime, toleranceBefore: tolerance, toleranceAfter: tolerance)
    }
    
    private func periodicTimeObserver(_ time: CMTime) {
        if status == .readyToPlay, let duration = currentItem?.duration {
            let timeInSeconds: Float64 = CMTimeGetSeconds(time)
            controller?.currentTime = timeInSeconds
        }
    }
    
    // Observe AVPlayer internal events
    private func observeEvents() {
        addObserver(self, forKeyPath: "status", options: [.old, .new], context: nil)
        addObserver(self, forKeyPath: "timeControlStatus", options: [.old, .new], context: nil)
        timeObserverRef = addPeriodicTimeObserver(
            forInterval: CMTimeMake(value: 1, timescale: 100),
            queue: .main
        ) { time in
            self.periodicTimeObserver(time)
        }
        currentItem?.addObserver(self, forKeyPath: "loadedTimeRanges", options: [.new], context: nil)
    }
    
    // Intercept AVPlayer internal events and update controller based on it
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        switch keyPath {
        case "status":
            var playerStatus: AVPlayer.Status?
            if let status = change?[.newKey] as? AVPlayer.Status {
                playerStatus = status
            }
            
            // Most likely to be called instead
            else if let i = change?[.newKey] as? Int {
                playerStatus = AVPlayer.Status(rawValue: i)
            }
            
            if let status = playerStatus {
                controller?.playerStatus = status
            }
            
            break
        case "timeControlStatus":
            var status: TimeControlStatus?
            if let tcs = change?[.newKey] as? TimeControlStatus {
                status = tcs
            }
            
            // Most likely to be called instead
            else if let i = change?[.newKey] as? Int {
                status = TimeControlStatus(rawValue: i)
            }
            
            if let timeControlStatus = status {
                controller?.timeControlStatus = timeControlStatus
            }
            break
        default:
            break
        }
    }
    
    deinit {
        removeObserver(self, forKeyPath: "status")
        removeObserver(self, forKeyPath: "timeControlStatus")
        if let ref = timeObserverRef {
            removeTimeObserver(ref)
        }
        currentItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
    }
}
