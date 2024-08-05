//
//  TikTokCopy.swift
//  Studyo IO Test
//
//  Created by Nanan Setiady on 05/08/24.
//

import Foundation
import AVKit
import FirebaseFirestore
import FirebaseStorage

class TikTokCopy: ObservableObject {
    
    @Published fileprivate (set) var error: Error?
    @Published private (set) var videoHolders: [VideoHolder] = [] {
        didSet {
            if !videoHolders.isEmpty {
                // Added some delay before loading the video
                // Loads the first video
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.loadVideoAt(0)
                }
            }
        }
    }
    
    init() {
        Task { @MainActor in
            // Fetch Video Listing
            await fetchVideoInfo()
        }
    }
    
    func loadVideoAt(_ index: Int) {
        let count = videoHolders.count
        if index < count {
            let prevIndex = index - 1
            let nextIndex = index + 1
            
            for i in videoHolders.indices {
                let mVideoHolder = videoHolders[i]
                if (prevIndex...nextIndex).contains(i) {
                    mVideoHolder.initPlayer(playWhenReady: i == index)
                    if i != index {
                        mVideoHolder.player?.pause()
                    }
                } else {
                    mVideoHolder.releasePlayer()
                }
            }
        }
    }
    
    private func videoDataFromDocument(_ id: String, _ data: [String: Any]) -> VideoData {
        return VideoData(
            id: id,
            author: data["author"] as! String,
            title: data["title"] as! String,
            path: data["path"] as! String
        )
    }
    
    private func fetchVideoInfo() async {
        do {
            let snapshots = try await Firestore.firestore().collection("videos").getDocuments()
            let videoDataList = snapshots.documents.map { snapshot in
                return videoDataFromDocument(snapshot.documentID, snapshot.data())
            }
            DispatchQueue.main.async {
                self.videoHolders = videoDataList.map({ videoData in
                    let holder = VideoHolder(videoData)
                    // IMPORTANT: Attaching this controller ref to each holder to delegate force refresh capability
                    holder.controller = self
                    return holder
                })
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error
            }
        }
    }
}

class SwipeableVideoPlayer: AVPlayer {
    
    fileprivate var videoData: VideoData?
    private var onPlayerBufferReady: ((SwipeableVideoPlayer) -> Void)?
    fileprivate var controller: TikTokCopy?
    private var playWhenReady: Bool = false
    
    override init() {
        super.init()
    }
    
    override init(playerItem item: AVPlayerItem?) {
        super.init(playerItem: item)
    }
    
    init(
        url URL: URL,
        videoData: VideoData,
        playWhenReady: Bool = false,
        onPlayerBufferReady: @escaping (SwipeableVideoPlayer) -> Void
    ) {
        super.init(url: URL)
        self.videoData = videoData
        self.playWhenReady = playWhenReady
        self.onPlayerBufferReady = onPlayerBufferReady
        // Observe playback readiness
        addObserver(self, forKeyPath: "status", options: [.new], context: nil)
        // Observe loaded buffers
        if let item = currentItem {
            item.addObserver(
                self, forKeyPath: "loadedTimeRanges", options: [.new], context: nil
            )
        }
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        switch keyPath {
        case "status":
            var playerStatus: AVPlayer.Status?
            
            if let status = change?[.newKey] as? AVPlayer.Status {
                playerStatus = status
            } else if let i = change?[.newKey] as? Int {
                playerStatus = AVPlayer.Status(rawValue: i)
            }
            
            if playWhenReady && playerStatus == .readyToPlay {
                play()
            }
            break
        case "loadedTimeRanges":
            if let loadedTimeRanges = change?[.newKey] as? [CMTimeRange], let timeRange = loadedTimeRanges.first {
                let timeDifference = (timeRange.end - timeRange.start).seconds
                if timeDifference >= 5 {
                    DispatchQueue.main.async {
                        if self.playWhenReady {
                            self.play()
                        }
                        self.onPlayerBufferReady?(self)
                    }
                }
            }
            break
        default:
            break
        }
        
    }
    
    fileprivate func removeRefs() {
        videoData = nil
        onPlayerBufferReady = nil
        controller = nil
    }
    
    deinit {
        removeObserver(self, forKeyPath: "status")
        currentItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
    }
}

class VideoHolder: Identifiable {
    
    init(_ video: VideoData) {
        self.videoData = video
        id = video.id
    }
    
    let id: String
    
    let videoData: VideoData
    fileprivate (set) var player: SwipeableVideoPlayer?
    fileprivate var controller: TikTokCopy?
    
    fileprivate func initPlayer(playWhenReady: Bool = false) {
        if player != nil {
            player?.play()
            return
        }
        
        Storage.storage().reference(withPath: videoData.path).downloadURL { url, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.controller?.error = error
                    return
                }
                if let url = url {
                    self.player = SwipeableVideoPlayer(
                        url: url,
                        videoData: self.videoData,
                        playWhenReady: playWhenReady
                    ) { player in
                        // Ensuring the View is force refreshed to notify that the player is ready
                        self.controller?.objectWillChange.send()
                    }
                }
            }
        }
    }
    
    // Release resources of the player
    fileprivate func releasePlayer() {
        player?.pause()
        player?.removeRefs()
        player = nil
    }
}
