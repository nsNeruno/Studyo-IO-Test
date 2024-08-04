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
    @Published private (set) var players: [SwipeableVideoPlayer] = []
    
    init() {
        Task { @MainActor in
            await fetchVideoInfo()
        }
    }
    
    fileprivate func addPlayer(_ player: SwipeableVideoPlayer) {
        var playersCopy = players.map({ player in
            return player
        })
        playersCopy.append(player)
        players = playersCopy
    }
    
    private func loadVideo(_ path: String) {
        let storage = Storage.storage()
        storage.reference(withPath: path).downloadURL { url, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.error = error
                } else {
                    if let url = url {
                        let player = SwipeableVideoPlayer(url: url)
                        player.controller = self
                    }
                }
            }
        }
    }
    
    private func prepareVideoData(_ data: [String: Any]) {
//        if let author = data["author"] as? String {
//            self.author = author
//        }
//        if let title = data["title"] as? String {
//            self.title = title
//        }
        if let path = data["path"] as? String {
            self.loadVideo(path)
        }
    }
    
    private func fetchVideoInfo() async {
        do {
            let snapshots = try await Firestore.firestore().collection("videos").getDocuments()
            snapshots.documents.forEach { snapshot in
                self.prepareVideoData(snapshot.data())
            }
        } catch {
            self.error = error
        }
    }
}

class SwipeableVideoPlayer: AVPlayer {
    
    fileprivate var controller: TikTokCopy?
    
    override init() {
        super.init()
    }
    
    override init(playerItem item: AVPlayerItem?) {
        super.init(playerItem: item)
    }
    
    override init(url URL: URL) {
        super.init(url: URL)
        currentItem?.addObserver(
            self, forKeyPath: "loadedTimeRanges", options: [.new], context: nil
        )
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "loadedTimeRanges" {
            if let loadedTimeRanges = change?[.newKey] as? [CMTimeRange], let timeRange = loadedTimeRanges.first {
                let timeDifference = (timeRange.end - timeRange.start).seconds
                if timeDifference >= 5 {
                    controller?.addPlayer(self)
                }
            }
        }
    }
}
