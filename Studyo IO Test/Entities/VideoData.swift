//
//  VideoData.swift
//  Studyo IO Test
//
//  Created by Nanan Setiady on 05/08/24.
//

import Foundation

struct VideoData: Codable, Equatable, Identifiable {
    
    let id: String
    let author: String
    let title: String
    let path: String
}
