import Foundation
import UIKit

struct YouTubeVideoInfo {
    let id: String
    let title: String
    let thumbnailURL: URL?
    let duration: String?
    let channelName: String?
}

class YouTubeService: ObservableObject {
    static let shared = YouTubeService()
    
    private let thumbnailCache = NSCache<NSString, UIImage>()
    private let session = URLSession.shared
    
    private init() {
        // Configure cache
        thumbnailCache.countLimit = 100
        thumbnailCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    // MARK: - Thumbnail Methods
    
    func getThumbnailURL(for videoID: String, quality: ThumbnailQuality = .medium) -> URL? {
        let baseURL = "https://img.youtube.com/vi/\(videoID)"
        let filename: String
        
        switch quality {
        case .default:
            filename = "default.jpg"
        case .medium:
            filename = "mqdefault.jpg"
        case .high:
            filename = "hqdefault.jpg"
        case .standard:
            filename = "sddefault.jpg"
        case .maxres:
            filename = "maxresdefault.jpg"
        }
        
        return URL(string: "\(baseURL)/\(filename)")
    }
    
    func loadThumbnail(for videoID: String, quality: ThumbnailQuality = .medium, completion: @escaping (UIImage?) -> Void) {
        let cacheKey = "\(videoID)-\(quality.rawValue)" as NSString
        
        // Check cache first
        if let cachedImage = thumbnailCache.object(forKey: cacheKey) {
            DispatchQueue.main.async {
                completion(cachedImage)
            }
            return
        }
        
        // Load from network
        guard let url = getThumbnailURL(for: videoID, quality: quality) else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }
        
        session.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data,
                  let image = UIImage(data: data),
                  error == nil else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            // Cache the image
            self?.thumbnailCache.setObject(image, forKey: cacheKey)
            
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }
    
    // MARK: - Video Info Methods
    
    func getVideoInfo(for videoID: String, completion: @escaping (YouTubeVideoInfo?) -> Void) {
        // This is a basic implementation that creates video info with thumbnail
        // In a production app, you'd use YouTube Data API v3 for complete metadata
        
        let videoInfo = YouTubeVideoInfo(
            id: videoID,
            title: "YouTube Video", // Placeholder - would come from API
            thumbnailURL: getThumbnailURL(for: videoID),
            duration: nil, // Would come from API
            channelName: nil // Would come from API
        )
        
        DispatchQueue.main.async {
            completion(videoInfo)
        }
    }
    
    // MARK: - URL Extraction
    
    func extractVideoID(from url: URL) -> String? {
        let urlString = url.absoluteString
        
        // YouTube URL patterns
        let patterns = [
            "(?:https?://)?(?:www\\.)?youtube\\.com/watch\\?v=([a-zA-Z0-9_\\-]+)",
            "(?:https?://)?(?:www\\.)?youtu\\.be/([a-zA-Z0-9_\\-]+)",
            "(?:https?://)?(?:www\\.)?youtube\\.com/embed/([a-zA-Z0-9_\\-]+)",
            "(?:https?://)?(?:www\\.)?youtube\\.com/v/([a-zA-Z0-9_\\-]+)"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: urlString, range: NSRange(urlString.startIndex..., in: urlString)) {
                let videoID = String(urlString[Range(match.range(at: 1), in: urlString)!])
                return videoID
            }
        }
        
        return nil
    }
    
    func extractVideoID(from urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }
        return extractVideoID(from: url)
    }
}

// MARK: - Supporting Types

enum ThumbnailQuality: String, CaseIterable {
    case `default` = "default"
    case medium = "medium"
    case high = "high"
    case standard = "standard"
    case maxres = "maxres"
    
    var displayName: String {
        switch self {
        case .default: return "Default (120x90)"
        case .medium: return "Medium (320x180)"
        case .high: return "High (480x360)"
        case .standard: return "Standard (640x480)"
        case .maxres: return "Max Resolution (1280x720)"
        }
    }
}

// MARK: - SwiftUI Integration

import SwiftUI

struct AsyncThumbnailImage: View {
    let videoID: String
    let quality: ThumbnailQuality
    
    @State private var image: UIImage?
    @State private var isLoading = true
    
    init(videoID: String, quality: ThumbnailQuality = .medium) {
        self.videoID = videoID
        self.quality = quality
    }
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    )
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
            }
        }
        .onAppear {
            loadThumbnail()
        }
        .onChange(of: videoID) {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        isLoading = true
        image = nil
        
        YouTubeService.shared.loadThumbnail(for: videoID, quality: quality) { loadedImage in
            self.image = loadedImage
            self.isLoading = false
        }
    }
}
