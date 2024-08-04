//
//  FrameExtraction.swift
//  Studyo IO Test
//
//  Created by Nanan Setiady on 04/08/24.
//

import Foundation
import SwiftUI
import Zip

class FrameExtraction: ObservableObject {
    
    @Published private (set) var imageFrames: [UIImage] = [] {
        didSet {
            animateFrames()
        }
    }
    @Published private (set) var currentFrame: UIImage?
    
    private let framesPerSecond: Int = 20
    
    init() {
        loadAssets()
    }
    
    private func loadImages(_ url: URL) {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        let path = url.path
        if fileManager.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue {
            do {
                let contents = try fileManager.contentsOfDirectory(atPath: path)
                // Assuming only .jpg files inside, no sub-directories, all file names are assigned numbers with
                // at least a single trailing zero for index < 10
                // First file starts at 1
                var fileUrls: [URL] = []
                for (index, _) in contents.enumerated() {
                    let fileName = String(format: "%02d", index + 1)
                    let fileUrl = url.appendingPathComponent("\(fileName).jpg")
                    fileUrls.append(fileUrl)
                }
                
                // Starts at last frame to do a zoom out effect
                fileUrls.reverse()
                
                var imageFrames: [UIImage] = []
                for url in fileUrls {
                    if let image = UIImage(contentsOfFile: url.path) {
//                        print("Found image at \(url.path)")
                        imageFrames.append(image)
                    } else {
//                        print("No file at \(url.path)")
                    }
                }
                self.imageFrames = imageFrames
            } catch {
                print(error)
            }
        }
    }
    
    private func loadAssets() {
        // Instead of registering entire image file sets, prefer to use compressed image sets
        let zipPath = Bundle.main.url(forResource: "frame_in_10_second", withExtension: "zip")
        if let zipPath = zipPath {
            do {
                // Result is directory path pointing to extracted files
                let extractedPath = try Zip.quickUnzipFile(zipPath)
                loadImages(extractedPath)
            } catch {
                print(error)
            }
        } else {
            print("Failed to convert to URL: \(zipPath)")
        }
    }
    
    private func animateFrames() {
        if imageFrames.isEmpty {
            return
        }
        
        // Instead of iterating with for-loop, we perform iteration using low level iterator
        var it = imageFrames.makeIterator()
        
        Timer.scheduledTimer(
            withTimeInterval: Double(1) / Double(framesPerSecond),
            repeats: true
        ) { timer in
            // Look for next frame, if no frame found, stop the timer
            if let next = it.next() {
                self.currentFrame = next
            } else {
                timer.invalidate()
            }
        }
    }
}
