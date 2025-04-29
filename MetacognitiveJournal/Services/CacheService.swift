import Foundation
import SwiftUI

// MARK: - Cache Service
class CacheService {
    static let shared = CacheService()
    
    private let cache = NSCache<NSString, AnyObject>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        // Set up cache directory
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDirectory.appendingPathComponent("MetacognitiveJournal", isDirectory: true)
        
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Configure cache limits
        cache.countLimit = 100 // Maximum number of objects
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
        
        // Register for memory warning notifications
        NotificationCenter.default.addObserver(self, selector: #selector(clearMemoryCache), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Memory Cache
    
    func cacheObject<T: AnyObject>(_ object: T, forKey key: String) {
        cache.setObject(object, forKey: key as NSString)
    }
    
    func getObject<T: AnyObject>(forKey key: String) -> T? {
        return cache.object(forKey: key as NSString) as? T
    }
    
    func removeObject(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    @objc func clearMemoryCache() {
        cache.removeAllObjects()
    }
    
    // MARK: - Disk Cache
    
    func cacheData(_ data: Data, forKey key: String) {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        try? data.write(to: fileURL)
    }
    
    func getData(forKey key: String) -> Data? {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        return try? Data(contentsOf: fileURL)
    }
    
    func removeData(forKey key: String) {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        try? fileManager.removeItem(at: fileURL)
    }
    
    func clearDiskCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Image Cache
    
    func cacheImage(_ image: UIImage, forKey key: String) {
        // Cache in memory
        cacheObject(image, forKey: key)
        
        // Cache on disk
        if let data = image.jpegData(compressionQuality: 0.8) {
            cacheData(data, forKey: key)
        }
    }
    
    func getImage(forKey key: String) -> UIImage? {
        // Try memory cache first
        if let image: UIImage = getObject(forKey: key) {
            return image
        }
        
        // Try disk cache
        if let data = getData(forKey: key), let image = UIImage(data: data) {
            // Add back to memory cache
            cacheObject(image, forKey: key)
            return image
        }
        
        return nil
    }
}

// MARK: - Cached Image View
struct CachedImageView: View {
    let url: URL
    let placeholder: Image
    
    @State private var image: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else if isLoading {
                ProgressView()
            } else {
                placeholder
                    .resizable()
                    .scaledToFit()
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        let cacheKey = url.absoluteString
        
        // Check cache first
        if let cachedImage = CacheService.shared.getImage(forKey: cacheKey) {
            self.image = cachedImage
            return
        }
        
        // Download image
        isLoading = true
        URLSession.shared.dataTask(with: url) { data, response, error in
            isLoading = false
            
            if let data = data, let downloadedImage = UIImage(data: data) {
                // Cache the image
                CacheService.shared.cacheImage(downloadedImage, forKey: cacheKey)
                
                DispatchQueue.main.async {
                    self.image = downloadedImage
                }
            }
        }.resume()
    }
}

// MARK: - Paginated Collection
class PaginatedCollection<T: Identifiable>: ObservableObject {
    @Published var items: [T] = []
    @Published var isLoading = false
    @Published var hasMorePages = true
    @Published var currentPage = 0
    
    private let pageSize: Int
    private let loadPage: (Int, @escaping ([T], Bool) -> Void) -> Void
    
    init(pageSize: Int, loadPage: @escaping (Int, @escaping ([T], Bool) -> Void) -> Void) {
        self.pageSize = pageSize
        self.loadPage = loadPage
        loadNextPage()
    }
    
    func loadNextPage() {
        guard hasMorePages && !isLoading else { return }
        
        isLoading = true
        
        loadPage(currentPage) { [weak self] newItems, hasMore in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.items.append(contentsOf: newItems)
                self.hasMorePages = hasMore
                self.currentPage += 1
                self.isLoading = false
            }
        }
    }
    
    func refresh() {
        items = []
        currentPage = 0
        hasMorePages = true
        loadNextPage()
    }
}

// MARK: - Paginated List View
struct PaginatedListView<T: Identifiable, Content: View>: View {
    @ObservedObject var collection: PaginatedCollection<T>
    let content: (T) -> Content
    
    init(collection: PaginatedCollection<T>, @ViewBuilder content: @escaping (T) -> Content) {
        self.collection = collection
        self.content = content
    }
    
    var body: some View {
        List {
            ForEach(collection.items) { item in
                content(item)
                    .onAppear {
                        if item.id == collection.items.last?.id {
                            collection.loadNextPage()
                        }
                    }
            }
            
            if collection.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding()
            }
        }
        .refreshable {
            collection.refresh()
        }
    }
}
