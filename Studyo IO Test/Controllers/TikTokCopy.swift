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
    
    @Published private (set) var error: Error?
    @Published private (set) var videoHolders: [VideoHolder] = [] {
        didSet {
            if !videoHolders.isEmpty {
                loadVideoAt(0)
            }
        }
    }
    
    init() {
        Task { @MainActor in
            await fetchVideoInfo()
        }
    }
    
    func loadVideoAt(_ index: Int) {
        let count = videoHolders.count
        if index < count {
            let videoHolder = videoHolders[index]
            let prevIndex = index - 1
            let nextIndex = index + 1
            
            for i in videoHolders.indices {
                let mVideoHolder = videoHolders[i]
                if ![prevIndex, index, nextIndex].contains(i) {
                    mVideoHolder.releasePlayer()
                } else {
                    mVideoHolder.initPlayer(playWhenReady: i == index)
                    if i != index {
                        mVideoHolder.player?.pause()
                    }
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
            self.videoHolders = videoDataList.map({ videoData in
                VideoHolder(videoData)
            })
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
    
    init(url URL: URL, videoData: VideoData) {
        super.init(url: URL)
        self.videoData = videoData
        addObserver(self, forKeyPath: "status", options: [.new], context: nil)
        currentItem?.addObserver(
            self, forKeyPath: "loadedTimeRanges", options: [.new], context: nil
        )
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
        addObserver(self, forKeyPath: "status", options: [.old, .new], context: nil)
        if let item = currentItem {
            item.addObserver(
                self, forKeyPath: "loadedTimeRanges", options: [.old, .new], context: nil
            )
        }
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        switch keyPath {
        case "status":
            var oldStatus: AVPlayer.Status?
            var playerStatus: AVPlayer.Status?
            
            if let status = change?[.oldKey] as? AVPlayer.Status {
                oldStatus = status
            } else if let i = change?[.oldKey] as? Int {
                oldStatus = AVPlayer.Status(rawValue: i)
            }
            
            if let status = change?[.newKey] as? AVPlayer.Status {
                playerStatus = status
            } else if let i = change?[.newKey] as? Int {
                playerStatus = AVPlayer.Status(rawValue: i)
            }
            
            if playWhenReady && oldStatus != .readyToPlay && playerStatus == .readyToPlay {
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
            if let url = url {
                self.player = SwipeableVideoPlayer(
                    url: url,
                    videoData: self.videoData,
                    playWhenReady: playWhenReady
                ) { player in
                    self.controller?.objectWillChange.send()
                }
            }
        }
    }
    
    fileprivate func releasePlayer() {
        player?.pause()
        player?.removeRefs()
        player = nil
    }
}
